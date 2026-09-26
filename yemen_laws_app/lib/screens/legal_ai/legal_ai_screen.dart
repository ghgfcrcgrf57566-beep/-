import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/legal_ai_service.dart';
import '../article/article_detail_screen.dart';

class LegalAiScreen extends StatefulWidget {
  const LegalAiScreen({super.key});
  @override State<LegalAiScreen> createState()=>_LegalAiScreenState();
}
class _LegalAiScreenState extends State<LegalAiScreen> {
  final c=TextEditingController(); final scroll=ScrollController(); final service=LegalAiService.instance;
  final messages=<_Msg>[]; bool loading=false;
  @override void dispose(){c.dispose();scroll.dispose();super.dispose();}
  Future<void> ask() async {
    if(loading) return; final q=c.text.trim(); if(q.isEmpty)return;
    setState((){messages.add(_Msg.user(q));c.clear();loading=true;});
    _end();
    try{
      final history=messages.take(10).map((m)=>{'role':m.role,'content':m.text}).toList();
      final r=await service.ask(question:q,history:history);
      if(mounted)setState(()=>messages.add(_Msg.answer(r)));
    }catch(e){if(mounted)setState(()=>messages.add(_Msg.error(e.toString())));}
    finally{if(mounted){setState(()=>loading=false);_end();}}
  }
  void _end()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:250),curve:Curves.easeOut);});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('اسأل موسوعة القوانين'),centerTitle:true),
    body:SafeArea(child:Column(children:[
      _Intro(),
      Expanded(child:messages.isEmpty?_Empty(onTap:(q){c.text=q;ask();}):ListView.builder(controller:scroll,padding:const EdgeInsets.all(14),itemCount:messages.length,itemBuilder:(_,i)=>_Message(m:messages[i]))),
      if(loading)const LinearProgressIndicator(minHeight:2),
      Container(
        padding:const EdgeInsets.fromLTRB(8,6,8,10),
        decoration:BoxDecoration(color:context.surfaceAlt,border:Border(top:BorderSide(color:context.divider))),
        child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
          IconButton(onPressed:loading?null:ask,icon:Icon(Icons.send_rounded,color:context.accent)),
          Expanded(child:TextField(controller:c,enabled:!loading,minLines:1,maxLines:5,textAlign:TextAlign.right,decoration:const InputDecoration(hintText:'اكتب سؤالك القانوني هنا...',border:InputBorder.none),onSubmitted:(_)=>ask())),
        ]),
      )
    ])),
  );
}
class _Intro extends StatelessWidget{
  @override Widget build(BuildContext context)=>Container(
    margin:const EdgeInsets.fromLTRB(14,14,14,8),padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:context.surfaceAlt,borderRadius:BorderRadius.circular(22),border:Border.all(color:context.accent.withOpacity(.35))),
    child:Row(children:[Icon(Icons.balance_rounded,color:context.accent,size:38),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
      Text('اسأل موسوعة القوانين اليمنية',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18,color:context.textPrimary)),
      const SizedBox(height:4),Text('اطرح سؤالك وسأبحث في القوانين اليمنية المتاحة في الموسوعة.',textAlign:TextAlign.right,style:TextStyle(color:context.textSecondary,height:1.45))
    ]))]));
}
class _Empty extends StatelessWidget{
  final ValueChanged<String> onTap; const _Empty({required this.onTap});
  @override Widget build(BuildContext context){const qs=['ما هي شروط الطلاق؟','ما عقوبة السرقة؟','ما المادة المتعلقة بالنفقة؟','اشرح لي المادة 15 بطريقة بسيطة.','ما الفرق بين النصين القانونيين؟'];
    return ListView(padding:const EdgeInsets.all(16),children:[Text('جرّب أحد الأسئلة',textAlign:TextAlign.right,style:TextStyle(fontWeight:FontWeight.w800,color:context.textPrimary)),const SizedBox(height:10),for(final q in qs)Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:Icon(Icons.arrow_back_ios_new_rounded,size:15,color:context.accent),title:Text(q,textAlign:TextAlign.right),onTap:()=>onTap(q)))]);
  }
}
class _Msg{
  final String role,text; final LegalAiResult? result;
  const _Msg(this.role,this.text,this.result);
  factory _Msg.user(String t)=>_Msg('user',t,null);
  factory _Msg.answer(LegalAiResult r)=>_Msg('assistant',r.answer,r);
  factory _Msg.error(String t)=>_Msg('error',t,null);
}
class _Message extends StatelessWidget{
  final _Msg m; const _Message({required this.m});
  @override Widget build(BuildContext context){final user=m.role=='user',err=m.role=='error';
    return Align(alignment:user?Alignment.centerLeft:Alignment.centerRight,child:Container(
      constraints:const BoxConstraints(maxWidth:760),margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:user?context.accent.withOpacity(.12):err?Colors.red.withOpacity(.08):context.surfaceAlt,borderRadius:BorderRadius.circular(18),border:Border.all(color:err?Colors.red.withOpacity(.25):context.divider)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
        Text(user?'سؤالك':err?'تنبيه':'الإجابة',style:TextStyle(fontWeight:FontWeight.w900,color:err?Colors.redAccent:context.accent)),
        const SizedBox(height:7),SelectableText(m.text,textAlign:TextAlign.right,style:TextStyle(color:context.textPrimary,height:1.7)),
        if(m.result!=null&&m.result!.sources.isNotEmpty)...[const SizedBox(height:16),Text('المصادر القانونية',textAlign:TextAlign.right,style:TextStyle(fontWeight:FontWeight.w900,color:context.textPrimary)),const SizedBox(height:8),for(final s in m.result!.sources)_Source(s:s)]
      ])));
  }
}
class _Source extends StatelessWidget{
  final LegalAiSource s; const _Source({required this.s});
  @override Widget build(BuildContext context)=>Card(child:InkWell(
    onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>ArticleDetailScreen(maddaId:s.articleId))),
    child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
      Text(s.lawName,textAlign:TextAlign.right,style:TextStyle(fontWeight:FontWeight.w800,color:context.accent)),
      const SizedBox(height:4),Text('المادة: ${s.articleNumber}',textAlign:TextAlign.right,style:TextStyle(fontWeight:FontWeight.w700,color:context.textPrimary)),
      const SizedBox(height:7),Text(s.articleText,maxLines:5,overflow:TextOverflow.ellipsis,textAlign:TextAlign.right,style:TextStyle(color:context.textSecondary,height:1.5)),
      const SizedBox(height:8),Row(mainAxisAlignment:MainAxisAlignment.start,children:[Text('فتح المادة في الموسوعة',style:TextStyle(color:context.accent,fontWeight:FontWeight.w700)),const SizedBox(width:5),Icon(Icons.open_in_new_rounded,size:16,color:context.accent)])
    ]))));
}
