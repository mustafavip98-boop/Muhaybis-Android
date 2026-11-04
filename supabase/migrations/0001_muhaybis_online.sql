-- Muhaybis online foundation. Hidden ring index is never exposed by room reads.
create extension if not exists pgcrypto;

create table if not exists public.muhaybis_rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  host_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'مجلس المحيبس',
  is_private boolean not null default false,
  hand_count int not null check (hand_count in (4,8)),
  status text not null default 'waiting' check (status in ('waiting','playing','closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.muhaybis_members (
  room_id uuid not null references public.muhaybis_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  team smallint check (team in (0,1)),
  joined_at timestamptz not null default now(),
  primary key(room_id,user_id)
);

create table if not exists public.muhaybis_rounds (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.muhaybis_rooms(id) on delete cascade,
  round_no int not null,
  hiding_team smallint not null check (hiding_team in (0,1)),
  hidden_hand int,
  opened_hands int[] not null default '{}',
  phase text not null default 'hiding' check (phase in ('hiding','guessing','final_draw','finished')),
  winner_team smallint check (winner_team in (0,1)),
  created_at timestamptz not null default now(),
  unique(room_id,round_no),
  check (hidden_hand is null or hidden_hand >= 0)
);

create table if not exists public.muhaybis_scores (
  room_id uuid not null references public.muhaybis_rooms(id) on delete cascade,
  team smallint not null check (team in (0,1)),
  points int not null default 0,
  primary key(room_id,team)
);

alter table public.muhaybis_rooms enable row level security;
alter table public.muhaybis_members enable row level security;
alter table public.muhaybis_rounds enable row level security;
alter table public.muhaybis_scores enable row level security;

create or replace function public.muhaybis_is_member(p_room uuid)
returns boolean language sql stable security definer set search_path=public
as $ select exists(select 1 from public.muhaybis_members m where m.room_id=p_room and m.user_id=auth.uid()) $;
revoke all on function public.muhaybis_is_member(uuid) from public;
grant execute on function public.muhaybis_is_member(uuid) to authenticated;

drop policy if exists room_members_can_read_room on public.muhaybis_rooms;
create policy room_members_can_read_room on public.muhaybis_rooms for select to authenticated
using (public.muhaybis_is_member(id));

drop policy if exists members_can_read_room_members on public.muhaybis_members;
create policy members_can_read_room_members on public.muhaybis_members for select to authenticated
using (public.muhaybis_is_member(room_id));

drop policy if exists members_can_read_scores on public.muhaybis_scores;
create policy members_can_read_scores on public.muhaybis_scores for select to authenticated
using (public.muhaybis_is_member(room_id));

-- Round table intentionally has no client SELECT policy: hidden_hand is secret.
-- All mutations happen through security-definer RPCs.
revoke all on public.muhaybis_rounds from anon, authenticated;
grant select on public.muhaybis_rooms, public.muhaybis_members, public.muhaybis_scores to authenticated;

create or replace function public.muhaybis_create_room(p_name text, p_private boolean, p_hands int)
returns table(room_id uuid, room_code text)
language plpgsql security definer set search_path=public
as $$
declare v_room uuid; v_code text;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 if p_hands not in (4,8) then raise exception 'hands must be 4 or 8'; end if;
 v_code := upper(substr(encode(gen_random_bytes(5),'hex'),1,8));
 insert into muhaybis_rooms(code,host_id,title,is_private,hand_count) values(v_code,auth.uid(),coalesce(nullif(trim(p_name),''),'مجلس المحيبس'),p_private,p_hands) returning id into v_room;
 insert into muhaybis_members(room_id,user_id,display_name,team) values(v_room,auth.uid(),'المضيف',0);
 insert into muhaybis_scores(room_id,team) values(v_room,0),(v_room,1);
 return query select v_room,v_code;
end $$;

create or replace function public.muhaybis_join_room(p_code text, p_display_name text)
returns uuid language plpgsql security definer set search_path=public
as $$
declare v_room uuid; v_team smallint; v_private boolean;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 select id,is_private into v_room,v_private from muhaybis_rooms where code=upper(trim(p_code)) and status='waiting';
 if v_room is null then raise exception 'room not found'; end if;
 if exists(select 1 from muhaybis_members where room_id=v_room and user_id=auth.uid()) then return v_room; end if;
 select case when count(*) filter(where team=0) <= count(*) filter(where team=1) then 0 else 1 end into v_team from muhaybis_members where room_id=v_room;
 insert into muhaybis_members(room_id,user_id,display_name,team) values(v_room,auth.uid(),coalesce(nullif(trim(p_display_name),''),'لاعب'),v_team);
 return v_room;
end $$;

create or replace function public.muhaybis_start_round(p_room uuid)
returns uuid language plpgsql security definer set search_path=public
as $$
declare v_round uuid; v_no int; v_team smallint; v_count int;
begin
 if not exists(select 1 from muhaybis_members where room_id=p_room and user_id=auth.uid() and team=0) then raise exception 'host team required'; end if;
 select coalesce(max(round_no),0)+1 into v_no from muhaybis_rounds where room_id=p_room;
 v_team := (v_no-1)%2;
 insert into muhaybis_rounds(room_id,round_no,hiding_team) values(p_room,v_no,v_team) returning id into v_round;
 update muhaybis_rooms set status='playing' where id=p_room;
 return v_round;
end $$;

create or replace function public.muhaybis_hide_ring(p_round uuid,p_hand int)
returns void language plpgsql security definer set search_path=public
as $$
declare r muhaybis_rounds%rowtype; n int;
begin
 select * into r from muhaybis_rounds where id=p_round for update;
 if not found then raise exception 'round not found'; end if;
 select hand_count into n from muhaybis_rooms where id=r.room_id;
 if not exists(select 1 from muhaybis_members where room_id=r.room_id and user_id=auth.uid() and team=r.hiding_team) then raise exception 'not hiding team'; end if;
 if r.phase<>'hiding' or p_hand<0 or p_hand>=n then raise exception 'invalid move'; end if;
 update muhaybis_rounds set hidden_hand=p_hand,phase='guessing' where id=p_round;
end $$;

create or replace function public.muhaybis_open_hand(p_round uuid,p_hand int)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare r muhaybis_rounds%rowtype; n int; v_team smallint; v_winner smallint; v_open int[];
begin
 select * into r from muhaybis_rounds where id=p_round for update;
 if not found then raise exception 'round not found'; end if;
 select hand_count into n from muhaybis_rooms where id=r.room_id;
 select team into v_team from muhaybis_members where room_id=r.room_id and user_id=auth.uid();
 if v_team is null or v_team=r.hiding_team then raise exception 'not guessing team'; end if;
 if r.phase not in ('guessing','final_draw') or p_hand<0 or p_hand>=n or p_hand=any(r.opened_hands) then raise exception 'invalid move'; end if;
 v_open := array_append(r.opened_hands,p_hand);
 if p_hand=r.hidden_hand then v_winner:=v_team;
 elsif n-cardinality(v_open)=2 then
   update muhaybis_rounds set opened_hands=v_open,phase='final_draw' where id=p_round;
   return jsonb_build_object('phase','final_draw','remaining',2);
 else
   update muhaybis_rounds set opened_hands=v_open where id=p_round;
   return jsonb_build_object('phase','guessing','remaining',n-cardinality(v_open));
 end if;
 update muhaybis_rounds set opened_hands=v_open,phase='finished',winner_team=v_winner where id=p_round;
 update muhaybis_scores set points=points+1 where room_id=r.room_id and team=v_winner;
 return jsonb_build_object('phase','finished','winner_team',v_winner,'remaining',n-cardinality(v_open));
end $$;

grant execute on function public.muhaybis_create_room(text,boolean,int) to authenticated;
grant execute on function public.muhaybis_join_room(text,text) to authenticated;
grant execute on function public.muhaybis_start_round(uuid) to authenticated;
grant execute on function public.muhaybis_hide_ring(uuid,int) to authenticated;
grant execute on function public.muhaybis_open_hand(uuid,int) to authenticated;
