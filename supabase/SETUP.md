# Supabase setup (required for online demo)

1. Open Supabase Dashboard → SQL Editor.
2. Run the full SQL file at `supabase/migrations/0001_muhaybis_online.sql`.
3. In Authentication → Providers, enable Anonymous sign-ins for the first playable test.
4. Deploy Edge Function `livekit-token` from `supabase/functions/livekit-token/index.ts`.
5. Set Edge Function secrets in Supabase (not GitHub): `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`.
   Never put the LiveKit API secret in the Android app or a public repository.
6. LiveKit token endpoint must additionally verify the caller's Supabase JWT and room membership before production. The current function is a development starter; do not expose it publicly until membership verification is added.

The Android build secrets only inject public Supabase URL/key into the client. They do not deploy database migrations or Edge Functions.
