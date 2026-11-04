import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  }
  runApp(const MuhaybisApp());
}
const gold=Color(0xFFD6AE68), ink=Color(0xFF0B0B0A), panel=Color(0xFF211C16);
class MuhaybisApp extends StatelessWidget{const MuhaybisApp({super.key});@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'المحيبس',theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:ink,colorScheme:ColorScheme.fromSeed(seedColor:gold,brightness:Brightness.dark)),home:const HomeScreen());}
class HomeScreen extends StatefulWidget{const HomeScreen({super.key});@override State<HomeScreen> createState()=>_HomeScreenState();}
class _HomeScreenState extends State<HomeScreen>{
 int hands=8; final a=TextEditingController(text:'الفريق الأول'),b=TextEditingController(text:'الفريق الثاني');
 @override void dispose(){a.dispose();b.dispose();super.dispose();}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('المحيبس',style:TextStyle(color:gold,fontWeight:FontWeight.bold))),body:SafeArea(child:ListView(padding:const EdgeInsets.all(20),children:[
 const SizedBox(height:20),const Icon(Icons.sports_esports,size:68,color:gold),const SizedBox(height:12),const Center(child:Text('لعبة المحيبس العراقية',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold))),const Center(child:Text('تراث • تحدّي • منافسة',style:TextStyle(color:Colors.white60))),const SizedBox(height:30),
 const Text('عدد العضمات',style:TextStyle(color:gold,fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:10),SegmentedButton<int>(segments:const [ButtonSegment(value:4,label:Text('4 عضمات')),ButtonSegment(value:8,label:Text('8 عضمات'))],selected:{hands},onSelectionChanged:(v)=>setState(()=>hands=v.first)),
 const SizedBox(height:20),const Text('أسماء الفريقين',style:TextStyle(color:gold,fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:10),TextField(controller:a,textAlign:TextAlign.center,decoration:const InputDecoration(labelText:'الفريق الأول')),const SizedBox(height:10),TextField(controller:b,textAlign:TextAlign.center,decoration:const InputDecoration(labelText:'الفريق الثاني')),
 const SizedBox(height:20),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),child:const Text('طريقة اللعب: فريق يخفي المحبس سراً، والفريق الثاني يفتح القبضات واحدة تلو الأخرى. إذا انفتح مكان المحبس تنتهي الجولة، وإذا بقيت قبضتان فارغتان يتم سحب المحبس من إحداهما.')),
 const SizedBox(height:24),FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>GameScreen(count:hands,teams:[a.text,b.text]))),icon:const Icon(Icons.play_arrow),label:const Padding(padding:EdgeInsets.all(12),child:Text('ابدأ اللعب',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)))),
 const SizedBox(height:12),const Center(child:Text('نسخة لعب محلي على جهاز واحد',style:TextStyle(color:Colors.white54,fontSize:12)))
 ])));}
class GameScreen extends StatefulWidget{final int count;final List<String> teams;const GameScreen({super.key,required this.count,required this.teams});@override State<GameScreen> createState()=>_GameScreenState();}
class _GameScreenState extends State<GameScreen>{
 late List<int> scores=[0,0];int hiding=0,round=1;int? ring;final Set<int> opened={};bool reveal=false,done=false;String message='';
 int get guess=>1-hiding;int get remaining=>widget.count-opened.length;
 @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_)=>chooseRing());}
 Future<void> chooseRing()async{final picked=await Navigator.push<int>(context,MaterialPageRoute(builder:(_)=>HideScreen(team:widget.teams[hiding],count:widget.count)));if(!mounted)return;if(picked!=null)setState(()=>ring=picked);}
 void finish(String s,int winner){scores[winner]++;done=true;message=s;}
 void tap(int i){if(done||opened.contains(i))return;setState((){
 if(reveal){finish(i==ring?'المحبس كان هنا! نقطة للفريق المخمّن.':'المحبس لم يكن هنا! نقطة للفريق المخفي.',i==ring?guess:hiding);}
 else{opened.add(i);if(i==ring)finish('انكشف المحبس! نقطة للفريق المخمّن.',guess);else if(remaining==2){reveal=true;message='بقت قبضتان. اسحبوا المحبس من واحدة منهن.';}else{message='قبضة فارغة. باقي ${remaining} قبضات.';}}
 });}
 void next(){setState((){hiding=1-hiding;round++;ring=null;opened.clear();reveal=false;done=false;message='';});chooseRing();}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text('الجولة ${round}',style:const TextStyle(color:gold))),body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
 Row(children:List.generate(2,(i)=>Expanded(child:Container(margin:const EdgeInsets.all(4),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:hiding==i?const Color(0xFF49371E):panel,borderRadius:BorderRadius.circular(14),border:Border.all(color:hiding==i?gold:Colors.white12)),child:Column(children:[Text(widget.teams[i].isEmpty?'الفريق ${i+1}':widget.teams[i],maxLines:1,overflow:TextOverflow.ellipsis),Text('${scores[i]}',style:const TextStyle(color:gold,fontSize:28,fontWeight:FontWeight.bold)),Text(hiding==i?'يخفي المحبس':'يخمّن',style:const TextStyle(fontSize:11))]))))),
 const SizedBox(height:14),Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(14)),child:Column(children:[Text(done?'انتهت الجولة':reveal?'سحب المحبس':'دور التخمين',style:const TextStyle(color:gold,fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text(done?message:reveal?message:'دور ${widget.teams[guess]} — اختاروا قبضة لفتحها.',textAlign:TextAlign.center),Text('المتبقي: ${remaining} من ${widget.count}',style:const TextStyle(color:Colors.white60))])),
 const SizedBox(height:18),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:widget.count,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:widget.count==4?2:4,crossAxisSpacing:9,mainAxisSpacing:9,childAspectRatio:.9),itemBuilder:(c,i){final used=opened.contains(i);final last=reveal&&!used;return InkWell(onTap:done||used?null:()=>tap(i),child:Container(decoration:BoxDecoration(color:used?const Color(0xFF34312B):last?const Color(0xFF49371E):panel,borderRadius:BorderRadius.circular(16),border:Border.all(color:last?gold:Colors.white24,width:last?2:1)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(used?Icons.pan_tool_alt:Icons.back_hand,size:38,color:used?Colors.white30:gold),const SizedBox(height:8),Text(used?'فارغة':'قبضة ${i+1}'),if(last)const Text('اسحب المحبس',style:TextStyle(color:gold,fontSize:10))])));}),
 const SizedBox(height:18),if(done)FilledButton.icon(onPressed:next,icon:const Icon(Icons.skip_next),label:const Text('الجولة التالية')),const SizedBox(height:8),const Text('اللعب محلي على جهاز واحد؛ الأونلاين والصوت المباشر يحتاجان خادماً وحسابات خدمة.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white38,fontSize:11))
 ])));}
class HideScreen extends StatefulWidget{final String team;final int count;const HideScreen({super.key,required this.team,required this.count});@override State<HideScreen> createState()=>_HideScreenState();}
class _HideScreenState extends State<HideScreen>{int? selected;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('إخفاء المحبس',style:TextStyle(color:gold))),body:SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[const Icon(Icons.visibility_off,color:gold,size:54),const SizedBox(height:10),Text('فقط ${widget.team}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const Text('اختاروا القبضة سراً ثم سلّموا الجهاز للفريق الثاني.',textAlign:TextAlign.center),const SizedBox(height:18),Expanded(child:GridView.builder(itemCount:widget.count,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:widget.count==4?2:4,crossAxisSpacing:9,mainAxisSpacing:9),itemBuilder:(c,i)=>InkWell(onTap:()=>setState(()=>selected=i),child:Container(decoration:BoxDecoration(color:selected==i?const Color(0xFF49371E):panel,borderRadius:BorderRadius.circular(15),border:Border.all(color:selected==i?gold:Colors.white24)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.back_hand,color:gold,size:38),Text('قبضة ${i+1}')] ))))),FilledButton(onPressed:selected==null?null:()=>Navigator.pop(c,selected),child:const SizedBox(width:double.infinity,child:Padding(padding:EdgeInsets.all(12),child:Center(child:Text('تأكيد إخفاء المحبس')))))]))));}
}