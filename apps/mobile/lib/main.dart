// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart' as material_widgets_ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:livekit_client/livekit_client.dart' hide ConnectionState;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://xgdngnekihhnkzurhvpe.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_RS7zMUhSXPJGooi8lQmMIQ_NyS4pS-h');
const ink = Color(0xFF07151A), panel = Color(0xFF102329), emerald = Color(0xFF18A878), gold = Color(0xFFE6BC55), muted = Color(0xFF9BAEAA);
const MethodChannel _callRingtoneChannel = MethodChannel('creatorverse/call_ringtone');
const MethodChannel _mediaSaverChannel = MethodChannel('creatorverse/media_saver');

String _mediaMimeFromUrl(String url,{required bool video}) {
  final path=(Uri.tryParse(url)?.path??'').toLowerCase();
  if(path.endsWith('.png')) { return 'image/png'; }
  if(path.endsWith('.webp')) { return 'image/webp'; }
  if(path.endsWith('.gif')) { return 'image/gif'; }
  if(path.endsWith('.webm')) { return 'video/webm'; }
  if(path.endsWith('.mov')) { return 'video/quicktime'; }
  return video?'video/mp4':'image/jpeg';
}

Future<void> _saveRemoteMedia(BuildContext context,String url,String mime,String name) async {
  try {
    await _mediaSaverChannel.invokeMethod<String>('save',{'url':url,'mime':mime,'name':name});
    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Media saved to your device.')));
    }
  } on PlatformException catch(error) {
    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(error.message??'Could not save this media.')));
    }
  } catch(error) {
    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Could not save this media: $error')));
    }
  }
}

List<String> parseSkillsInput(String input) => input.split(',')
  .map((value) => value.trim()).where((value) => value.isNotEmpty).toList();

String sanitizeSearchTerm(String input) => input
  .replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ _-]'), ' ')
  .replaceAll(RegExp(r'\s+'), ' ').trim();

Future<Uint8List> buildPaymentReceiptPdf(Map<String,dynamic> order) async {
  final doc=pw.Document();
  final amount=(order['amount_ngn'] as num?)?.toInt() ?? 0;
  final issued=DateTime.tryParse((order['receipt_issued_at'] ?? order['confirmed_at'] ?? '').toString());
  doc.addPage(pw.Page(pageFormat:PdfPageFormat.a4,margin:const pw.EdgeInsets.all(42),build:(ctx)=>pw.Column(
    crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
      pw.Text('CREATORVERSE',style:pw.TextStyle(fontSize:24,fontWeight:pw.FontWeight.bold)),
      pw.SizedBox(height:4),pw.Text('OFFICIAL PAYMENT RECEIPT',style:const pw.TextStyle(fontSize:11)),
      pw.Divider(height:28),pw.Text('RECEIPT NUMBER',style:pw.TextStyle(fontSize:9,color:PdfColors.grey700)),
      pw.Text((order['receipt_number'] ?? '').toString(),style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold)),
      pw.SizedBox(height:20),pw.Container(width:double.infinity,padding:const pw.EdgeInsets.all(16),
        decoration:pw.BoxDecoration(color:PdfColors.grey100,borderRadius:pw.BorderRadius.circular(8)),
        child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
          pw.Text('AMOUNT RECEIVED',style:pw.TextStyle(fontSize:9,color:PdfColors.grey700)),
          pw.Text('NGN $amount',style:pw.TextStyle(fontSize:26,fontWeight:pw.FontWeight.bold)),
          pw.Text('STATUS: CONFIRMED',style:pw.TextStyle(fontSize:10,color:PdfColors.green800)),
        ])),
      pw.SizedBox(height:22),pw.Text('PAYMENT DETAILS',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),
      pw.Divider(),
      _receiptPdfRow('Payer',(order['receipt_payer_name'] ?? order['payer_name'] ?? 'CreatorVerse learner').toString()),
      _receiptPdfRow('Course',(order['receipt_course_title'] ?? (order['courses'] is Map ? order['courses']['title'] : null) ?? 'CreatorVerse course').toString()),
      _receiptPdfRow('Method',(order['method'] ?? '').toString().replaceAll('_',' ').toUpperCase()),
      _receiptPdfRow('CreatorVerse reference',(order['reference'] ?? '').toString()),
      _receiptPdfRow('Bank / USSD reference',(order['transfer_reference'] ?? '').toString()),
      _receiptPdfRow('Confirmed',(issued?.toLocal().toString() ?? 'Not available')),
      _receiptPdfRow('Currency',(order['currency'] ?? 'NGN').toString()),
      pw.SizedBox(height:24),pw.Divider(),
      pw.Text('This receipt confirms that CreatorVerse recorded this payment as received after administrator verification.',
        style:const pw.TextStyle(fontSize:9,color:PdfColors.grey700)),
      pw.Spacer(),pw.Center(child:pw.Text('CreatorVerse · Payment record',style:const pw.TextStyle(fontSize:8,color:PdfColors.grey600))),
    ])));
  return doc.save();
}
pw.Widget _receiptPdfRow(String label,String value)=>pw.Padding(
  padding:const pw.EdgeInsets.symmetric(vertical:7),
  child:pw.Row(children:[
    pw.SizedBox(width:145,child:pw.Text(label,style:const pw.TextStyle(fontSize:10,color:PdfColors.grey700))),
    pw.Expanded(child:pw.Text(value.isEmpty?'Not recorded':value,style:pw.TextStyle(fontSize:10,fontWeight:pw.FontWeight.bold))),
  ]));
Future<void> printPaymentReceipt(BuildContext context,Map<String,dynamic> order) async {
  if(order['status']!='confirmed'||(order['receipt_number']??'').toString().isEmpty){
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('A receipt is available only after payment confirmation.')));return;
  }
  try { await Printing.layoutPdf(onLayout:(_)=>buildPaymentReceiptPdf(order),name:'CreatorVerse-${order['receipt_number']}.pdf'); }
  catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not open receipt for printing: $e')));}
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (error) {
    // Firebase push is optional in local/dev builds without the Android config.
    debugPrint('CreatorVerse Firebase initialization skipped: $error');
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(const CreatorVerseApp());
}

class OfflineCourseCache {
 static const maxAge=Duration(days:7);
 static String _ck(String u,String c)=>'cv_offline_course_${u}_$c';
 static String _nk(String u)=>'cv_notifications_$u';
 static String _pk(String u)=>'cv_pending_reads_$u';
 static Future<void> saveCourse(String u,String c,List<Map<String,dynamic>> m) async {final p=await SharedPreferences.getInstance();await p.setString(_ck(u,c),jsonEncode({'saved_at':DateTime.now().toUtc().toIso8601String(),'modules':m}));}
 static Future<List<Map<String,dynamic>>?> readCourse(String u,String c) async {final p=await SharedPreferences.getInstance();final raw=p.getString(_ck(u,c));if(raw==null)return null;try{final d=jsonDecode(raw) as Map<String,dynamic>;final at=DateTime.tryParse((d['saved_at']??'').toString());if(at==null||DateTime.now().toUtc().difference(at)>maxAge){await p.remove(_ck(u,c));return null;}return (d['modules'] as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();}catch(_){await p.remove(_ck(u,c));return null;}}
 static Future<void> clearCourse(String u,String c) async {final p=await SharedPreferences.getInstance();await p.remove(_ck(u,c));}
 static Future<void> saveNotifications(String u,List<Map<String,dynamic>> rows) async {final p=await SharedPreferences.getInstance();await p.setString(_nk(u),jsonEncode(rows));}
 static Future<List<Map<String,dynamic>>> readNotifications(String u) async {final p=await SharedPreferences.getInstance();final raw=p.getString(_nk(u));if(raw==null)return [];try{return (jsonDecode(raw) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();}catch(_){return [];}}
 static Future<void> queueRead(String u,String id) async {final p=await SharedPreferences.getInstance();final ids=p.getStringList(_pk(u))??<String>[];if(!ids.contains(id))ids.add(id);await p.setStringList(_pk(u),ids);}
 static Future<void> syncPendingReads(SupabaseClient db,String u) async {final p=await SharedPreferences.getInstance();final key=_pk(u);final ids=p.getStringList(key)??<String>[];if(ids.isEmpty)return;final remain=<String>[];for(final id in ids){try{await db.from('cv_notifications').update({'read_at':DateTime.now().toUtc().toIso8601String()}).eq('id',id).eq('user_id',u);}catch(_){remain.add(id);}}await p.setStringList(key,remain);}
}

class CreatorVerseApp extends StatelessWidget {
  const CreatorVerseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CreatorVerse', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: ink, useMaterial3: true,
      colorScheme: const ColorScheme.dark(primary: emerald, secondary: gold, surface: panel),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: emerald)))),
    home: const CreatorVerseLaunchGate());
}

class CreatorVerseLaunchGate extends StatelessWidget {
  const CreatorVerseLaunchGate({super.key});

  // Supabase.initialize completes before runApp, so AuthGate can restore the
  // saved session on the first frame. Avoid a second timed overlay that hides
  // an already-ready screen and creates an unnecessary loading flash.
  @override
  Widget build(BuildContext context) => const AuthGate();
}
class _CreatorVerseLoadingGate extends StatefulWidget {
  const _CreatorVerseLoadingGate();
  @override
  State<_CreatorVerseLoadingGate> createState() => _CreatorVerseLoadingGateState();
}
class _CreatorVerseLoadingGateState extends State<_CreatorVerseLoadingGate>
    with TickerProviderStateMixin {
  late final AnimationController _outer = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1500),
  )..repeat();
  late final AnimationController _inner = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 2400),
  )..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  @override
  void dispose() { _outer.dispose(); _inner.dispose(); _pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF06130C),
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.04), radius: .8,
          colors: [Color(0x3035AE5E), Color(0xFF06130C)],
          stops: [0, .72],
        ),
      ),
      child: Center(child: SizedBox(
        width: 156, height: 156,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(animation: _outer, builder: (context, child) => Transform.rotate(
            angle: _outer.value * 6.283185307,
            child: Container(decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: const Border(
                top: BorderSide(color: Color(0xFF9DF5B8), width: 1.4),
                right: BorderSide(color: Colors.transparent, width: 1),
                bottom: BorderSide(color: Color(0x5555E18B), width: 1),
                left: BorderSide(color: Color(0x5555E18B), width: 1),
              ),
              boxShadow: [BoxShadow(color: const Color(0x2236D878), blurRadius: 25)],
            )),
          )),
          AnimatedBuilder(animation: _inner, builder: (context, child) => Transform.rotate(
            angle: -_inner.value * 6.283185307,
            child: Container(
              width: 124, height: 124,
              decoration: const BoxDecoration(shape: BoxShape.circle,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2C66D), width: 1.4),
                  left: BorderSide(color: Colors.transparent, width: 1),
                  top: BorderSide(color: Color(0x44E2C66D), width: 1),
                  right: BorderSide(color: Color(0x44E2C66D), width: 1),
                )),
            ),
          )),
          AnimatedBuilder(animation: _pulse, builder: (context, child) => Transform.scale(
            scale: .94 + (_pulse.value * .10),
            child: SvgPicture.asset('assets/creatorverse-brand.svg', width: 104, height: 104,
              fit: BoxFit.contain,
            ),
          )),
          Positioned(right: 30, top: 10, child: Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD9EF87),
              boxShadow: [BoxShadow(color: Color(0xFFD9EF87), blurRadius: 18)]),
          )),
        ]),
      )),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(stream: auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, auth.currentSession),
      builder: (context, s) => s.data?.session == null ? const SignInScreen() : const MainShell());
  }
}
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}
class _SignInScreenState extends State<SignInScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController(), name = TextEditingController();
  bool create = false, busy = false, obscure = true, error = false;
  String? message;
  @override
  void initState() { super.initState(); SharedPreferences.getInstance().then((prefs) { final saved=prefs.getString('cv_last_login_email'); if(mounted && email.text.isEmpty && saved!=null) email.text=saved; }); }
  @override
  void dispose() { email.dispose(); password.dispose(); name.dispose(); super.dispose(); }

  Future<void> signInSocial(OAuthProvider provider) async {
    setState(() { busy = true; message = null; });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(provider,
        redirectTo: 'io.supabase.creatorverse://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication);
    } on AuthException catch (e) {
      if (mounted) setState(() { error = true; message = e.message; });
    } catch (_) {
      if (mounted) setState(() { error = true; message = 'Social sign-in could not start. Check your connection and provider setup.'; });
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() { busy = true; message = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (create) {
        final r = await auth.signUp(email: email.text.trim(), password: password.text, data: {'full_name': name.text.trim()});
        if (!mounted) return;
        setState(() { error = false; message = r.session == null ? 'Account created. Check your email to confirm, then sign in.' : 'Your account is ready.'; });
      } else {
        await auth.signInWithPassword(email: email.text.trim(), password: password.text);
        final prefs=await SharedPreferences.getInstance(); await prefs.setString('cv_last_login_email',email.text.trim());
      }
    } on AuthException catch (e) {
      if (mounted) setState(() { error = true; message = e.message; });
    } catch (_) {
      if (mounted) setState(() { error = true; message = 'Connection error. Please try again.'; });
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
      child: material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 82, height: 82, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22)),
          child: SvgPicture.asset('assets/creatorverse-brand.svg'))),
        const SizedBox(height: 24),
        const Text('CREATORVERSE', textAlign: TextAlign.center, style: TextStyle(color: gold, letterSpacing: 3, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(create ? 'Create your account' : 'Welcome back', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Learning, creativity and campus life in one place.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
        const SizedBox(height: 28),
        Form(key: form, child: material_widgets_ui.Column(children: [
          if (create) ...[
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null),
            const SizedBox(height: 14),
          ],
          TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
          const SizedBox(height: 14),
          TextFormField(controller: password, obscureText: obscure,
            decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            validator: (v) => v == null || v.length < 6 ? 'Use at least 6 characters' : null),
        ])),
        if (message != null) ...[const SizedBox(height: 14), Text(message!, style: TextStyle(color: error ? Colors.redAccent : gold))],
        const SizedBox(height: 20),
        FilledButton(onPressed: busy ? null : submit, style: FilledButton.styleFrom(backgroundColor: emerald, minimumSize: const Size.fromHeight(52)),
          child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(create ? 'Create account' : 'Sign in')),
        TextButton(onPressed: busy ? null : () => setState(() { create = !create; message = null; }),
          child: Text(create ? 'Already registered? Sign in' : 'New to CreatorVerse? Create an account')),
        if (!create) ...[
          const SizedBox(height: 10),
          const Row(children:[Expanded(child:Divider(color:Colors.white12)),Padding(padding:EdgeInsets.symmetric(horizontal:10),child:Text('OR CONTINUE WITH',style:TextStyle(color:muted,fontSize:10))),Expanded(child:Divider(color:Colors.white12))]),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed:busy?null:()=>signInSocial(OAuthProvider.google),
            icon:const Icon(Icons.g_mobiledata,size:24),label:const Text('Continue with Google')),
          const SizedBox(height:8),
          OutlinedButton.icon(onPressed:busy?null:()=>signInSocial(OAuthProvider.facebook),
            icon:const Icon(Icons.facebook,size:20),label:const Text('Continue with Facebook')),
          const SizedBox(height:8),
          OutlinedButton.icon(onPressed:null,icon:const Icon(Icons.camera_alt_outlined,size:19),
            label:const Text('Instagram sign-in (setup required)')),
        ],
        const SizedBox(height: 18),
        const Text('Your existing CreatorVerse website account works here too. Your last email is remembered on this device; passwords are never saved here.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
      ]))))));
}
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int index = 0;
  int unreadMessages = 0, unreadNotifications = 0;
  List<String> _conversationIds = [];
  late final List<Widget?> _pages;
  RealtimeChannel? _notificationBadgeChannel, _academyNotificationBadgeChannel, _messageBadgeChannel, _callInviteChannel;
  bool _incomingCallDialogOpen=false;
  final Set<String> _handledIncomingCallIds=<String>{};
  StreamSubscription<String>? _pushTokenSubscription;
  StreamSubscription<dynamic>? _authStateSubscription;
  bool _pushListenersInitialized = false;
  StreamSubscription<RemoteMessage>? _pushOpenSubscription;
  StreamSubscription<RemoteMessage>? _pushForegroundSubscription;
  final db = Supabase.instance.client;
  // The social feed is the signed-in app's primary landing screen.
  static const labels = ['Community', 'Learn', 'Explore', 'Campus', 'Profile'];

  Widget _pageFor(int tab) => switch (tab) {
    0 => const CommunityTab(),
    1 => const LearnTab(),
    2 => const HomeTab(),
    3 => const CampusTab(),
    4 => const ProfileTab(),
    _ => const CommunityTab(),
  };

  void _selectTab(int tab) {
    if (tab < 0 || tab >= labels.length) return;
    setState(() {
      index = tab;
      // Build each tab only when first visited. Keep it in the IndexedStack
      // afterward so its scroll position and loaded state remain stable.
      _pages[tab] ??= _pageFor(tab);
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(labels.length, null);
    _pages[0] = const CommunityTab();
    _refreshBadges();
    _registerPushNotifications();
    _authStateSubscription = db.auth.onAuthStateChange.listen((state) {
      if (state.session != null) _registerPushNotifications();
    });
    final userId = db.auth.currentUser?.id;
    if (userId != null) {
      _callInviteChannel=db.channel('cv-call-invites-$userId')
        .onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'cv_call_invites',
          filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'callee_id',value:userId),
          callback:(payload)=>unawaited(_handleIncomingCall(Map<String,dynamic>.from(payload.newRecord))))
        .subscribe();
      _notificationBadgeChannel = db.channel('cv-shell-notifications-$userId')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'cv_notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (_) { if (mounted) _refreshBadges(); }).subscribe();
      _academyNotificationBadgeChannel = db.channel('cv-shell-academy-notifications-$userId')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'academy_notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (_) { if (mounted) _refreshBadges(); }).subscribe();
      _messageBadgeChannel = db.channel('cv-shell-messages-$userId')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'cv_direct_messages',
          callback: (payload) {
            final row = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
            final conversationId = row['conversation_id']?.toString();
            if (conversationId != null && _conversationIds.contains(conversationId) && mounted) _refreshBadges();
          }).subscribe();
    }
  }


  Future<void> _stopIncomingCallRingtone() async {
    try { await _callRingtoneChannel.invokeMethod('stop'); } catch (_) {}
  }

  Future<void> _handleIncomingCall(Map<String,dynamic> payload) async{
    if(_incomingCallDialogOpen||(payload['status']??'')!='ringing')return;
    final callerId=(payload['caller_id']??'').toString();
    final callId=(payload['id']??'').toString();
    final conversationId=(payload['conversation_id']??'').toString();
    final mode=(payload['mode']??'audio').toString();
    final expiry=DateTime.tryParse((payload['expires_at']??'').toString());
    if(callerId.isEmpty||callerId==db.auth.currentUser?.id||callId.isEmpty||
       conversationId.isEmpty||!['audio','video'].contains(mode)||
       (expiry!=null&&expiry.isBefore(DateTime.now()))||
       !_handledIncomingCallIds.add(callId)) { return; }
    _incomingCallDialogOpen=true;
    try{await _callRingtoneChannel.invokeMethod('start');}catch(_){}
    String callerName='CreatorVerse member';
    try{
      final profile=await db.from('public_profiles').select('full_name,username').eq('id',callerId).maybeSingle();
      callerName=(profile?['full_name']??profile?['username']??callerName).toString();
    }catch(_){}
    if(!mounted){_incomingCallDialogOpen=false;await _stopIncomingCallRingtone();return;}
    bool? accept;
    bool callClosedRemotely=false;
    BuildContext? incomingDialogContext;
    RealtimeChannel? incomingStatusChannel;
    try{
      incomingStatusChannel=db.channel('cv-incoming-status-$callId')
        .onPostgresChanges(event:PostgresChangeEvent.update,schema:'public',table:'cv_call_invites',
          filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'id',value:callId),
          callback:(change){
            final status=(change.newRecord['status']??'').toString();
            if(status!='ringing'&&_incomingCallDialogOpen){
              callClosedRemotely=true;
              final dialogContext=incomingDialogContext;
              if(dialogContext!=null){
                final navigator=material_widgets_ui.Navigator.of(dialogContext);
                if(navigator.canPop())navigator.pop(false);
              }
            }
          }).subscribe();
      accept=await showDialog<bool>(context:context,barrierDismissible:false,
        builder:(ctx){
          incomingDialogContext=ctx;
          return AlertDialog(backgroundColor:panel,
            title:Text(mode=='video'?'Incoming video call':'Incoming audio call'),
            content:Text('$callerName is calling you.'),
            actions:[
              TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),
                child:const Text('Decline',style:TextStyle(color:Colors.redAccent))),
              FilledButton.icon(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),
                icon:const Icon(Icons.call),label:const Text('Accept'),
                style:FilledButton.styleFrom(backgroundColor:emerald))
            ]);
        });
    }finally{
      _incomingCallDialogOpen=false;
      await _stopIncomingCallRingtone();
      final statusChannel=incomingStatusChannel;
      if(statusChannel!=null)unawaited(statusChannel.unsubscribe());
    }
    if(!mounted||callClosedRemotely)return;
    try{
      await db.rpc('cv_set_call_invite_status',params:{
        'p_call_id':callId,'p_status':accept==true?'accepted':'declined'
      });
      final latest=await db.from('cv_call_invites').select('status').eq('id',callId).single();
      if(accept==true&&latest['status']=='accepted'&&mounted){
        await material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CreatorVerseCallScreen(
          conversationId:conversationId,callId:callId,peerName:callerName,mode:mode,isCaller:false)));
      }
    }catch(e){
      _handledIncomingCallIds.remove(callId);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content:Text('Could not answer the call: $e')));
      }
    }
  }

  Future<void> _handleCallPush(RemoteMessage message,{bool opened=false}) async{
    final type=(message.data['type']??'').toString();
    final entityType=(message.data['entity_type']??'').toString();
    final callId=(message.data['entity_id']??'').toString();
    if(type=='incoming_call'&&entityType=='call'&&callId.isNotEmpty){
      try{
        final row=await db.from('cv_call_invites')
          .select('id,conversation_id,caller_id,callee_id,mode,status,created_at,expires_at')
          .eq('id',callId).maybeSingle();
        if(row!=null&&mounted)await _handleIncomingCall(Map<String,dynamic>.from(row));
      }catch(error){debugPrint('Could not load incoming call from notification: $error');}
      return;
    }
    if(opened&&mounted)_openNotifications();
  }

  Future<void> _registerPushNotifications() async {
    if (Firebase.apps.isEmpty) return;
    if (db.auth.currentUser == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;

      Future<void> saveToken(String token) async {
        final currentUserId = db.auth.currentUser?.id;
        if (currentUserId == null) return;
        await db.from('cv_device_tokens').upsert({
          'user_id': currentUserId,
          'token': token,
          'platform': 'android',
          'device_label': 'CreatorVerse Android',
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'token');
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await saveToken(token);
      if (_pushListenersInitialized) {
        final currentToken = await messaging.getToken();
        if (currentToken != null && currentToken.isNotEmpty) await saveToken(currentToken);
        return;
      }
      _pushListenersInitialized = true;
      _pushTokenSubscription = messaging.onTokenRefresh.listen((token) {
        saveToken(token).catchError((error) {
          debugPrint('Could not refresh CreatorVerse push token: $error');
        });
      });
      _pushOpenSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        unawaited(_handleCallPush(message,opened:true));
      });
      _pushForegroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        if (!mounted) return;
        if ((message.data['type']??'').toString()=='incoming_call') {
          unawaited(_handleCallPush(message));
          return;
        }
        final title = message.notification?.title ?? message.data['title']?.toString() ?? 'CreatorVerse update';
        final body = message.notification?.body ?? message.data['body']?.toString() ?? 'You have a new notification.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body.isEmpty ? title : '$title: $body'),
          action: SnackBarAction(label: 'VIEW', onPressed: _openNotifications),
          duration: const Duration(seconds: 5),
        ));
      });
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_handleCallPush(initialMessage,opened:true));
        });
      }
    } catch (error) {
      debugPrint('CreatorVerse push registration failed: $error');
    }
  }

  Future<void> _refreshBadges() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final conversationsRaw = await db.from('cv_conversations').select('id')
        .or('user_a.eq.$userId,user_b.eq.$userId');
      final ids = List<Map<String, dynamic>>.from(conversationsRaw)
        .map((row) => row['id'].toString()).toList();
      final notificationRows = await db.from('cv_notifications').select('id')
        .eq('user_id', userId).isFilter('read_at', null);
      final academyNotificationRows = await db.from('academy_notifications').select('id')
        .eq('user_id', userId).isFilter('read_at', null)
        .lte('scheduled_for', DateTime.now().toUtc().toIso8601String());
      final unreadNotificationIds = <String>{
        ...List<Map<String, dynamic>>.from(notificationRows).map((row) => row['id'].toString()),
        ...List<Map<String, dynamic>>.from(academyNotificationRows).map((row) => row['id'].toString()),
      };
      var messageCount = 0;
      if (ids.isNotEmpty) {
        final unread = await db.from('cv_direct_messages').select('id')
          .inFilter('conversation_id', ids).neq('sender_id', userId)
          .isFilter('read_at', null).count(CountOption.exact);
        messageCount = unread.count;
      }
      if (!mounted) return;
      setState(() {
        _conversationIds = ids;
        unreadMessages = messageCount;
        unreadNotifications = unreadNotificationIds.length;
      });
    } catch (_) {
      // Keep the last known counts visible if the network is temporarily unavailable.
    }
  }

  Widget _badgeAction({required IconData icon, required String tooltip, required int count, required VoidCallback onPressed}) {
    return IconButton(tooltip: tooltip, onPressed: onPressed, icon: Stack(clipBehavior: Clip.none, children: [
      Icon(icon),
      if (count > 0) Positioned(right: -9, top: -8, child: Container(
        constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ink, width: 1.5)),
        child: Text(count > 99 ? '99+' : count.toString(), textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, height: 1.35, fontWeight: FontWeight.w800, color: Colors.white)),
      )),
    ]));
  }

  Future<void> _openMessages() async {
    await material_widgets_ui.Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessageInboxScreen()));
    if (mounted) _refreshBadges();
  }

  Future<void> _openNotifications() async {
    await material_widgets_ui.Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Notifications')), body: const NotificationsScreen())));
    if (mounted) _refreshBadges();
  }

  @override
  void dispose() {
    final n = _notificationBadgeChannel, a = _academyNotificationBadgeChannel, m = _messageBadgeChannel;
    if (n != null) unawaited(n.unsubscribe());
    if (a != null) unawaited(a.unsubscribe());
    if (m != null) unawaited(m.unsubscribe());
    final incoming=_callInviteChannel;if(incoming!=null)unawaited(incoming.unsubscribe());
    _authStateSubscription?.cancel();
    _pushTokenSubscription?.cancel();
    _pushOpenSubscription?.cancel();
    _pushForegroundSubscription?.cancel();
    unawaited(_stopIncomingCallRingtone());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = List<Widget>.generate(
      _pages.length,
      (tab) => _pages[tab] ?? const SizedBox.shrink(),
      growable: false,
    );
    return Scaffold(
      appBar: AppBar(title: Row(children: [SvgPicture.asset('assets/creatorverse-brand.svg', width: 30, height: 30),
        const SizedBox(width: 9),
        material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CreatorVerse', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: .25)),
          Text(labels[index], style: const TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w500)),
        ])]),
        actions: [
          _badgeAction(icon: Icons.chat_bubble_outline, tooltip: 'Messages', count: unreadMessages, onPressed: _openMessages),
          _badgeAction(icon: Icons.notifications_none, tooltip: 'Notifications', count: unreadNotifications, onPressed: _openNotifications),
        ]),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: _selectTab,
        backgroundColor: panel, indicatorColor: emerald.withValues(alpha: .2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.location_city_outlined), selectedIcon: Icon(Icons.location_city), label: 'Campus'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile')]));
  }
}
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override State<HomeTab> createState()=>_HomeTabState();
}
class _HomeTabState extends State<HomeTab>{
  late Future<Map<String,dynamic>> summary;
  RealtimeChannel? _syncChannel;
  Timer? _syncTimer;
  @override void initState(){
    super.initState();summary=loadSummary();
    final userId=Supabase.instance.client.auth.currentUser?.id;
    if(userId!=null){
      _syncChannel=Supabase.instance.client.channel('cv-home-sync-$userId')
        .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'profiles',
          filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'id',value:userId),
          callback:(_)=>_scheduleSync())
        .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'enrolments',
          filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'user_id',value:userId),
          callback:(_)=>_scheduleSync())
        .subscribe();
    }
  }
  void _scheduleSync(){
    _syncTimer?.cancel();
    _syncTimer=Timer(const Duration(milliseconds:450),(){
      if(mounted)setState(()=>summary=loadSummary());
    });
  }
  @override void dispose(){
    _syncTimer?.cancel();
    final channel=_syncChannel;if(channel!=null)unawaited(channel.unsubscribe());
    super.dispose();
  }
  Future<Map<String,dynamic>> loadSummary() async {
    final db=Supabase.instance.client;final user=db.auth.currentUser;
    if(user==null)return {'name':'','enrolled':0,'unread':0};
    final profile=await db.from('profiles').select('full_name,role').eq('id',user.id).maybeSingle();
    final enrolled=await db.from('enrolments').select('course_id').eq('user_id',user.id).count(CountOption.exact);
    final unread=await db.from('cv_notifications').select('id').eq('user_id',user.id).isFilter('read_at',null).count(CountOption.exact);
    return {'name':(profile?['full_name']??user.userMetadata?['full_name']??'').toString(),
      'role':(profile?['role']??'student').toString(),'enrolled':enrolled.count,'unread':unread.count};
  }
  @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(future:summary,builder:(context,snapshot){
    final data=snapshot.data??{};
    final name=(data['name']??Supabase.instance.client.auth.currentUser?.userMetadata?['full_name']??'').toString();
    return ListView(padding:const EdgeInsets.all(20),children:[
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFF123D35),panel]),
        border:Border.all(color:emerald.withValues(alpha:.3))),
        child:material_widgets_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('YOUR NEXT CHAPTER STARTS HERE',style:TextStyle(color:gold,fontSize:10,letterSpacing:1.2,fontWeight:FontWeight.w800)),
          const SizedBox(height:12),Text('Hello${name.isEmpty?'':', $name'}.',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w800)),
          const SizedBox(height:8),const Text('Learn new skills, explore opportunities and find your community.',style:TextStyle(color:Colors.white70,height:1.5)),
          const SizedBox(height:16),FilledButton(onPressed:()=>openFeature(context,'/divisions.html'),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('Explore CreatorVerse')),
        ])),
      const SizedBox(height:16),
      if(snapshot.connectionState==ConnectionState.waiting)const LinearProgressIndicator(color:emerald),
      if(snapshot.hasError)const Text('Your learning summary will appear when the connection is restored.',style:TextStyle(color:muted,fontSize:12)),
      if(snapshot.hasData)Row(children:[
        Expanded(child:Card(color:panel,child:ListTile(leading:const Icon(Icons.menu_book_outlined,color:emerald),title:Text('${data['enrolled']??0}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),subtitle:const Text('Enrolled courses',style:TextStyle(color:muted,fontSize:11))))),
        const SizedBox(width:8),
        Expanded(child:Card(color:panel,child:ListTile(leading:const Icon(Icons.notifications_none,color:gold),title:Text('${data['unread']??0}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),subtitle:const Text('Unread alerts',style:TextStyle(color:muted,fontSize:11))))),
      ]),
      const SizedBox(height:12),const Text('Explore your spaces',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
      const SizedBox(height:12),
      const FeatureTile(icon:Icons.auto_awesome_outlined,title:'Digital Skills',detail:'Build practical and creative skills.',path:'/digital-skills.html'),
      const FeatureTile(icon:Icons.school_outlined,title:'Academic',detail:'Find learning pathways and study resources.',path:'/academic.html'),
      const FeatureTile(icon:Icons.apartment_outlined,title:'Campus Life',detail:'Discover accommodation and campus services.',path:'/campus.html'),
      const FeatureTile(icon:Icons.storefront_outlined,title:'Marketplace',detail:'Explore the CreatorVerse marketplace.',path:'/marketplace.html'),
      const FeatureTile(icon:Icons.assignment_ind_outlined,title:'Creator / Instructor Pathway',detail:'Apply to create, teach or showcase work on CreatorVerse.',path:'/academy-applications'),
      const FeatureTile(icon:Icons.workspace_premium_outlined,title:'My Certificates',detail:'View certificates issued after Academy review.',path:'/certificates'),
      const FeatureTile(icon:Icons.groups_outlined,title:'Community',detail:'Connect with other learners and creators.',path:'/community.html'),
    ]);
  });
}

class LearnTab extends StatefulWidget {
  const LearnTab({super.key});
  @override
  State<LearnTab> createState() => _LearnTabState();
}
class _LearnTabState extends State<LearnTab> {
  late Future<List<Map<String, dynamic>>> courses;
  final search = TextEditingController();
  String category = '';
  RealtimeChannel? _syncChannel;
  Timer? _syncTimer;
  @override
  void initState() {
    super.initState(); courses = loadCourses();
    _syncChannel=Supabase.instance.client.channel('cv-learn-courses-sync')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'courses',
        callback:(_){
          _syncTimer?.cancel();
          _syncTimer=Timer(const Duration(milliseconds:500),(){
            if(mounted)setState(()=>courses=loadCourses());
          });
        }).subscribe();
  }
  Future<List<Map<String, dynamic>>> loadCourses() async {
    final rows = await Supabase.instance.client.from('courses')
      .select('id,slug,title,description,category_slug,level,duration_text,thumbnail_url,price_ngn,featured')
      .eq('published', true).order('featured', ascending: false).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
  @override void dispose() {
    search.dispose();_syncTimer?.cancel();
    final channel=_syncChannel;if(channel!=null)unawaited(channel.unsubscribe());
    super.dispose();
  }
  Future<void> reload() async { final next = loadCourses(); setState(() => courses = next); await next; }
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: courses,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: emerald));
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 42, color: muted),
          const SizedBox(height: 12), const Text('Courses could not be loaded', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8), const Text('Check your connection and try again.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
          const SizedBox(height: 16), OutlinedButton.icon(onPressed: reload, icon: const Icon(Icons.refresh), label: const Text('Try again')),
        ])));
      }
      final items = snapshot.data ?? [];
      final categories = items.map((c)=>(c['category_slug']??'').toString()).where((v)=>v.isNotEmpty).toSet().toList()..sort();
      final term=search.text.trim().toLowerCase();
      final filtered=items.where((c){
        final matchesCategory=category.isEmpty||(c['category_slug']??'').toString()==category;
        final haystack='${c['title']??''} ${c['description']??''} ${c['level']??''}'.toLowerCase();
        return matchesCategory&&(term.isEmpty||haystack.contains(term));
      }).toList();
      return RefreshIndicator(color: emerald, onRefresh: reload,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Learn and grow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Explore programmes published by CreatorVerse.', style: TextStyle(color: muted)),
          const SizedBox(height: 14),
          TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search courses, skills or topics')),
          if(categories.isNotEmpty)Padding(padding:const EdgeInsets.only(top:10),child:Wrap(spacing:7,runSpacing:6,children:[
            ChoiceChip(label:const Text('All'),selected:category.isEmpty,onSelected:(_)=>setState(()=>category='')),
            for(final item in categories)ChoiceChip(label:Text(item.replaceAll('-',' ')),selected:category==item,onSelected:(_)=>setState(()=>category=item)),
          ])),
          const SizedBox(height: 18),
          if(items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No published courses are available yet.', textAlign: TextAlign.center, style: TextStyle(color: muted))),
          if(items.isNotEmpty&&filtered.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('No courses match your search.',textAlign:TextAlign.center,style:TextStyle(color:muted))),
          for (final course in filtered) CourseCard(course: course),
        ]));
    });
}

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const CourseCard({super.key, required this.course});
  @override
  Widget build(BuildContext context) {
    final image = course['thumbnail_url'] as String?;
    final price = (course['price_ngn'] as num?)?.toInt() ?? 0;
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: Material(
      color: panel, borderRadius: BorderRadius.circular(18), clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: () {
        if (price <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This course is temporarily unavailable while its price is being set.')));
          return;
        }
        material_widgets_ui.Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CourseCheckoutScreen(course: course)));
      }, child: material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (image != null && image.startsWith('https://'))
            Image.network(image, height: 150, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 90, color: const Color(0xFF17352F), child: const Icon(Icons.menu_book, color: emerald, size: 34))),
          Padding(padding: const EdgeInsets.all(16), child: material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text((course['level'] ?? 'Course').toString(), style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w700))),
              Text(price <= 0 ? 'PRICE PENDING' : '₦${price.toString()}', style: const TextStyle(color: emerald, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 7),
            Text((course['title'] ?? 'Untitled course').toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text((course['description'] ?? '').toString(), maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, height: 1.4, fontSize: 12)),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.schedule, size: 15, color: muted), const SizedBox(width: 5),
              Expanded(child: Text((course['duration_text'] ?? 'Self-paced').toString(), style: const TextStyle(color: muted, fontSize: 12))),
              const Text('View course', style: TextStyle(color: emerald, fontWeight: FontWeight.w700, fontSize: 12)),
              const Icon(Icons.chevron_right, color: emerald, size: 18),
            ]),
          ])),
        ])),
    ));
  }
}

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  const CourseDetailScreen({super.key, required this.course});
  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}
class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> curriculum;
  late Future<List<Map<String, dynamic>>> quizzes;
  late Future<bool> enrollment;
  @override
  void initState() { super.initState(); enrollment = loadEnrollment(); curriculum = loadCurriculum(); quizzes = loadQuizzes(); }

  Future<bool> loadEnrollment() async {
    final user=db.auth.currentUser;if(user==null)return false;
    try{final row=await db.from('enrolments').select('course_id').eq('user_id',user.id).eq('course_id',widget.course['id']).maybeSingle();if(row==null){await OfflineCourseCache.clearCourse(user.id,widget.course['id'].toString());return false;}return true;}
    catch(_){return await OfflineCourseCache.readCourse(user.id,widget.course['id'].toString())!=null;}
  }

  void refreshCourse() => setState(() { enrollment = loadEnrollment(); curriculum = loadCurriculum(); quizzes = loadQuizzes(); });

  Future<void> saveCourseOffline() async {
    final user=db.auth.currentUser;
    if(user==null){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Sign in to save this course offline.')));return;}
    try{
      final enrolled=await db.from('enrolments').select('course_id').eq('user_id',user.id).eq('course_id',widget.course['id']).maybeSingle()!=null;
      if(!enrolled){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Only courses with confirmed enrolment can be saved offline.')));return;}
      final modules=await loadCurriculum();
      await OfflineCourseCache.saveCourse(user.id,widget.course['id'].toString(),modules);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Course lessons saved for offline reading for up to 7 days. Video streaming and external links still require internet.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save course offline: $e')));}
  }



  Future<List<Map<String,dynamic>>> loadCurriculum() async {
    final user=db.auth.currentUser;if(user==null)return [];final courseId=widget.course['id'].toString();
    try{
      final modulesRaw=await db.from('modules').select('id,title,description,position,duration_text,stage_number').eq('course_id',courseId).order('position');
      final modules=List<Map<String,dynamic>>.from(modulesRaw);if(modules.isEmpty)return [];
      final ids=modules.map((m)=>m['id']).toList();
      final enrolled=await db.from('enrolments').select('course_id').eq('user_id',user.id).eq('course_id',courseId).maybeSingle()!=null;
      if(!enrolled){await OfflineCourseCache.clearCourse(user.id,courseId);for(final m in modules){m['lessons']=<Map<String,dynamic>>[];}return modules;}
      final lessonsRaw=await db.from('lessons').select('id,module_id,title,video_url,content,position,estimated_minutes,chapter_number,topic_outline').inFilter('module_id',ids).order('position');
      final lessons=List<Map<String,dynamic>>.from(lessonsRaw);
      if(lessons.isNotEmpty){final lessonIds=lessons.map((l)=>l['id']).toList();
        final rr=await db.from('lesson_resources').select('id,lesson_id,title,url,position').inFilter('lesson_id',lessonIds).order('position');
        final resources=List<Map<String,dynamic>>.from(rr);
        final pr=await db.from('lesson_progress').select('lesson_id,completed_at').eq('user_id',user.id).inFilter('lesson_id',lessonIds);
        final completed=List<Map<String,dynamic>>.from(pr).map((r)=>r['lesson_id'].toString()).toSet();
        for(final l in lessons){l['resources']=resources.where((r)=>r['lesson_id']==l['id']).toList();l['completed']=completed.contains(l['id'].toString());}
      }
      for(final m in modules){m['lessons']=lessons.where((l)=>l['module_id']==m['id']).toList();}
      await OfflineCourseCache.saveCourse(user.id,courseId,modules);return modules;
    }catch(_){final cached=await OfflineCourseCache.readCourse(user.id,courseId);if(cached!=null)return cached;rethrow;}
  }

  Future<List<Map<String,dynamic>>> loadQuizzes() async {
    final rows = await db.from('quizzes').select('id,title,pass_mark')
      .eq('course_id',widget.course['id']).order('created_at');
    return List<Map<String,dynamic>>.from(rows);
  }

  Future<void> openLesson(Map<String,dynamic> lesson) async {
    final db=Supabase.instance.client;
    try {
      // Lesson viewing is recorded when online, but must never block cached offline reading.
      try { await db.rpc('record_academy_lesson_view',params:{'p_lesson_id':lesson['id']}); } catch (_) {}
      final raw=(lesson['video_url']??'').toString().trim();
      final uri=Uri.tryParse(raw);
      if(uri!=null&&(uri.scheme=='https'||uri.scheme=='http')) {
        await launchUrl(uri,mode:LaunchMode.externalApplication);
      }
      final content=(lesson['content']??'').toString().trim();
      final resources=lesson['resources'] as List<Map<String,dynamic>>? ?? [];
      if(content.isNotEmpty || resources.isNotEmpty || (uri != null && raw.isNotEmpty)) {
        if(!mounted)return;
        await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:panel,
          builder:(_)=>SafeArea(child:FractionallySizedBox(heightFactor:.82,child:ListView(padding:const EdgeInsets.all(22),children:[
            Text((lesson['title']??'Lesson').toString(),style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800)),
            const SizedBox(height:14),if(content.isNotEmpty)Text(content,style:const TextStyle(height:1.6,color:Colors.white70)),
            if(uri!=null && raw.isNotEmpty)Padding(padding:const EdgeInsets.only(top:16),child:OutlinedButton.icon(
              onPressed:()=>launchUrl(uri,mode:LaunchMode.externalApplication),icon:const Icon(Icons.play_circle_outline),label:const Text('Open lesson video'))),
            if(resources.isNotEmpty)...[
              const SizedBox(height:18),const Text('Lesson resources',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
              for(final resource in resources)ListTile(leading:const Icon(Icons.attach_file,color:emerald),
                title:Text((resource['title']??'Resource').toString()),
                onTap:()=>launchUrl(Uri.parse(resource['url'].toString()),mode:LaunchMode.externalApplication)),
            ],
          ]))));
      }
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not open lesson: $e')));
    }
  }
  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final price = (c['price_ngn'] as num?)?.toInt() ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Course overview'), actions: [
        IconButton(onPressed: saveCourseOffline, tooltip: 'Save paid lessons offline', icon: const Icon(Icons.download_for_offline_outlined)),
        IconButton(onPressed: refreshCourse, tooltip: 'Refresh enrolment', icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text((c['title'] ?? '').toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text((c['description'] ?? '').toString(), style: const TextStyle(color: muted, height: 1.5)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Chip(label: Text((c['level'] ?? 'All levels').toString())),
          Chip(label: Text((c['duration_text'] ?? 'Self-paced').toString())),
          Chip(label: Text(price <= 0 ? 'Price pending' : '₦${price.toString()}')),
        ]),
        const SizedBox(height: 14),
        FutureBuilder<bool>(future: enrollment, builder: (context, enrolledSnap) {
          if (enrolledSnap.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator(color: emerald);
          }
          final enrolled = enrolledSnap.data == true;
          if (enrolled) {
            return const ListTile(leading: Icon(Icons.check_circle, color: emerald), title: Text('You are enrolled'), subtitle: Text('Your learning access is active.', style: TextStyle(color: muted)));
          }
          if (price <= 0) {
            return const ListTile(leading: Icon(Icons.lock_outline, color: gold),
              title: Text('Course temporarily unavailable'),
              subtitle: Text('The administrator must set a course price before enrolment can open.', style: TextStyle(color: muted)));
          }
          return material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const ListTile(leading: Icon(Icons.lock_outline, color: gold), title: Text('Paid course'),
              subtitle: Text('Payment and administrator verification are required before course access.', style: TextStyle(color: muted))),
            OutlinedButton.icon(onPressed: () async { await material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => CourseCheckoutScreen(course: c))); if (mounted) refreshCourse(); },
              icon: const Icon(Icons.payments_outlined), label: const Text('Continue to payment')),
          ]);
        }),
        const SizedBox(height: 22),
        const Text('Course curriculum', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(future: curriculum, builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(22), child: Center(child: CircularProgressIndicator(color: emerald)));
          if (snapshot.hasError) return const Text('The course outline is temporarily unavailable.', style: TextStyle(color: muted));
          final modules = snapshot.data ?? [];
          if (modules.isEmpty) return const Text('Course lessons are being prepared.', style: TextStyle(color: muted));
          return material_widgets_ui.Column(children: [
            for (final module in modules) Card(color: panel, child: ExpansionTile(
              initiallyExpanded: false,
              title: Text((module['title'] ?? 'Module').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text((module['lessons'] as List).isEmpty ? 'Enrol to unlock lessons' : '${(module['lessons'] as List).where((l)=>l['completed']==true).length}/${(module['lessons'] as List).length} lessons completed', style: const TextStyle(color: muted, fontSize: 12)),
              children: [
                if ((module['description'] ?? '').toString().isNotEmpty)
                  Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Text(module['description'].toString(), style: const TextStyle(color: muted))),
                for (final lesson in module['lessons'] as List<Map<String, dynamic>>)
                  ListTile(
                    dense: true, leading: Icon(lesson['completed']==true?Icons.check_circle:Icons.play_circle_outline, color: emerald),
                    title: Text((lesson['title'] ?? 'Lesson').toString()),
                    subtitle: Text('${lesson['estimated_minutes'] ?? 0} min', style: const TextStyle(color: muted, fontSize: 11)),
                    trailing: lesson['video_url'] == null || lesson['video_url'].toString().isEmpty
                      ? null : const Icon(Icons.open_in_new, size: 16, color: muted),
                    onTap: () => openLesson(lesson),
                  ),
              ],
            )),
          ]);
        }),
        const SizedBox(height: 22),
        FutureBuilder<bool>(future: enrollment, builder: (context, enrolled) {
          if (enrolled.data != true) return const SizedBox.shrink();
          return FutureBuilder<List<Map<String,dynamic>>>(future: quizzes, builder: (context, quizSnap) {
            if (quizSnap.connectionState == ConnectionState.waiting) return const LinearProgressIndicator(color: emerald);
            if (quizSnap.hasError || (quizSnap.data ?? []).isEmpty) return const SizedBox.shrink();
            final items=quizSnap.data ?? [];
            return material_widgets_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Course assessments',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
              const SizedBox(height:8),
              for(final quiz in items)Card(color:panel,child:ListTile(
                leading:const Icon(Icons.quiz_outlined,color:gold),
                title:Text((quiz['title']??'Course quiz').toString()),
                subtitle:Text('Pass mark: ${quiz['pass_mark']}%',style:const TextStyle(color:muted)),
                trailing:const Icon(Icons.chevron_right,color:emerald),
                onTap:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseQuizScreen(quizId:quiz['id'].toString()))),
              )),
            ]);
          });
        }),
      ]),
    );
  }
}

class CourseQuizScreen extends StatefulWidget {
  final String quizId;
  const CourseQuizScreen({super.key,required this.quizId});
  @override State<CourseQuizScreen> createState()=>_CourseQuizScreenState();
}
class _CourseQuizScreenState extends State<CourseQuizScreen>{
  final db=Supabase.instance.client;
  late Future<Map<String,dynamic>> quiz;
  final Map<String,int> answers={};
  bool submitting=false;
  Map<String,dynamic>? result;
  @override void initState(){super.initState();quiz=load();}
  Future<Map<String,dynamic>> load() async {
    final raw=await db.rpc('get_quiz',params:{'p_quiz':widget.quizId});
    if(raw==null)throw StateError('This quiz is unavailable. Check your enrolment.');
    return Map<String,dynamic>.from(raw as Map);
  }
  Future<void> submit(Map<String,dynamic> data) async {
    final questions=data['questions'] as List? ?? [];
    if(answers.length!=questions.length){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Answer every question before submitting.')));return;
    }
    setState(()=>submitting=true);
    try{
      final raw=await db.rpc('submit_quiz',params:{
        'p_quiz':widget.quizId,
        'p_answers':answers.map((key,value)=>MapEntry(key,value)),
      });
      final outcome=Map<String,dynamic>.from(raw as Map);
      if(mounted)setState(()=>result=outcome);
      if(mounted) { showDialog<void>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,
        title:Text(outcome['passed']==true?'Assessment passed':'Assessment result'),
        content:Text('Score: ${outcome['score']}%\nCorrect: ${outcome['correct']} of ${outcome['total']}\nPass mark: ${outcome['pass_mark']}%\n\n${outcome['passed']==true?'Well done. Your result has been recorded.':'Review the lessons and try again.'}'),
        actions:[FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx),child:const Text('Continue'))])); }
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not submit assessment: $e')));}
    finally{if(mounted)setState(()=>submitting=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Course assessment')),body:FutureBuilder<Map<String,dynamic>>(future:quiz,builder:(context,snap){
    if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
    if(snap.hasError)return Center(child:Padding(padding:const EdgeInsets.all(20),child:Text('Assessment unavailable: ${snap.error}',textAlign:TextAlign.center,style:const TextStyle(color:muted))));
    final data=snap.data??{};final questions=data['questions'] as List? ?? [];
    return ListView(padding:const EdgeInsets.all(18),children:[
      Text((data['title']??'Assessment').toString(),style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800)),
      const SizedBox(height:6),Text('Pass mark: ${data['pass_mark']}% · ${questions.length} questions',style:const TextStyle(color:muted)),
      const SizedBox(height:16),
      for(var i=0;i<questions.length;i++)...[
        Card(color:panel,child:Padding(padding:const EdgeInsets.all(14),child:material_widgets_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Question ${i+1}',style:const TextStyle(color:gold,fontSize:11,fontWeight:FontWeight.w800)),
          const SizedBox(height:7),Text((questions[i]['question']??'').toString(),style:const TextStyle(fontWeight:FontWeight.w700,height:1.4)),
          const SizedBox(height:8),
          for(var j=0;j<(questions[i]['options'] as List? ?? []).length;j++)
            RadioListTile<int>(dense:true,contentPadding:EdgeInsets.zero,activeColor:emerald,
              value:j,groupValue:answers[questions[i]['id'].toString()],
              title:Text((questions[i]['options'] as List)[j].toString()),
              onChanged:result!=null||submitting?null:(v)=>setState(()=>answers[questions[i]['id'].toString()]=v!)),
        ]))),
      ],
      if(result==null)FilledButton(onPressed:submitting?null:()=>submit(data),
        style:FilledButton.styleFrom(backgroundColor:emerald,minimumSize:const Size.fromHeight(48)),
        child:Text(submitting?'Submitting…':'Submit assessment'))
      else OutlinedButton.icon(onPressed:()=>material_widgets_ui.Navigator.pop(context),icon:const Icon(Icons.arrow_back),label:const Text('Back to course')),
      const SizedBox(height:12),
      const Text('Assessment results are recorded by CreatorVerse. Completing a quiz does not automatically issue a certificate; certificate approval remains an administrator decision.',style:TextStyle(color:muted,fontSize:12,height:1.5)),
    ]);
  }));
}

class CourseCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  const CourseCheckoutScreen({super.key, required this.course});
  @override
  State<CourseCheckoutScreen> createState() => _CourseCheckoutScreenState();
}

class _CourseCheckoutScreenState extends State<CourseCheckoutScreen> {
  final db = Supabase.instance.client;
  final transferReference = TextEditingController();
  XFile? proofImage;
  late Future<Map<String, dynamic>> checkout;
  bool creating = false;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    checkout = loadCheckout();
  }

  @override
  void dispose() {
    transferReference.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> loadCheckout() async {
    final user = db.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to continue with course payment.');
    }
    final settings = await db.from('payment_settings').select(
      'currency,payment_window_minutes,bank_transfer_enabled,ussd_enabled,bank_name,account_name,account_number,ussd_instructions'
    ).eq('id', true).maybeSingle();
    final rows = await db.from('payment_orders')
      .select('id,method,status,reference,expires_at,transfer_reference,admin_note,created_at,amount_ngn,currency,confirmed_at,receipt_number,receipt_issued_at,receipt_course_title,receipt_payer_name')
      .eq('user_id', user.id).eq('course_id', widget.course['id'])
      .inFilter('status', ['pending','proof_submitted','confirmed'])
      .order('created_at', ascending: false).limit(1);
    final currentOrder = rows.isEmpty ? null : rows.first;
    if (currentOrder != null) {
      transferReference.text = (currentOrder['transfer_reference'] ?? '').toString();
    }
    return {'settings': settings ?? <String, dynamic>{}, 'order': currentOrder};
  }

  Future<void> startPayment(String method, Map<String, dynamic> settings) async {
    final user = db.auth.currentUser;
    if (user == null || creating) return;
    final price = (widget.course['price_ngn'] as num?)?.toInt() ?? 0;
    if (price <= 0) return;
    setState(() => creating = true);
    try {
      final window = (settings['payment_window_minutes'] as num?)?.toInt() ?? 30;
      final now = DateTime.now();
      await db.from('payment_orders').insert({
        'user_id': user.id,
        'course_id': widget.course['id'],
        'amount_ngn': price,
        'currency': (settings['currency'] ?? 'NGN').toString(),
        'method': method,
        'status': 'pending',
        'reference': 'CV-MOB-${now.millisecondsSinceEpoch}-${user.id.substring(0, 8).toUpperCase()}',
        'expires_at': now.add(Duration(minutes: window)).toIso8601String(),
      });
      if (!mounted) return;
      setState(() => checkout = loadCheckout());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment request created. Follow the instructions below.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start payment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => creating = false);
      }
    }
  }

  Future<void> choosePaymentProof() async {
    final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:82);
    if(picked!=null&&mounted)setState(()=>proofImage=picked);
  }

  Future<void> submitReference(Map<String, dynamic> order) async {
    final reference = transferReference.text.trim();
    if (reference.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the transaction reference from your bank or USSD receipt.')));
      return;
    }
    setState(() => submitting = true);
    try {
      final userId=db.auth.currentUser!.id;
      String? proofPath;
      final image=proofImage;
      if(image!=null){
        final mime=image.mimeType??'image/jpeg';
        final ext=mime=='image/png'?'png':mime=='image/webp'?'webp':'jpg';
        proofPath='$userId/${order['id']}/${DateTime.now().microsecondsSinceEpoch}.$ext';
        await db.storage.from('payment-proofs').uploadBinary(proofPath,await image.readAsBytes(),
          fileOptions:FileOptions(contentType:mime,upsert:false));
      }
      await db.from('payment_orders').update({
        'transfer_reference': reference,
        'proof_url': proofPath,
        'status': 'proof_submitted',
      }).eq('id', order['id']).eq('user_id', userId);
      if (!mounted) return;
      setState(() { proofImage=null; checkout=loadCheckout(); });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer reference submitted for administrator verification.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit reference: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = (widget.course['price_ngn'] as num?)?.toInt() ?? 0;
    return Scaffold(appBar: AppBar(title: const Text('Course payment')), body: FutureBuilder<Map<String, dynamic>>(
      future: checkout,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: emerald));
        }
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(
            'Payment options could not be loaded: ${snapshot.error}',
            textAlign: TextAlign.center, style: const TextStyle(color: muted))));
        }
        final data = snapshot.data ?? {};
        final settings = data['settings'] as Map<String, dynamic>? ?? {};
        final order = data['order'] as Map<String, dynamic>?;
        final bankEnabled = settings['bank_transfer_enabled'] == true;
        final ussdEnabled = settings['ussd_enabled'] == true;
        final bankReady = bankEnabled && ['bank_name','account_name','account_number'].every((key)=>(settings[key]??'').toString().trim().isNotEmpty);
        final ussdReady = ussdEnabled && (settings['ussd_instructions']??'').toString().trim().isNotEmpty;
        final orderStatus = (order?['status'] ?? '').toString();
        final expiry = DateTime.tryParse((order?['expires_at'] ?? '').toString());
        final expired = expiry != null && expiry.isBefore(DateTime.now()) && orderStatus != 'confirmed';
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text((widget.course['title'] ?? 'Course').toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Amount due: ₦${price.toString()}', style: const TextStyle(color: gold, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (orderStatus == 'confirmed') ...[
            const Card(color: panel, child: ListTile(leading:Icon(Icons.check_circle,color:emerald),title:Text('Payment confirmed'),subtitle:Text('Your course enrolment has been activated.',style:TextStyle(color:muted)))),
            if(order!=null&&(order['receipt_number']??'').toString().isNotEmpty)
              FilledButton.icon(onPressed:()=>printPaymentReceipt(context,order),icon:const Icon(Icons.receipt_long_outlined),label:const Text('View / print official receipt'),style:FilledButton.styleFrom(backgroundColor:emerald)),
          ],
          if (order != null && orderStatus != 'confirmed') ...[
            Card(color: panel, child: Padding(padding: const EdgeInsets.all(16), child: material_widgets_ui.Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expired ? 'Payment window expired' : 'Payment request · $orderStatus',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Reference: ${order['reference']}', style: const TextStyle(color: muted)),
                if (expiry != null) Text('Deadline: ${expiry.toLocal()}', style: const TextStyle(color: muted, fontSize: 12)),
                if (!expired && orderStatus == 'pending') ...[
                  const SizedBox(height: 12),
                  TextField(controller: transferReference, decoration: const InputDecoration(labelText: 'Bank / USSD transaction reference')),
                  const SizedBox(height: 4),
                  TextButton.icon(onPressed: submitting ? null : choosePaymentProof,icon:const Icon(Icons.attach_file),
                    label:Text(proofImage==null?'Attach payment proof screenshot (optional)':proofImage!.name)),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: submitting ? null : () => submitReference(order),
                    style: FilledButton.styleFrom(backgroundColor: emerald),
                    child: Text(submitting ? 'Submitting…' : 'Submit transfer reference')),
                ],
                if (orderStatus == 'proof_submitted') const Padding(padding: EdgeInsets.only(top: 10),
                  child: Text('Your reference is awaiting administrator verification.', style: TextStyle(color: gold))),
              ]))),
          ],
          if (order == null || expired) ...[
            const SizedBox(height: 12),
            if (!bankEnabled && !ussdEnabled) const Card(color: panel, child: Padding(
              padding: EdgeInsets.all(16), child: Text(
                'Payments are not enabled at the moment. The administrator must configure bank transfer or USSD in CreatorVerse payment settings before checkout can begin.',
                style: TextStyle(color: muted, height: 1.5)))),
            if (bankEnabled && !bankReady) const Card(color:panel,child:Padding(padding:EdgeInsets.all(16),child:Text('Bank transfer is enabled but the bank name, account name or account number is missing. Please contact the administrator.',style:TextStyle(color:muted,height:1.5)))),
            if (ussdEnabled && !ussdReady) const Card(color:panel,child:Padding(padding:EdgeInsets.all(16),child:Text('USSD is enabled but payment instructions are missing. Please contact the administrator.',style:TextStyle(color:muted,height:1.5)))),
            if (bankReady) Card(color: panel, child: Padding(padding: const EdgeInsets.all(16), child: material_widgets_ui.Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bank transfer', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Bank: ${settings['bank_name'] ?? ''}'),
                Text('Account name: ${settings['account_name'] ?? ''}'),
                Text('Account number: ${settings['account_number'] ?? ''}'),
                const SizedBox(height: 10),
                FilledButton(onPressed: creating ? null : () => startPayment('bank_transfer', settings),
                  style: FilledButton.styleFrom(backgroundColor: emerald),
                  child: Text(creating ? 'Creating request…' : 'Create bank transfer request')),
              ]))),
            if (ussdReady) Card(color: panel, child: Padding(padding: const EdgeInsets.all(16), child: material_widgets_ui.Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('USSD payment', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text((settings['ussd_instructions'] ?? '').toString(), style: const TextStyle(color: muted, height: 1.5)),
                const SizedBox(height: 10),
                FilledButton(onPressed: creating ? null : () => startPayment('ussd', settings),
                  style: FilledButton.styleFrom(backgroundColor: emerald),
                  child: Text(creating ? 'Creating request…' : 'Create USSD payment request')),
              ]))),
          ],
          const SizedBox(height: 16),
          const Text('Do not submit a transfer reference until you have completed the payment. Course access is activated only after an administrator verifies receipt.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
        ]);
      },
    ));
  }
}

class AcademicHubScreen extends StatelessWidget {
  const AcademicHubScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Academic Learning', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    const Text('Choose the education level that matches you. Secondary and tertiary learning have separate spaces and resources.', style: TextStyle(color: muted, height: 1.5)),
    const SizedBox(height: 18),
    FeatureTile(icon: Icons.school_outlined, title: 'Secondary School',
      detail: 'Prepare for recognised school-leaving and entrance examinations with organised subjects and study resources.',
      path: '/academic-secondary.html'),
    FeatureTile(icon: Icons.account_balance_outlined, title: 'Tertiary Institutions',
      detail: 'A dedicated academic space for universities and other higher institutions.',
      path: '/academic-tertiary.html'),
  ]);
}

class CampusTab extends StatelessWidget {
  const CampusTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(colors: [Color(0xFF123D35), panel]),
      border: Border.all(color: emerald.withValues(alpha: .3))),
      child: const material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('THE STUDENT EXPERIENCE', style: TextStyle(color: gold, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
        SizedBox(height: 10), Text('Make campus life work better.', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        SizedBox(height: 8), Text('Discover the spaces CreatorVerse is building around student life beyond the classroom.', style: TextStyle(color: Colors.white70, height: 1.5)),
      ])),
    const SizedBox(height: 22), const Text('Explore campus spaces', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
    const SizedBox(height: 12),
    FeatureTile(icon: Icons.home_work_outlined, title: 'Verified Housing', detail: 'Browse approved room and rental listings from verified campus sellers.', path: '/housing'),
    FeatureTile(icon: Icons.storefront_outlined, title: 'Campus Marketplace', detail: 'Discover approved student products and services.', path: '/marketplace.html'),
    FeatureTile(icon: Icons.menu_book_outlined, title: 'Past Questions & Study Hub', detail: 'Explore academic resources and study materials.', path: '/academic.html'),
    FeatureTile(icon: Icons.delivery_dining_outlined, title: 'Campus Services & Delivery', detail: 'Browse approved campus services and delivery providers.', path: '/delivery'),
    const SizedBox(height: 8), const Text('Campus Life is being released in stages. Housing and delivery listings are not live yet; safety dispatch is not part of this release.', style: TextStyle(color: muted, height: 1.5, fontSize: 12)),
  ]);
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}
class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final db = Supabase.instance.client;
  final search = TextEditingController();
  late Future<Map<String, dynamic>> catalogue;
  String categoryId = '';
  RealtimeChannel? _syncChannel;
  Timer? _syncTimer;
  @override
  void initState() {
    super.initState(); catalogue = loadCatalogue();
    _syncChannel=db.channel('cv-marketplace-listings-sync')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'marketplace_listings',
        callback:(_){
          _syncTimer?.cancel();
          _syncTimer=Timer(const Duration(milliseconds:500),(){
            if(mounted)setState(()=>catalogue=loadCatalogue());
          });
        }).subscribe();
  }
  @override
  void dispose() {
    search.dispose();_syncTimer?.cancel();
    final channel=_syncChannel;if(channel!=null)unawaited(channel.unsubscribe());
    super.dispose();
  }

  Future<Map<String, dynamic>> loadCatalogue() async {
    final cats = await db.from('marketplace_categories').select('id,name').eq('active', true).order('position');
    final rows = await db.from('marketplace_listings')
      .select('id,seller_id,category_id,title,description,listing_type,price_ngn,location_label,institution,campus,image_urls,created_at')
      .eq('status', 'published').order('created_at', ascending: false).limit(80);
    return {'categories': List<Map<String, dynamic>>.from(cats), 'listings': List<Map<String, dynamic>>.from(rows)};
  }

  void retry() => setState(() => catalogue = loadCatalogue());

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: catalogue,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: material_widgets_ui.Column(
        mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.storefront_outlined, color: emerald, size: 46),
          const SizedBox(height: 12), const Text('Marketplace is not connected yet', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8), const Text('The Marketplace service could not be reached. Check your connection and try again; your account and listing data have not been changed.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5)),
          const SizedBox(height: 16), OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Check again')),
        ])));
      }
      final categories = snapshot.data?['categories'] as List<Map<String, dynamic>>? ?? [];
      final all = snapshot.data?['listings'] as List<Map<String, dynamic>>? ?? [];
      final term = search.text.trim().toLowerCase();
      final rows = all.where((item) {
        final matchesCategory = categoryId.isEmpty || item['category_id'] == categoryId;
        final haystack = [item['title'], item['description'], item['institution'], item['campus'], item['location_label']]
          .map((v) => (v ?? '').toString().toLowerCase()).join(' ');
        return matchesCategory && (term.isEmpty || haystack.contains(term));
      }).toList();
      return material_widgets_ui.Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 10), child: material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Campus Marketplace', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5), const Text('Discover approved products and services from the CreatorVerse community.', style: TextStyle(color: muted)),
          const SizedBox(height: 12), TextField(controller: search, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search listings or campus')),
          const SizedBox(height: 10),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            OutlinedButton.icon(onPressed: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceSellerScreen())).then((_) => retry()),
              icon: const Icon(Icons.storefront_outlined), label: const Text('Sell')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceSavedScreen())),
              icon: const Icon(Icons.bookmark_border), label: const Text('Saved')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceEnquiriesScreen())),
              icon: const Icon(Icons.chat_bubble_outline), label: const Text('Enquiries')),
          ])),
        ])),
        if (categories.isNotEmpty) SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: const Text('All'), selected: categoryId.isEmpty, onSelected: (_) => setState(() => categoryId = ''))),
          for (final cat in categories) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(
            label: Text((cat['name'] ?? '').toString()), selected: categoryId == cat['id'],
            onSelected: (_) => setState(() => categoryId = cat['id'].toString()))),
        ])),
        Expanded(child: rows.isEmpty ? Center(child: Text(all.isEmpty ? 'No approved listings have been published yet.' : 'No listings match your search.', style: const TextStyle(color: muted)))
          : RefreshIndicator(color: emerald, onRefresh: () async { retry(); }, child: ListView.builder(
            padding: const EdgeInsets.all(14), itemCount: rows.length, itemBuilder: (context, index) {
              final item = rows[index];
              final images = item['image_urls'] is List ? item['image_urls'] as List : const [];
              final photo = images.isNotEmpty ? images.first.toString() : '';
              return Card(color: panel, margin: const EdgeInsets.only(bottom: 12), child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: photo.startsWith('https://') ? ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: Image.network(photo, width: 68, height: 68, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 68, height: 68, child: Icon(Icons.storefront_outlined, color: emerald))))
                  : const SizedBox(width: 68, height: 68, child: Icon(Icons.storefront_outlined, color: emerald, size: 32)),
                title: Text((item['title'] ?? 'Marketplace listing').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${item['description'] ?? ''}\n${[item['campus'], item['institution']].where((v) => v != null && v.toString().isNotEmpty).join(' · ')}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted)),
                trailing: Text(item['price_ngn'] == null ? 'Ask' : (item['price_ngn'] == 0 ? 'FREE' : '₦${item['price_ngn']}'), style: const TextStyle(color: emerald, fontWeight: FontWeight.w800)),
                onTap: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceListingScreen(listing: item))),
              ));
            }))),
      ]);
    });
}

class MarketplaceFilteredScreen extends StatefulWidget {
  final String listingType,title,description;
  const MarketplaceFilteredScreen({super.key,required this.listingType,required this.title,required this.description});
  @override State<MarketplaceFilteredScreen> createState()=>_MarketplaceFilteredScreenState();
}
class _MarketplaceFilteredScreenState extends State<MarketplaceFilteredScreen>{
  final db=Supabase.instance.client;final search=TextEditingController();late Future<List<Map<String,dynamic>>> rows;
  @override void initState(){super.initState();rows=load();}
  @override void dispose(){search.dispose();super.dispose();}
  Future<List<Map<String,dynamic>>> load() async {
    final raw=await db.from('marketplace_listings').select('id,seller_id,category_id,title,description,listing_type,price_ngn,location_label,institution,campus,image_urls,created_at')
      .eq('status','published').eq('listing_type',widget.listingType).order('created_at',ascending:false).limit(80);
    return List<Map<String,dynamic>>.from(raw);
  }
  Future<void> refresh() async {final next=load();setState(()=>rows=next);await next;}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.title),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:rows,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Padding(padding:const EdgeInsets.all(20),child:Text('Could not load listings: ${snap.error}',textAlign:TextAlign.center,style:const TextStyle(color:muted))));
      final all=snap.data??[];final term=search.text.trim().toLowerCase();
      final items=all.where((r)=>'${r['title']??''} ${r['description']??''} ${r['campus']??''} ${r['institution']??''} ${r['location_label']??''}'.toLowerCase().contains(term)).toList();
      return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(16),children:[
        Text(widget.description,style:const TextStyle(color:muted,height:1.5)),
        const SizedBox(height:12),TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search listings or campus')),
        const SizedBox(height:12),
        if(items.isEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:44),child:material_widgets_ui.Column(children:[
          Icon(widget.listingType=='rental'?Icons.home_work_outlined:Icons.delivery_dining_outlined,color:emerald,size:42),
          const SizedBox(height:10),Text(all.isEmpty?'No approved listings have been published yet.':'No listings match your search.',style:const TextStyle(color:muted),textAlign:TextAlign.center),
          const SizedBox(height:8),const Text('Only verified sellers and administrator-approved listings appear here.',style:TextStyle(color:muted,fontSize:11),textAlign:TextAlign.center),
        ])),
        for(final item in items)Card(color:panel,child:ListTile(
          leading:const Icon(Icons.storefront_outlined,color:emerald,size:30),
          title:Text((item['title']??'Listing').toString(),style:const TextStyle(fontWeight:FontWeight.w700)),
          subtitle:Text('${item['campus']??item['institution']??item['location_label']??''}\n${item['description']??''}',maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted)),
          trailing:Text(item['price_ngn']==null?'Ask':(item['price_ngn']==0?'FREE':'₦${item['price_ngn']}'),style:const TextStyle(color:emerald,fontWeight:FontWeight.w800)),
          onTap:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>MarketplaceListingScreen(listing:item))),
        )),
      ]));
    }));
}

class MarketplaceListingScreen extends StatefulWidget {
  final Map<String, dynamic> listing;
  const MarketplaceListingScreen({super.key, required this.listing});
  @override
  State<MarketplaceListingScreen> createState() => _MarketplaceListingScreenState();
}
class _MarketplaceListingScreenState extends State<MarketplaceListingScreen> {
  final db = Supabase.instance.client;
  bool saved = false, loadingSave = true, busy = false;
  Map<String, dynamic>? seller;
  @override
  void initState() { super.initState(); loadDetails(); }
  Future<void> loadDetails() async {
    try {
      final user = db.auth.currentUser;
      if (user != null) {
        final row = await db.from('marketplace_saved_listings').select('listing_id')
          .eq('user_id', user.id).eq('listing_id', widget.listing['id']).maybeSingle();
        if (mounted) setState(() => saved = row != null);
      }
      final profile = await db.from('marketplace_public_sellers').select(
        'id,display_name,seller_type,institution,campus,bio'
      ).eq('id', widget.listing['seller_id']).maybeSingle();
      if (mounted) setState(() => seller = profile);
    } catch (_) {
      // Listing discovery remains available even if optional seller metadata fails.
    } finally { if (mounted) setState(() => loadingSave = false); }
  }
  Future<void> toggleSaved() async {
    final user = db.auth.currentUser;
    if (user == null || busy) return;
    setState(() => busy = true);
    try {
      if (saved) {
        await db.from('marketplace_saved_listings').delete()
          .eq('user_id', user.id).eq('listing_id', widget.listing['id']);
      } else {
        await db.from('marketplace_saved_listings').insert({
          'user_id': user.id, 'listing_id': widget.listing['id'],
        });
      }
      if (mounted) setState(() => saved = !saved);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update saved listings: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> startEnquiry() async {
    final input = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: panel, title: const Text('Contact seller'),
      content: TextField(controller: input, minLines: 3, maxLines: 6, maxLength: 2000,
        decoration: const InputDecoration(hintText: 'Ask a question about this listing...')),
      actions: [
        TextButton(onPressed: () => material_widgets_ui.Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => material_widgets_ui.Navigator.pop(ctx, true), child: const Text('Send enquiry')),
      ],
    ));
    if (!mounted) { input.dispose(); return; }
    final body = input.text.trim(); input.dispose();
    if (ok != true) return;
    if (body.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write at least five characters.')));
      return;
    }
    setState(() => busy = true);
    try {
      final id = await db.rpc('marketplace_start_enquiry', params: {
        'p_listing_id': widget.listing['id'], 'p_message': body,
      });
      if (!mounted) return;
      material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceEnquiryThreadScreen(enquiryId: id.toString())));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send enquiry: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final images = listing['image_urls'] is List ? listing['image_urls'] as List : const [];
    final photo = images.isNotEmpty ? images.first.toString() : '';
    final price = listing['price_ngn'];
    final location = [listing['campus'], listing['institution'], listing['location_label']]
      .where((v) => v != null && v.toString().isNotEmpty).join(' · ');
    return Scaffold(appBar: AppBar(title: const Text('Marketplace listing'), actions: [
      IconButton(onPressed: loadingSave || busy ? null : toggleSaved,
        icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: gold)),
    ]), body: ListView(padding: const EdgeInsets.all(18), children: [
      if (photo.startsWith('https://')) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(photo, height: 220, fit: BoxFit.cover)),
      const SizedBox(height: 14), Text((listing['title'] ?? '').toString(), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), Text(price == null ? 'Price on request' : (price == 0 ? 'Free' : '₦$price'), style: const TextStyle(color: emerald, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12), Text((listing['description'] ?? '').toString(), style: const TextStyle(color: Colors.white70, height: 1.55)),
      const SizedBox(height: 14), ListTile(leading: const Icon(Icons.location_on_outlined, color: emerald), title: Text(location.isEmpty ? 'Campus listing' : location)),
      if (seller != null) Card(color: panel, child: ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFF174B3B), child: Icon(Icons.storefront_outlined, color: gold)),
        title: Text((seller!['display_name'] ?? 'Verified seller').toString()),
        subtitle: Text([seller!['seller_type'], seller!['campus'], seller!['institution']]
          .where((v) => v != null && v.toString().isNotEmpty).join(' · '), style: const TextStyle(color: muted)),
      )),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: busy ? null : startEnquiry,
        style: FilledButton.styleFrom(backgroundColor: emerald, minimumSize: const Size.fromHeight(48)),
        icon: const Icon(Icons.chat_bubble_outline), label: Text(busy ? 'Please wait…' : 'Contact seller')),
      const SizedBox(height: 8),
      const Text('Keep your conversation inside CreatorVerse. Never send passwords, verification codes or sensitive financial information to a seller.',
        style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
    ]));
  }
}

class MarketplaceSellerScreen extends StatefulWidget {
  const MarketplaceSellerScreen({super.key});
  @override
  State<MarketplaceSellerScreen> createState() => _MarketplaceSellerScreenState();
}
class _MarketplaceSellerScreenState extends State<MarketplaceSellerScreen> {
  final db = Supabase.instance.client;
  final name = TextEditingController(), institution = TextEditingController(), campus = TextEditingController(), bio = TextEditingController();
  late Future<Map<String, dynamic>> data;
  bool busy = false;
  @override
  void initState() { super.initState(); data = load(); }
  @override
  void dispose() { name.dispose(); institution.dispose(); campus.dispose(); bio.dispose(); super.dispose(); }
  Future<Map<String, dynamic>> load() async {
    final user = db.auth.currentUser;
    if (user == null) throw StateError('Sign in to manage a seller profile.');
    final seller = await db.from('marketplace_sellers').select(
      'id,user_id,display_name,seller_type,institution,campus,bio,status,created_at'
    ).eq('user_id', user.id).maybeSingle();
    if (seller == null) return {'seller': null, 'listings': <Map<String,dynamic>>[]};
    final rows = await db.from('marketplace_listings').select(
      'id,title,description,status,price_ngn,created_at'
    ).eq('seller_id', seller['id']).order('created_at', ascending: false).limit(50);
    return {'seller': seller, 'listings': List<Map<String,dynamic>>.from(rows)};
  }
  Future<void> refresh() async { final next = load(); setState(() => data = next); await next; }
  Future<void> apply() async {
    if (name.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a seller or business name.'))); return;
    }
    setState(() => busy = true);
    try {
      await db.from('marketplace_sellers').insert({
        'user_id': db.auth.currentUser!.id,
        'display_name': name.text.trim(),
        'seller_type': 'student',
        'institution': institution.text.trim().isEmpty ? null : institution.text.trim(),
        'campus': campus.text.trim().isEmpty ? null : campus.text.trim(),
        'bio': bio.text.trim().isEmpty ? null : bio.text.trim(),
      });
      await refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seller application submitted. An administrator must verify your profile before listings can be submitted.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit seller application: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> createListing(Map<String,dynamic> seller) async {
    final cats = await db.from('marketplace_categories').select('id,name').eq('active', true).order('position');
    if (cats.isEmpty || !mounted) return;
    final title = TextEditingController(), description = TextEditingController(), price = TextEditingController(),
      campusField = TextEditingController(text: (seller['campus'] ?? '').toString()),
      institutionField = TextEditingController(text: (seller['institution'] ?? '').toString()),
      location = TextEditingController();
    String category = cats.first['id'].toString(), type = 'product';
    XFile? selectedImage;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      backgroundColor: panel, title: const Text('Create a listing'),
      content: SizedBox(width: 440, child: SingleChildScrollView(child: material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 100, decoration: const InputDecoration(labelText: 'Listing title')),
        const SizedBox(height: 8), DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category'),
          items: [for (final cat in cats) DropdownMenuItem(value: cat['id'].toString(), child: Text(cat['name'].toString()))],
          onChanged: (v) => setDialog(() => category = v ?? category)),
        const SizedBox(height: 8), DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Listing type'),
          items: const [DropdownMenuItem(value: 'product',child:Text('Product')),DropdownMenuItem(value:'service',child:Text('Service')),DropdownMenuItem(value:'rental',child:Text('Rental')),DropdownMenuItem(value:'free',child:Text('Free item'))],
          onChanged: (v) => setDialog(() => type = v ?? type)),
        const SizedBox(height: 8), TextField(controller: description, minLines: 3, maxLines: 5, maxLength: 3000,
          decoration: const InputDecoration(labelText: 'Description (at least 10 characters)')),
        const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: TextButton.icon(
          onPressed: () async { final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600); if (picked != null) setDialog(() => selectedImage = picked); },
          icon: const Icon(Icons.add_photo_alternate_outlined), label: Text(selectedImage == null ? 'Add listing photo' : 'Photo: ${selectedImage!.name}'))),
        const SizedBox(height: 8), TextField(controller: price, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price in naira (leave blank if negotiable / on request)')),
        const SizedBox(height: 8), TextField(controller: institutionField, decoration: const InputDecoration(labelText: 'Institution')),
        const SizedBox(height: 8), TextField(controller: campusField, decoration: const InputDecoration(labelText: 'Campus')),
        const SizedBox(height: 8), TextField(controller: location, decoration: const InputDecoration(labelText: 'Location / pickup point')),
      ]))),
      actions: [TextButton(onPressed: () => material_widgets_ui.Navigator.pop(ctx,false), child: const Text('Cancel')),
        FilledButton(onPressed: () => material_widgets_ui.Navigator.pop(ctx,true), child: const Text('Submit for review'))],
    )));
    final titleText = title.text.trim(), descText = description.text.trim(), priceText = price.text.trim();
    final institutionText = institutionField.text.trim(), campusText = campusField.text.trim(), locationText = location.text.trim();
    title.dispose(); description.dispose(); price.dispose(); campusField.dispose(); institutionField.dispose(); location.dispose();
    if (ok != true) return;
    if (titleText.length < 4 || descText.length < 10 || (priceText.isNotEmpty && int.tryParse(priceText) == null)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check the title, description and price fields.')));
      return;
    }
    setState(() => busy = true);
    try {
      final inserted = await db.from('marketplace_listings').insert({
        'seller_id': seller['id'], 'category_id': category, 'title': titleText, 'description': descText,
        'listing_type': type, 'price_ngn': type == 'free' ? 0 : (priceText.isEmpty ? null : int.parse(priceText)),
        'institution': institutionText.isEmpty ? null : institutionText,
        'campus': campusText.isEmpty ? null : campusText,
        'location_label': locationText.isEmpty ? null : locationText,
        'status': 'draft',
      }).select('id').single();
      if (selectedImage != null) {
        final extension = selectedImage!.name.split('.').last.toLowerCase();
        final safeExtension = ['jpg','jpeg','png','webp','avif'].contains(extension) ? extension : 'jpg';
        final contentType = safeExtension == 'png' ? 'image/png' : safeExtension == 'webp' ? 'image/webp' : safeExtension == 'avif' ? 'image/avif' : 'image/jpeg';
        final objectPath = '${db.auth.currentUser!.id}/${inserted['id']}/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
        await db.storage.from('marketplace-listing-images').uploadBinary(objectPath, await selectedImage!.readAsBytes(),
          fileOptions: FileOptions(contentType: contentType, upsert: false));
        final publicUrl = db.storage.from('marketplace-listing-images').getPublicUrl(objectPath);
        await db.from('marketplace_listings').update({'image_urls': [publicUrl]}).eq('id', inserted['id']);
      }
      await db.rpc('marketplace_submit_listing', params: {'p_listing_id': inserted['id']});
      await refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing submitted. It will appear in Marketplace after administrator approval.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit listing: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Seller workspace'), actions: [
    IconButton(onPressed: busy ? null : refresh, icon: const Icon(Icons.refresh)),
  ]), body: FutureBuilder<Map<String,dynamic>>(future: data, builder: (context,snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child:CircularProgressIndicator(color:emerald));
    if (snapshot.hasError) return Center(child:Padding(padding:const EdgeInsets.all(22),child:Text('Seller workspace unavailable: ${snapshot.error}',textAlign:TextAlign.center,style:const TextStyle(color:muted))));
    final seller = snapshot.data?['seller'] as Map<String,dynamic>?;
    final listings = snapshot.data?['listings'] as List<Map<String,dynamic>>? ?? [];
    if (seller == null) {
      return ListView(padding:const EdgeInsets.all(20),children:[
        const Icon(Icons.storefront_outlined,color:emerald,size:46),const SizedBox(height:12),
        const Text('Become a CreatorVerse seller',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
        const SizedBox(height:8),const Text('Apply to sell products or offer services to the community. An administrator verifies every seller before listings can be submitted.',style:TextStyle(color:muted,height:1.5)),
        const SizedBox(height:18),TextField(controller:name,decoration:const InputDecoration(labelText:'Seller / business display name')),
        const SizedBox(height:10),TextField(controller:institution,decoration:const InputDecoration(labelText:'Institution')),
        const SizedBox(height:10),TextField(controller:campus,decoration:const InputDecoration(labelText:'Campus')),
        const SizedBox(height:10),TextField(controller:bio,maxLines:3,maxLength:500,decoration:const InputDecoration(labelText:'What do you sell or provide?')),
        const SizedBox(height:16),FilledButton(onPressed:busy?null:apply,style:FilledButton.styleFrom(backgroundColor:emerald),child:Text(busy?'Submitting…':'Submit seller application')),
      ]);
    }
    final status = (seller['status'] ?? 'pending').toString();
    return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(18),children:[
      const Text('Your seller profile',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
      const SizedBox(height:10),Card(color:panel,child:ListTile(
        leading:Icon(status=='verified'?Icons.verified:Icons.storefront_outlined,color:status=='verified'?emerald:gold),
        title:Text((seller['display_name']??'Seller').toString()),
        subtitle:Text('Status: ${status.toUpperCase()}\n${status=='verified'?'Your seller profile is approved.':'Your profile is reviewed by the Marketplace team.'}',style:const TextStyle(color:muted,height:1.5)),
      )),
      if(status=='verified') ...[
        const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:()=>createListing(seller),style:FilledButton.styleFrom(backgroundColor:emerald),
          icon:const Icon(Icons.add),label:const Text('Create a listing')),
      ] else const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text('You can create listings after your seller profile is verified.')),
      const SizedBox(height:18),const Text('Your listings',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
      if(listings.isEmpty) const Padding(padding:EdgeInsets.all(12),child:Text('You have not submitted any listings yet.',style:TextStyle(color:muted))),
      for(final listing in listings) Card(color:panel,child:ListTile(
        title:Text((listing['title']??'Untitled listing').toString()),
        subtitle:Text((listing['status']??'').toString(),style:const TextStyle(color:muted)),
        trailing:Text(listing['price_ngn']==null?'Ask':'₦${listing['price_ngn']}',style:const TextStyle(color:gold,fontWeight:FontWeight.w700)),
      )),
    ]));
  }));
}

class MarketplaceSavedScreen extends StatefulWidget {
  const MarketplaceSavedScreen({super.key});
  @override
  State<MarketplaceSavedScreen> createState() => _MarketplaceSavedScreenState();
}
class _MarketplaceSavedScreenState extends State<MarketplaceSavedScreen> {
  final db=Supabase.instance.client;
  late Future<List<Map<String,dynamic>>> rows;
  @override void initState(){super.initState();rows=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in to view saved listings.');
    final saved=await db.from('marketplace_saved_listings').select('listing_id,created_at').eq('user_id',user.id).order('created_at',ascending:false);
    if(saved.isEmpty)return [];
    final ids=saved.map((r)=>r['listing_id']).toList();
    final listings=await db.from('marketplace_listings').select('id,seller_id,title,description,price_ngn,campus,institution,location_label,image_urls').inFilter('id',ids).eq('status','published');
    return List<Map<String,dynamic>>.from(listings);
  }
  Future<void> refresh() async {final next=load();setState(()=>rows=next);await next;}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Saved listings')),body:FutureBuilder<List<Map<String,dynamic>>>(future:rows,builder:(context,snap){
    if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
    if(snap.hasError)return Center(child:Text('Could not load saved listings: ${snap.error}',style:const TextStyle(color:muted)));
    final items=snap.data??[];
    if(items.isEmpty)return const Center(child:Text('You have not saved any listings yet.',style:TextStyle(color:muted)));
    return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(children:[for(final item in items) ListTile(
      title:Text((item['title']??'Listing').toString()),subtitle:Text((item['campus']??item['institution']??'Marketplace').toString(),style:const TextStyle(color:muted)),
      trailing:Text(item['price_ngn']==null?'Ask':'₦${item['price_ngn']}',style:const TextStyle(color:emerald)),
      onTap:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>MarketplaceListingScreen(listing:item))),
    )]));
  }));
}

class MarketplaceEnquiriesScreen extends StatefulWidget {
  const MarketplaceEnquiriesScreen({super.key});
  @override State<MarketplaceEnquiriesScreen> createState()=>_MarketplaceEnquiriesScreenState();
}
class _MarketplaceEnquiriesScreenState extends State<MarketplaceEnquiriesScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> rows;
  @override void initState(){super.initState();rows=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in to view enquiries.');
    final sellers=await db.from('marketplace_sellers').select('id').eq('user_id',user.id);
    final ids=List<Map<String,dynamic>>.from(sellers).map((r)=>r['id']).toList();
    final buyerRows=await db.from('marketplace_enquiries').select('id,listing_id,buyer_id,seller_id,status,last_message_at,marketplace_listings(title)')
      .eq('buyer_id',user.id).order('last_message_at',ascending:false);
    final sellerRows=ids.isEmpty ? <Map<String,dynamic>>[] : List<Map<String,dynamic>>.from(await db.from('marketplace_enquiries')
      .select('id,listing_id,buyer_id,seller_id,status,last_message_at,marketplace_listings(title)')
      .inFilter('seller_id',ids).order('last_message_at',ascending:false));
    final combined=<String,Map<String,dynamic>>{};
    for(final row in [...List<Map<String,dynamic>>.from(buyerRows),...sellerRows]){combined[row['id'].toString()]=row;}
    final result=combined.values.toList()..sort((a,b)=>b['last_message_at'].toString().compareTo(a['last_message_at'].toString()));
    return result;
  }
  Future<void> refresh() async {final next=load();setState(()=>rows=next);await next;}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Marketplace enquiries')),body:FutureBuilder<List<Map<String,dynamic>>>(future:rows,builder:(context,snap){
    if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
    if(snap.hasError)return Center(child:Padding(padding:const EdgeInsets.all(20),child:Text('Could not load enquiries: ${snap.error}',textAlign:TextAlign.center,style:const TextStyle(color:muted))));
    final items=snap.data??[];
    if(items.isEmpty)return const Center(child:Text('No Marketplace enquiries yet.',style:TextStyle(color:muted)));
    return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(children:[for(final item in items)
      ListTile(leading:const Icon(Icons.chat_bubble_outline,color:emerald),
        title:Text((item['marketplace_listings'] is Map?item['marketplace_listings']['title']:'Marketplace enquiry').toString()),
        subtitle:Text('${item['status']} · ${item['last_message_at']}',style:const TextStyle(color:muted,fontSize:12)),
        onTap:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>MarketplaceEnquiryThreadScreen(enquiryId:item['id'].toString()))).then((_)=>refresh()),
      )]));
  }));
}

class MarketplaceEnquiryThreadScreen extends StatefulWidget {
  final String enquiryId;
  const MarketplaceEnquiryThreadScreen({super.key,required this.enquiryId});
  @override State<MarketplaceEnquiryThreadScreen> createState()=>_MarketplaceEnquiryThreadScreenState();
}
class _MarketplaceEnquiryThreadScreenState extends State<MarketplaceEnquiryThreadScreen>{
  final db=Supabase.instance.client;final input=TextEditingController();late Future<Map<String,dynamic>> thread;bool sending=false;
  @override void initState(){super.initState();thread=load();}
  @override void dispose(){input.dispose();super.dispose();}
  Future<Map<String,dynamic>> load() async {
    final head=await db.from('marketplace_enquiries').select('id,status,buyer_id,seller_id,listing_id,marketplace_listings(title),marketplace_sellers(display_name,user_id)')
      .eq('id',widget.enquiryId).single();
    await db.rpc('marketplace_mark_enquiry_read',params:{'p_enquiry_id':widget.enquiryId});
    final messages=await db.from('marketplace_enquiry_messages').select('id,sender_id,body,created_at,read_at')
      .eq('enquiry_id',widget.enquiryId).order('created_at');
    return {'head':head,'messages':List<Map<String,dynamic>>.from(messages)};
  }
  Future<void> refresh() async {final next=load();setState(()=>thread=next);await next;}
  Future<void> send() async {
    final body=input.text.trim();if(body.isEmpty||sending)return;
    setState(()=>sending=true);
    try{await db.rpc('marketplace_send_enquiry_message',params:{'p_enquiry_id':widget.enquiryId,'p_message':body});input.clear();await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Message not sent: $e')));}
    finally{if(mounted)setState(()=>sending=false);}
  }
  Future<void> closeThread() async {
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Close this enquiry?'),
      content:const Text('Both participants will no longer be able to send messages in this thread.'),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Keep open')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Close enquiry'))]));
    if(ok!=true)return;
    try{await db.rpc('marketplace_close_enquiry',params:{'p_enquiry_id':widget.enquiryId});await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not close enquiry: $e')));}
  }
  @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(future:thread,builder:(context,snap){
    if(snap.connectionState==ConnectionState.waiting)return Scaffold(appBar:AppBar(title:const Text('Enquiry')),body:const Center(child:CircularProgressIndicator(color:emerald)));
    if(snap.hasError)return Scaffold(appBar:AppBar(title:const Text('Enquiry')),body:Center(child:Text('Enquiry unavailable: ${snap.error}',style:const TextStyle(color:muted))));
    final data=snap.data??{};final head=data['head'] as Map<String,dynamic>;final messages=data['messages'] as List<Map<String,dynamic>>;
    final closed=head['status']=='closed';
    return Scaffold(appBar:AppBar(title:Text((head['marketplace_listings'] is Map?head['marketplace_listings']['title']:'Marketplace enquiry').toString()),
      actions:[if(!closed)IconButton(onPressed:closeThread,icon:const Icon(Icons.lock_outline))]),
      body:material_widgets_ui.Column(children:[
        Expanded(child:messages.isEmpty?const Center(child:Text('Start the conversation.',style:TextStyle(color:muted))):ListView(padding:const EdgeInsets.all(14),children:[
          for(final m in messages) Align(alignment:m['sender_id']==db.auth.currentUser?.id?Alignment.centerRight:Alignment.centerLeft,
            child:Container(constraints:const BoxConstraints(maxWidth:310),margin:const EdgeInsets.symmetric(vertical:4),padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:m['sender_id']==db.auth.currentUser?.id?const Color(0xFF155E48):panel,borderRadius:BorderRadius.circular(14)),
              child:Text((m['body']??'').toString(),style:const TextStyle(height:1.4)))),
        ])),
        if(closed)const Padding(padding:EdgeInsets.all(16),child:Text('This enquiry is closed.',style:TextStyle(color:muted)))
        else SafeArea(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
          Expanded(child:TextField(controller:input,minLines:1,maxLines:4,decoration:const InputDecoration(hintText:'Write a message...'))),
          IconButton(onPressed:sending?null:send,icon:sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send,color:emerald)),
        ]))),
      ]));
  });
}

class MarketplaceAdminScreen extends StatefulWidget {
  const MarketplaceAdminScreen({super.key});
  @override State<MarketplaceAdminScreen> createState()=>_MarketplaceAdminScreenState();
}
class _MarketplaceAdminScreenState extends State<MarketplaceAdminScreen>{
  final db=Supabase.instance.client;
  late Future<Map<String,dynamic>> data;
  bool busy=false;
  @override void initState(){super.initState();data=load();}
  Future<Map<String,dynamic>> load() async {
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in first.');
    final p=await db.from('profiles').select('role').eq('id',user.id).single();
    if(!['admin','super_admin'].contains(p['role']))throw StateError('Administrator access is required.');
    final sellers=await db.from('marketplace_sellers').select('id,user_id,display_name,seller_type,institution,campus,bio,status,created_at')
      .eq('status','pending').order('created_at');
    final listings=await db.from('marketplace_listings').select('id,title,description,price_ngn,listing_type,created_at,seller_id,marketplace_sellers(display_name,institution,campus),marketplace_categories(name)')
      .eq('status','pending_review').order('created_at');
    final cats=await db.from('marketplace_categories').select('id,name,active,position').order('position');
    return {'sellers':List<Map<String,dynamic>>.from(sellers),'listings':List<Map<String,dynamic>>.from(listings),'categories':List<Map<String,dynamic>>.from(cats)};
  }
  Future<void> refresh() async {final next=load();setState(()=>data=next);await next;}
  Future<String?> noteDialog(String title,String hint) async {
    final controller=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:Text(title),
      content:TextField(controller:controller,maxLines:3,decoration:InputDecoration(hintText:hint)),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Continue'))]));
    final value=controller.text.trim();controller.dispose();return ok==true?value:null;
  }
  Future<void> reviewSeller(Map<String,dynamic> seller,String status) async {
    final note=await noteDialog(status=='verified'?'Verify seller':'Reject seller','Optional review note');
    if(note==null)return;
    setState(()=>busy=true);
    try{
      await db.from('marketplace_sellers').update({'status':status,'review_note':note.isEmpty?null:note}).eq('id',seller['id']);
      await refresh();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(status=='verified'?'Seller verified.':'Seller application rejected.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not review seller: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> reviewListing(Map<String,dynamic> listing,String status) async {
    final note=await noteDialog(status=='published'?'Approve listing':'Reject listing','Optional moderation note');
    if(note==null)return;
    setState(()=>busy=true);
    try{
      await db.from('marketplace_listings').update({
        'status':status,'moderation_note':note.isEmpty?null:note,
        if(status=='rejected')'reviewed_by':db.auth.currentUser!.id,
        if(status=='rejected')'reviewed_at':DateTime.now().toUtc().toIso8601String(),
      }).eq('id',listing['id']);
      await refresh();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(status=='published'?'Listing published in Marketplace.':'Listing rejected.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not review listing: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> toggleCategory(Map<String,dynamic> cat) async {
    setState(()=>busy=true);
    try{await db.from('marketplace_categories').update({'active':!(cat['active']==true)}).eq('id',cat['id']);await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update category: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Marketplace moderation'),actions:[IconButton(onPressed:busy?null:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<Map<String,dynamic>>(future:data,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Marketplace moderation unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final d=snap.data??{};final sellers=d['sellers'] as List<Map<String,dynamic>>? ?? [];final listings=d['listings'] as List<Map<String,dynamic>>? ?? [];final cats=d['categories'] as List<Map<String,dynamic>>? ?? [];
      return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(16),children:[
        const Text('Seller applications',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
        if(sellers.isEmpty)const Padding(padding:EdgeInsets.all(10),child:Text('No seller applications awaiting review.',style:TextStyle(color:muted))),
        for(final s in sellers)Card(color:panel,child:Padding(padding:const EdgeInsets.all(12),child:material_widgets_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text((s['display_name']??'Seller').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
          Text('${s['seller_type']} · ${s['campus']??''} · ${s['institution']??''}',style:const TextStyle(color:muted,fontSize:12)),
          if((s['bio']??'').toString().isNotEmpty)Text(s['bio'].toString(),style:const TextStyle(height:1.4)),
          Row(children:[Expanded(child:OutlinedButton(onPressed:busy?null:()=>reviewSeller(s,'rejected'),child:const Text('Reject'))),
            const SizedBox(width:8),Expanded(child:FilledButton(onPressed:busy?null:()=>reviewSeller(s,'verified'),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('Verify')))]),
        ]))),
        const SizedBox(height:20),const Text('Listings awaiting approval',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
        if(listings.isEmpty)const Padding(padding:EdgeInsets.all(10),child:Text('No listings awaiting review.',style:TextStyle(color:muted))),
        for(final l in listings)Card(color:panel,child:Padding(padding:const EdgeInsets.all(12),child:material_widgets_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text((l['title']??'Listing').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
          Text('${l['marketplace_categories'] is Map?l['marketplace_categories']['name']:'Category'} · ${l['marketplace_sellers'] is Map?l['marketplace_sellers']['display_name']:'Seller'} · ₦${l['price_ngn']??'Ask'}',style:const TextStyle(color:muted,fontSize:12)),
          const SizedBox(height:6),Text((l['description']??'').toString(),maxLines:4,overflow:TextOverflow.ellipsis,style:const TextStyle(height:1.4)),
          Row(children:[Expanded(child:OutlinedButton(onPressed:busy?null:()=>reviewListing(l,'rejected'),child:const Text('Reject'))),
            const SizedBox(width:8),Expanded(child:FilledButton(onPressed:busy?null:()=>reviewListing(l,'published'),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('Approve & publish')))]),
        ]))),
        const SizedBox(height:20),const Text('Marketplace categories',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
        for(final cat in cats)SwitchListTile(value:cat['active']==true,title:Text(cat['name'].toString()),activeColor:emerald,onChanged:busy?null:(_)=>toggleCategory(cat)),
      ]));
    }));
}

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});
  @override
  State<CommunityTab> createState() => _CommunityTabState();
}
class _CommunityTabState extends State<CommunityTab> {
  late Future<List<Map<String, dynamic>>> feed;
  late Future<List<Map<String, dynamic>>> stories;
  final db = Supabase.instance.client;
  String _feedMode = 'for_you';
  RealtimeChannel? _syncChannel;
  Timer? _syncTimer;
  String _feedCacheKey() => 'cv_community_feed_${db.auth.currentUser?.id ?? 'guest'}_$_feedMode';

  Future<List<Map<String,dynamic>>> _initialFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_feedCacheKey());
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final cached = decoded.whereType<Map>().map((row) => Map<String,dynamic>.from(row)).toList();
          if (cached.isNotEmpty) {
            unawaited(_refreshFeedInBackground());
            return cached;
          }
        }
      }
    } catch (_) {}
    return loadFeed();
  }

  Future<void> _refreshFeedInBackground() async {
    try {
      final fresh = await loadFeed();
      if (mounted) setState(() => feed = Future.value(fresh));
    } catch (_) {
      // Keep the last cached feed visible while offline or on a slow connection.
    }
  }

  @override
  void initState() {
    super.initState(); feed = _initialFeed(); stories = loadStories();
    _syncChannel=db.channel('cv-community-feed-sync')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'community_posts',
        callback:(_)=>_scheduleFeedSync())
      .subscribe();
  }
  void _scheduleFeedSync(){
    _syncTimer?.cancel();
    _syncTimer=Timer(const Duration(milliseconds:600),(){
      if(mounted){
        final next=loadFeed();
        setState(()=>feed=next);
      }
    });
  }
  @override
  void dispose(){
    _syncTimer?.cancel();
    final channel=_syncChannel;if(channel!=null)unawaited(channel.unsubscribe());
    super.dispose();
  }
  Future<List<Map<String, dynamic>>> loadFeed() async {
    final columns = 'id,user_id,title,description,image_url,media_type,destination_url,category,tags,created_at';
    late final List<Map<String, dynamic>> posts;
    if (_feedMode == 'following') {
      final me = db.auth.currentUser?.id;
      if (me == null) return [];
      final followsRaw = await db.from('community_follows')
        .select('following_id').eq('follower_id', me);
      final visibleAuthors = <String>{
        me,
        ...List<Map<String, dynamic>>.from(followsRaw)
          .map((row) => row['following_id'].toString()),
      }.toList();
      final raw = await db.from('community_posts').select(columns)
        .eq('status', 'published').inFilter('user_id', visibleAuthors)
        .order('created_at', ascending: false).limit(40);
      posts = List<Map<String, dynamic>>.from(raw);
    } else {
      final raw = await db.from('community_posts').select(columns)
        .eq('status', 'published').order('created_at', ascending: false).limit(40);
      posts = List<Map<String, dynamic>>.from(raw);
    }
    if (posts.isEmpty) return posts;
    final ids = posts.map((p) => p['id'].toString()).toList();
    final users = posts.map((p) => p['user_id'].toString()).toSet().toList();
    final me = db.auth.currentUser?.id;
    // Fetch post metadata concurrently. Serial network round-trips made the feed
    // feel as if it was loading each part one after another.
    final results = await Future.wait<dynamic>([
      db.from('public_profiles').select('id,full_name,username,avatar_url,verified_badge').inFilter('id', users),
      db.from('community_likes').select('post_id,user_id').inFilter('post_id', ids).limit(2500),
      db.from('community_comments').select('post_id').inFilter('post_id', ids).limit(2500),
      me == null
        ? Future.value(<Map<String,dynamic>>[])
        : db.from('community_saves').select('post_id').eq('user_id',me).inFilter('post_id',ids),
    ]);
    final profiles = {for (final p in List<Map<String, dynamic>>.from(results[0])) p['id'].toString(): p};
    final likes = List<Map<String, dynamic>>.from(results[1]);
    final comments = List<Map<String, dynamic>>.from(results[2]);
    final savesRaw = List<Map<String,dynamic>>.from(results[3]);
    final savedIds=savesRaw.map((r)=>r['post_id'].toString()).toSet();
    for (final post in posts) {
      final id = post['id'].toString();
      post['author'] = profiles[post['user_id'].toString()] ?? {};
      final postLikes = likes.where((l) => l['post_id'].toString() == id).toList();
      post['like_count'] = postLikes.length;
      post['liked'] = postLikes.any((l) => l['user_id'] == me);
      post['comment_count'] = comments.where((c) => c['post_id'].toString() == id).length;
      post['saved'] = savedIds.contains(id);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_feedCacheKey(), jsonEncode(posts));
    } catch (_) {}
    return posts;
  }
  Future<List<Map<String,dynamic>>> loadStories() async {
    final now=DateTime.now().toUtc().toIso8601String();
    final raw=await db.from('cv_stories').select('id,user_id,content,media_url,media_type,background,created_at,expires_at')
      .gt('expires_at',now).order('created_at',ascending:false).limit(30);
    final rows=List<Map<String,dynamic>>.from(raw);
    if(rows.isEmpty)return rows;
    final ids=rows.map((r)=>r['user_id'].toString()).toSet().toList();
    final profiles=await db.from('public_profiles').select('id,full_name,username,avatar_url').inFilter('id',ids);
    final byId={for(final p in List<Map<String,dynamic>>.from(profiles))p['id'].toString():p};
    final grouped=<String,List<Map<String,dynamic>>>{};
    for(final row in rows){
      row['author']=byId[row['user_id'].toString()]??{};
      grouped.putIfAbsent(row['user_id'].toString(),()=>[]).add(row);
    }
    final creators=grouped.entries.map((entry){
      final chronological=entry.value.reversed.toList();
      return <String,dynamic>{'user_id':entry.key,'author':chronological.last['author'],'stories':chronological,'latest_at':chronological.last['created_at']};
    }).toList();
    creators.sort((a,b)=>DateTime.parse(b['latest_at'].toString()).compareTo(DateTime.parse(a['latest_at'].toString())));
    return creators;
  }
  Future<void> refresh() async {
    final nextFeed=loadFeed(),nextStories=loadStories();
    setState((){feed=nextFeed;stories=nextStories;});
    await Future.wait([nextFeed,nextStories]);
  }
  Future<void> selectFeedMode(String mode) async {
    if (_feedMode == mode || !mounted) return;
    setState(() => _feedMode = mode);
    final next = _initialFeed();
    setState(() => feed = next);
    await next;
  }
  Future<void> createStory() async {
    final input=TextEditingController();XFile? media;bool video=false;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(backgroundColor:panel,title:const Text('Share a 24-hour story'),
      content:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:input,minLines:3,maxLines:5,maxLength:500,decoration:const InputDecoration(hintText:'Add a message or choose a photo/video')),
        const SizedBox(height:8),Wrap(spacing:8,children:[
          TextButton.icon(onPressed:()async{final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:82,maxWidth:1600);if(picked!=null)setDialog((){media=picked;video=false;});},
            icon:const Icon(Icons.add_photo_alternate_outlined),label:Text(media==null?'Add photo':(!video?'Photo selected':'Change photo'))),
          TextButton.icon(onPressed:()async{final picked=await ImagePicker().pickVideo(source:ImageSource.gallery,maxDuration:const Duration(seconds:60));if(picked!=null)setDialog((){media=picked;video=true;});},
            icon:const Icon(Icons.video_library_outlined),label:Text(video?'Video selected':'Add video')),
        ]),
      ]),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Share story'))])));
    if(!mounted){input.dispose();return;}
    final content=input.text.trim();input.dispose();
    if(ok!=true)return;
    if(content.isEmpty&&media==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Add a message, photo or video to your story.')));return;}
    try{
      final userId=db.auth.currentUser!.id;String? mediaUrl;
      if(media!=null){
        final ext=media!.name.split('.').last.toLowerCase();
        final safeExt=video?(<String>['mp4','mov','webm'].contains(ext)?ext:'mp4'):(<String>['png','webp','gif'].contains(ext)?ext:'jpg');
        final mime=video?(safeExt=='mov'?'video/quicktime':safeExt=='webm'?'video/webm':'video/mp4'):(safeExt=='png'?'image/png':safeExt=='webp'?'image/webp':safeExt=='gif'?'image/gif':'image/jpeg');
        final path='$userId/stories/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
        await db.storage.from('community-media').uploadBinary(path,await media!.readAsBytes(),fileOptions:FileOptions(contentType:mime));
        mediaUrl=db.storage.from('community-media').getPublicUrl(path);
      }
      final now=DateTime.now().toUtc();
      await db.from('cv_stories').insert({'user_id':userId,'content':content,'media_url':mediaUrl,
        'media_type':mediaUrl==null?'text':(video?'video':'image'),'background':'#123D35','expires_at':now.add(const Duration(hours:24)).toIso8601String()});
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not publish story: $e')));}
  }
  Future<void> viewStoryGroup(Map<String,dynamic> creator) async {
    final entries=List<Map<String,dynamic>>.from(creator['stories'] as List? ?? const []);
    if(entries.isEmpty)return;
    final me=db.auth.currentUser?.id;
    Future<void> recordView(Map<String,dynamic> story) async {
      if(me!=null&&story['user_id']!=me){
        try{await db.from('cv_story_views').insert({'story_id':story['id'],'viewer_id':me});}catch(_){}
      }
    }
    var index=0;
    await recordView(entries[index]);
    if(!mounted)return;
    await showModalBottomSheet<void>(context:context,backgroundColor:panel,isScrollControlled:true,
      builder:(sheetContext)=>StatefulBuilder(builder:(sheetContext,setSheetState){
        final story=entries[index];
        final author=Map<String,dynamic>.from(story['author'] as Map? ?? creator['author'] as Map? ?? {});
        final media=(story['media_url']??'').toString();
        return SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:material_widgets_ui.Column(
          mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Expanded(child:Text((author['full_name']??author['username']??'CreatorVerse member').toString(),style:const TextStyle(color:gold,fontWeight:FontWeight.w800))),
              Text('${index+1}/${entries.length}',style:const TextStyle(color:muted,fontSize:12)),
            ]),
            const SizedBox(height:12),
            if(media.startsWith('https://')&&story['media_type']=='image')
              ClipRRect(borderRadius:BorderRadius.circular(14),child:CachedNetworkImage(imageUrl:media,fit:BoxFit.contain,memCacheWidth:1200,placeholder:(_,__)=>const SizedBox(height:220,child:Center(child:CircularProgressIndicator(color:emerald))),errorWidget:(_,__,___)=>const Text('Story media could not be loaded'))),
            if(media.startsWith('https://')&&story['media_type']=='video')
              InlineVideoPlayer(url:media),
            if((story['content']??'').toString().isNotEmpty)
              Padding(padding:const EdgeInsets.only(top:12),child:Text(story['content'].toString(),style:const TextStyle(fontSize:20,height:1.5))),
            const SizedBox(height:18),
            Row(children:[
              Expanded(child:OutlinedButton(onPressed:index==0?null:()=>setSheetState(()=>index--),child:const Text('Previous'))),
              const SizedBox(width:10),
              Expanded(child:FilledButton(onPressed:()async{
                if(index<entries.length-1){
                  final next=index+1;
                  await recordView(entries[next]);
                  if(sheetContext.mounted)setSheetState(()=>index=next);
                }else if(sheetContext.mounted){material_widgets_ui.Navigator.pop(sheetContext);}
              },child:Text(index==entries.length-1?'Done':'Next'))),
            ]),
            const SizedBox(height:8),
            Align(alignment:Alignment.centerRight,child:Text(_timeAgo(story['created_at']?.toString()),style:const TextStyle(color:muted,fontSize:11))),
          ])));
      }));
  }
  Future<void> createPost() async {
    final body = TextEditingController();XFile? media;bool video=false;
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder:(dialogContext,setDialog)=>AlertDialog(
      backgroundColor: panel, title: const Text('Share with the community'),
      content: SizedBox(width: 420, child: material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: body, minLines: 3, maxLines: 6, maxLength: 3000,
          decoration: const InputDecoration(hintText: "What's on your mind?")),
        const SizedBox(height:8),Wrap(spacing:8,children:[
          TextButton.icon(onPressed:()async{final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:82,maxWidth:1600);if(picked!=null)setDialog((){media=picked;video=false;});},
            icon:const Icon(Icons.add_photo_alternate_outlined),label:Text(media==null?'Add photo':(!video?'Photo selected':'Change photo'))),
          TextButton.icon(onPressed:()async{final picked=await ImagePicker().pickVideo(source:ImageSource.gallery,maxDuration:const Duration(seconds:60));if(picked!=null)setDialog((){media=picked;video=true;});},
            icon:const Icon(Icons.video_library_outlined),label:Text(video?'Video selected':'Add video')),
        ]),
      ])),
      actions: [TextButton(onPressed: () => material_widgets_ui.Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => material_widgets_ui.Navigator.pop(dialogContext, true), child: const Text('Publish'))])));
    if (!mounted) { body.dispose(); return; }
    if (ok != true) { body.dispose(); return; }
    final bodyText=body.text.trim();body.dispose();
    if (bodyText.isEmpty&&media==null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write something or add a photo/video.')));
      return;
    }
    try {
      final userId=db.auth.currentUser!.id;String? imageUrl;
      if(media!=null){
        final ext=media!.name.split('.').last.toLowerCase();
        final safeExt=video?(<String>['mp4','mov','webm'].contains(ext)?ext:'mp4'):(<String>['png','webp','gif'].contains(ext)?ext:'jpg');
        final mime=video?(safeExt=='mov'?'video/quicktime':safeExt=='webm'?'video/webm':'video/mp4'):(safeExt=='png'?'image/png':safeExt=='webp'?'image/webp':safeExt=='gif'?'image/gif':'image/jpeg');
        final path='$userId/posts/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
        await db.storage.from('community-media').uploadBinary(path,await media!.readAsBytes(),fileOptions:FileOptions(contentType:mime));
        imageUrl=db.storage.from('community-media').getPublicUrl(path);
      }
      final titleText = bodyText.isEmpty
        ? (video ? 'Shared a video' : 'Shared a photo')
        : (bodyText.length > 80 ? '${bodyText.substring(0, 77)}...' : bodyText);
      await db.from('community_posts').insert({'user_id':userId,'title':titleText,'description':bodyText,
        'image_url':imageUrl,'media_type':imageUrl==null?'none':(video?'video':'image'),'category':'General','tags':<String>[],'status':'published'});
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not publish: $e')));
    }
  }
  Future<void> toggleLike(Map<String, dynamic> post) async {
    final me = db.auth.currentUser!.id, id = post['id'].toString();
    final liked = post['liked'] == true;
    setState(() { post['liked'] = !liked; post['like_count'] = ((post['like_count'] as int?) ?? 0) + (liked ? -1 : 1); });
    try {
      if (liked) { await db.from('community_likes').delete().eq('post_id', id).eq('user_id', me); }
      else { await db.from('community_likes').insert({'post_id': id, 'user_id': me}); }
    } catch (_) { if (mounted) await refresh(); }
  }
  Future<void> toggleSave(Map<String,dynamic> post) async {
    final me=db.auth.currentUser!.id,id=post['id'].toString();
    final saved=post['saved']==true;
    setState(()=>post['saved']=!saved);
    try{
      if(saved){await db.from('community_saves').delete().eq('user_id',me).eq('post_id',id);}
      else{await db.from('community_saves').insert({'user_id':me,'post_id':id});}
    }catch(_){if(mounted)await refresh();}
  }
  Future<void> reportPost(Map<String,dynamic> post) async {
    String reason='spam';final details=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(backgroundColor:panel,
      title:const Text('Report this post'),
      content:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:reason,decoration:const InputDecoration(labelText:'Reason'),
          items:const [DropdownMenuItem(value:'spam',child:Text('Spam or misleading')),DropdownMenuItem(value:'harassment',child:Text('Harassment or bullying')),
            DropdownMenuItem(value:'scam',child:Text('Scam or fraud')),DropdownMenuItem(value:'inappropriate',child:Text('Inappropriate content')),
            DropdownMenuItem(value:'other',child:Text('Other'))],
          onChanged:(v)=>setDialog(()=>reason=v??reason)),
        const SizedBox(height:10),TextField(controller:details,maxLines:3,maxLength:500,decoration:const InputDecoration(labelText:'Additional details (optional)')),
      ]),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Submit report'))])));
    if(!mounted){details.dispose();return;}
    final note=details.text.trim();details.dispose();if(ok!=true)return;
    try{
      await db.from('community_reports').insert({'reporter_id':db.auth.currentUser!.id,'post_id':post['id'],'reason':reason,'details':note.isEmpty?null:note,'status':'open'});
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Report submitted to the moderation team.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not submit report: $e')));}
  }
  Future<void> showComments(Map<String, dynamic> post) async {
    await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: panel,
      builder: (_) => CommentsSheet(post: post));
    if (mounted) await refresh();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: feed, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, color: muted, size: 42), const SizedBox(height: 12),
          const Text('Community is unavailable right now.'), const SizedBox(height: 12),
          OutlinedButton(onPressed: () => setState(() => feed = loadFeed()), child: const Text('Try again'))])));
      }
      final posts = snapshot.data ?? [];
      return RefreshIndicator(color: emerald, onRefresh: refresh, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        const Text('Community', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -.4)),
        const SizedBox(height: 3),
        const Text('Connect, share and learn together.', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          ChoiceChip(label: const Text('For you'), selected: _feedMode == 'for_you',
            onSelected: (_) => selectFeedMode('for_you')),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('Following'), selected: _feedMode == 'following',
            onSelected: (_) => selectFeedMode('following')),
        ]),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String,dynamic>>>(future:stories,builder:(context,storySnap){
          final items=storySnap.data??[];
          return SizedBox(height:104,child:ListView(scrollDirection:Axis.horizontal,children:[
            InkWell(onTap:createStory,child:Container(width:78,margin:const EdgeInsets.only(right:10),child:material_widgets_ui.Column(children:[
              Container(width:62,height:62,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:gold,width:2),color:panel),child:const Icon(Icons.add,color:gold,size:28)),
              const SizedBox(height:6),const Text('Your story',style:TextStyle(fontSize:10,color:muted)),
            ]))),
            for(final story in items)InkWell(onTap:()=>viewStoryGroup(story),child:Container(width:78,margin:const EdgeInsets.only(right:10),child:material_widgets_ui.Column(children:[
              Container(width:62,height:62,padding:const EdgeInsets.all(3),decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:emerald,width:2)),
                child:CircleAvatar(backgroundColor:const Color(0xFF174B3B),child:Text((((story['author'] as Map?)?['full_name']??(story['author'] as Map?)?['username']??'C').toString().isEmpty?'C':((story['author'] as Map?)?['full_name']??(story['author'] as Map?)?['username']??'C').toString()[0].toUpperCase()),style:const TextStyle(color:gold,fontWeight:FontWeight.w800)))),
              const SizedBox(height:6),Text(((story['author'] as Map?)?['full_name']??(story['author'] as Map?)?['username']??'Member').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:muted)),
            ]))),
          ]));
        }),
        const SizedBox(height: 10),
        InkWell(
          onTap: createPost,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .07)),
            ),
            child: material_widgets_ui.Column(
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: emerald.withValues(alpha: .2),
                    child: const Icon(Icons.person_outline, color: emerald, size: 21),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .055),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text("What's on your mind?", style: TextStyle(color: muted, fontSize: 13)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.white.withValues(alpha: .08)),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.photo_library_outlined, color: emerald, size: 18),
                  const SizedBox(width: 7),
                  const Text('Photo / video', style: TextStyle(color: muted, fontSize: 11)),
                  const Spacer(),
                  const Icon(Icons.edit_note_outlined, color: gold, size: 19),
                  const SizedBox(width: 6),
                  const Text('Create a post', style: TextStyle(color: muted, fontSize: 11)),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (posts.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 50), child: material_widgets_ui.Column(children: [
          const Icon(Icons.forum_outlined, color: emerald, size: 44), const SizedBox(height: 12),
          Text(_feedMode == 'following' ? 'Your Following feed is quiet' : 'Your community starts here',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_feedMode == 'following'
            ? 'Follow members to see their updates here, or share your own post.'
            : 'Be the first to share an update.',
            textAlign: TextAlign.center, style: const TextStyle(color: muted))])),
        for (final post in posts) CommunityPostCard(post: post, onLike: () => toggleLike(post), onComments: () => showComments(post), onSave: () => toggleSave(post), onReport: () => reportPost(post)),
      ]));
    });
}
class InlineVideoPlayer extends StatefulWidget {
  final String url;
  const InlineVideoPlayer({super.key, required this.url});
  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}
class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController controller;
  late Future<void> ready;
  @override
  void initState() { super.initState(); _initialize(); }
  void _initialize() {
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    controller.addListener(_refreshControls);
    ready = controller.initialize().then((_) { if (mounted) setState(() {}); });
  }
  void _refreshControls() { if (mounted) setState(() {}); }
  @override
  void didUpdateWidget(covariant InlineVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      controller.removeListener(_refreshControls);
      controller.dispose();
      _initialize();
    }
  }
  @override
  void dispose() { controller.removeListener(_refreshControls); controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: ready,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Padding(padding: EdgeInsets.all(16), child: Text('This video could not be played.', style: TextStyle(color: muted)));
      if (snapshot.connectionState != ConnectionState.done) return const SizedBox(height: 190, child: Center(child: CircularProgressIndicator(color: emerald)));
      final size = controller.value.size;
      return ClipRRect(borderRadius: BorderRadius.circular(10), child: AspectRatio(
        aspectRatio: size.width > 0 && size.height > 0 ? size.width / size.height : 16 / 9,
        child: Stack(alignment: Alignment.center, children: [
          VideoPlayer(controller),
          IconButton.filled(onPressed: () { controller.value.isPlaying ? controller.pause() : controller.play(); },
            iconSize: 34, icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow)),
        ]),
      ));
    },
  );
}
class CommunityMediaViewer extends StatelessWidget {
  final Map<String,dynamic> post;
  final VoidCallback onComments;
  const CommunityMediaViewer({super.key,required this.post,required this.onComments});
  @override Widget build(BuildContext context){
    final url=(post['image_url']??'').toString();
    final video=post['media_type']=='video';
    return Scaffold(backgroundColor:Colors.black,
      appBar:AppBar(backgroundColor:Colors.black,title:Text((post['title']??'Post media').toString(),
        maxLines:1,overflow:TextOverflow.ellipsis),
        actions:[IconButton(tooltip:'Save media',onPressed:()=>_saveRemoteMedia(context,url,
          _mediaMimeFromUrl(url,video:video),'creatorverse-${post['id']??'community-media'}'),
          icon:const Icon(Icons.download_rounded))]),
      body:Column(children:[
        Expanded(
          child: Center(
            child: video
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: InlineVideoPlayer(url: url),
                )
              : InteractiveViewer(
                  minScale: .6,
                  maxScale: 5,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    memCacheWidth: 1600,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: emerald)),
                    errorWidget: (_, __, ___) => const Text('Media could not be loaded', style: TextStyle(color: Colors.white70)),
                  ),
                ),
          ),
        ),
        Container(width:double.infinity,color:const Color(0xFF101719),padding:const EdgeInsets.fromLTRB(16,12,16,18),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((post['title']??'').toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:17)),
            if((post['description']??'').toString().trim().isNotEmpty)Padding(padding:const EdgeInsets.only(top:6),
              child:Text((post['description']??'').toString(),style:const TextStyle(color:Colors.white70,height:1.4))),
            const SizedBox(height:10),
            Row(children:[
              Text('${post['like_count']??0} likes',style:const TextStyle(color:muted)),
              const Spacer(),
              TextButton.icon(onPressed:onComments,icon:const Icon(Icons.mode_comment_outlined),
                label:Text('${post['comment_count']??0} comments')),
            ])
          ]))
      ]));
  }
}

class CommunityPostCard extends StatelessWidget {
  final Map<String, dynamic> post; final VoidCallback onLike, onComments, onSave, onReport;
  const CommunityPostCard({super.key, required this.post, required this.onLike, required this.onComments, required this.onSave, required this.onReport});
  @override
  Widget build(BuildContext context) {
    final author = Map<String, dynamic>.from(post['author'] as Map? ?? {});
    final name = (author['full_name'] ?? author['username'] ?? 'CreatorVerse member').toString();
    final avatar = author['avatar_url']?.toString() ?? '';
    final image = post['image_url']?.toString() ?? '';
    return Container(margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
      child: material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          CircleAvatar(radius: 19, backgroundColor: emerald.withValues(alpha: .18),
            backgroundImage: avatar.startsWith('https://') ? NetworkImage(avatar) : null,
            child: avatar.startsWith('https://') ? null : const Icon(Icons.person, color: emerald, size: 20)),
          const SizedBox(width: 10), Expanded(child: material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
              if (author['verified_badge']?.toString() != null && author['verified_badge'] != 'none') const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified, color: gold, size: 15))]),
            Text((post['category'] ?? 'Community').toString(), style: const TextStyle(color: muted, fontSize: 11))])),
          Text(_timeAgo(post['created_at']?.toString()), style: const TextStyle(color: muted, fontSize: 10)),
          PopupMenuButton<String>(onSelected:(value){if(value=='report')onReport();},itemBuilder:(_)=>const [
            PopupMenuItem(value:'report',child:Row(children:[Icon(Icons.flag_outlined,size:18),SizedBox(width:8),Text('Report post')]))]),

        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text((post['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        Padding(padding: const EdgeInsets.fromLTRB(14, 7, 14, 12), child: Text((post['description'] ?? '').toString(), style: const TextStyle(color: Colors.white70, height: 1.45))),
        if(image.startsWith('https://'))Padding(padding:const EdgeInsets.symmetric(horizontal:8),child:Stack(
          alignment:Alignment.topRight,children:[
            GestureDetector(onTap:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CommunityMediaViewer(
              post:post,onComments:onComments))),
              child: post['media_type'] == 'video'
              ? InlineVideoPlayer(url: image)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: 1000,
                    placeholder: (_, __) => const SizedBox(
                      height: 210,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: emerald)),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
          ),
            IconButton.filled(onPressed:()=>_saveRemoteMedia(context,image,
              _mediaMimeFromUrl(image,video:post['media_type']=='video'),
              'creatorverse-${post['id']??'community-media'}'),
              icon:const Icon(Icons.download_rounded),tooltip:'Save media',
              style:IconButton.styleFrom(backgroundColor:Colors.black87)),
            Positioned(right:8,bottom:8,child:Container(padding:const EdgeInsets.all(7),
              decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(20)),
              child:const Icon(Icons.open_in_full,color:Colors.white,size:16))),
          ])),
        Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 8), child: Row(children: [
          Text('${post['like_count'] ?? 0} likes', style: const TextStyle(color: muted, fontSize: 11)),
          const Spacer(), Text('${post['comment_count'] ?? 0} comments', style: const TextStyle(color: muted, fontSize: 11))])),
        const Divider(height: 1, color: Colors.white10),
        Row(children: [
          Expanded(child: TextButton.icon(onPressed: onLike, icon: Icon(post['liked'] == true ? Icons.favorite : Icons.favorite_border,
            color: post['liked'] == true ? Colors.pinkAccent : muted, size: 18), label: const Text('Like', style: TextStyle(color: muted)))),
          Expanded(child: TextButton.icon(onPressed: onComments, icon: const Icon(Icons.mode_comment_outlined, color: muted, size: 18),
            label: const Text('Comment', style: TextStyle(color: muted)))),
          Expanded(child: TextButton.icon(onPressed: onSave, icon: Icon(post['saved']==true?Icons.bookmark:Icons.bookmark_border,color:post['saved']==true?gold:muted,size:18),
            label:Text(post['saved']==true?'Saved':'Save',style:const TextStyle(color:muted)))),
        ]),
      ]));
  }
}
String _timeAgo(String? raw) {
  final date = DateTime.tryParse(raw ?? '')?.toLocal(); if (date == null) return '';
  final delta = DateTime.now().difference(date);
  if (delta.inMinutes < 1) return 'Just now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inDays < 1) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
}
class CommentsSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  const CommentsSheet({super.key, required this.post});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}
class _CommentsSheetState extends State<CommentsSheet> {
  final db = Supabase.instance.client; final input = TextEditingController();
  late Future<List<Map<String, dynamic>>> comments;
  bool sending = false;
  @override
  void initState() { super.initState(); comments = load(); }
  @override
  void dispose() { input.dispose(); super.dispose(); }
  Future<List<Map<String, dynamic>>> load() async {
    final raw = await db.from('community_comments').select('id,user_id,body,created_at')
      .eq('post_id', widget.post['id']).order('created_at');
    final rows = List<Map<String, dynamic>>.from(raw);
    if (rows.isEmpty) return rows;
    final ids = rows.map((r) => r['user_id'].toString()).toSet().toList();
    final p = await db.from('public_profiles').select('id,full_name,username,avatar_url').inFilter('id', ids);
    final profiles = {for (final x in List<Map<String, dynamic>>.from(p)) x['id'].toString(): x};
    for (final row in rows) { row['author'] = profiles[row['user_id'].toString()] ?? {}; }
    return rows;
  }
  Future<void> send() async {
    if (input.text.trim().isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await db.from('community_comments').insert({'post_id': widget.post['id'], 'user_id': db.auth.currentUser!.id, 'body': input.text.trim()});
      input.clear(); setState(() => comments = load());
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comment failed: $e'))); }
    finally { if (mounted) setState(() => sending = false); }
  }
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(context).viewInsets.bottom + 18),
    child: SizedBox(height: MediaQuery.of(context).size.height * .72, child: material_widgets_ui.Column(children: [
      const Text('Comments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12), Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: comments, builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
        if (snap.hasError) return const Center(child: Text('Could not load comments.', style: TextStyle(color: muted)));
        final rows = snap.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('No comments yet. Start the conversation.', style: TextStyle(color: muted)));
        return ListView(children: [for (final row in rows) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(radius: 15, backgroundColor: Color(0x3320B887), child: Icon(Icons.person, size: 16, color: emerald)),
          const SizedBox(width: 9), Expanded(child: material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(((row['author'] as Map?)?['full_name'] ?? (row['author'] as Map?)?['username'] ?? 'Member').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 3), Text(row['body'].toString(), style: const TextStyle(color: Colors.white70, height: 1.4))]))]))]);
      })),
      const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: input, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'Write a comment...'))),
        const SizedBox(width: 8), IconButton(onPressed: sending ? null : send, icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: emerald))]),
    ]))));
}
class MessageInboxScreen extends StatefulWidget {
  const MessageInboxScreen({super.key});
  @override
  State<MessageInboxScreen> createState() => _MessageInboxScreenState();
}
class _MessageInboxScreenState extends State<MessageInboxScreen> {
  final db = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> inbox;
  RealtimeChannel? _inboxChannel;
  String _searchTerm = '';
  bool _unreadOnly = false;
  @override
  void initState() {
    super.initState();
    inbox = loadInbox();
    final userId = db.auth.currentUser?.id;
    if (userId != null) {
      _inboxChannel = db.channel('cv-inbox-$userId')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'cv_direct_messages',
          callback: (_) { if (mounted) setState(() => inbox = loadInbox()); })
        .subscribe();
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    final channel = _inboxChannel;
    if (channel != null) unawaited(channel.unsubscribe());
    super.dispose();
  }
  Future<void> refreshInbox() async {
    final next = loadInbox();
    if (mounted) setState(() => inbox = next);
    await next;
  }
  Future<List<Map<String, dynamic>>> loadInbox() async {
    final me = db.auth.currentUser!.id;
    dynamic directRaw;
    try{
      directRaw=await db.from('cv_conversations').select('id,user_a,user_b,last_message_at,is_group,group_name,group_avatar_path')
        .eq('is_group',false).or('user_a.eq.$me,user_b.eq.$me').order('last_message_at',ascending:false);
    }catch(_){
      // Backward-compatible fallback while the group migration is not yet applied.
      directRaw=await db.from('cv_conversations').select('id,user_a,user_b,last_message_at')
        .or('user_a.eq.$me,user_b.eq.$me').order('last_message_at',ascending:false);
    }
    final conversations = List<Map<String, dynamic>>.from(directRaw);
    // Group conversations are visible only through the caller's membership rows.
    try {
      final memberships = await db.from('cv_conversation_members').select('conversation_id').eq('user_id',me);
      final groupIds = List<Map<String,dynamic>>.from(memberships).map((m)=>m['conversation_id'].toString()).toList();
      if(groupIds.isNotEmpty){
        final groupRaw=await db.from('cv_conversations').select('id,user_a,user_b,last_message_at,is_group,group_name,group_avatar_path')
          .eq('is_group',true).inFilter('id',groupIds).order('last_message_at',ascending:false);
        conversations.addAll(List<Map<String,dynamic>>.from(groupRaw));
      }
    } catch (_) {
      // Until the additive group migration is applied, keep existing direct chats available.
    }
    if (conversations.isEmpty) return [];
    conversations.sort((a,b)=>(b['last_message_at']??'').toString().compareTo((a['last_message_at']??'').toString()));
    final ids = conversations.map((c) => c['id'].toString()).toList();
    final otherIds = conversations.where((c)=>c['is_group']!=true)
      .map((c) => (c['user_a'] == me ? c['user_b'] : c['user_a']).toString()).toSet().toList();
    final peopleRaw = otherIds.isEmpty ? <dynamic>[] : await db.from('public_profiles').select('id,full_name,username,avatar_url').inFilter('id', otherIds);
    final people = {for (final p in List<Map<String, dynamic>>.from(peopleRaw)) p['id'].toString(): p};
    final groupMemberIds=<String,Set<String>>{};
    final groupRows=conversations.where((c)=>c['is_group']==true).toList();
    if(groupRows.isNotEmpty){
      try{
        final memberships=await db.from('cv_conversation_members').select('conversation_id,user_id').inFilter('conversation_id',groupRows.map((g)=>g['id'].toString()).toList());
        for(final m in List<Map<String,dynamic>>.from(memberships)){
          groupMemberIds.putIfAbsent(m['conversation_id'].toString(),()=>{}).add(m['user_id'].toString());
        }
      }catch(_){}
    }
    final msgRaw = await db.from('cv_direct_messages').select('id,conversation_id,body,sender_id,created_at,read_at,attachment_path,attachment_name,attachment_mime')
      .inFilter('conversation_id', ids).order('created_at', ascending: false);
    final groupConversationIds=groupRows.map((g)=>g['id'].toString()).toSet();
    final groupIncomingIds=List<Map<String,dynamic>>.from(msgRaw)
      .where((m)=>groupConversationIds.contains(m['conversation_id'].toString())&&m['sender_id']!=me)
      .map((m)=>m['id'].toString()).toList();
    final groupReadIds=<String>{};
    if(groupIncomingIds.isNotEmpty){
      try{
        final receipts=await db.from('cv_message_receipts').select('message_id')
          .eq('user_id',me).inFilter('message_id',groupIncomingIds).not('read_at','is',null);
        groupReadIds.addAll(List<Map<String,dynamic>>.from(receipts).map((r)=>r['message_id'].toString()));
      }catch(_){}
    }
    final latest = <String, Map<String, dynamic>>{}, unreadByConversation = <String, int>{};
    for (final m in List<Map<String, dynamic>>.from(msgRaw)) {
      final cid = m['conversation_id'].toString();
      latest.putIfAbsent(cid, () => m);
      final isGroup=groupConversationIds.contains(cid);
      final isUnread=isGroup ? (m['read_at']==null&&!groupReadIds.contains(m['id'].toString())) : m['read_at']==null;
      if (m['sender_id'] != me && isUnread) unreadByConversation[cid] = (unreadByConversation[cid] ?? 0) + 1;
    }
    for (final c in conversations) {
      if(c['is_group']==true){
        c['person']={'id':'','full_name':(c['group_name']??'Group conversation').toString(),'username':'','is_group':true,
          'member_count':groupMemberIds[c['id'].toString()]?.length??0};
      }else{
        c['person'] = people[(c['user_a'] == me ? c['user_b'] : c['user_a']).toString()] ?? {};
      }
      c['latest'] = latest[c['id'].toString()];
      c['unread_count'] = unreadByConversation[c['id'].toString()] ?? 0;
    }
    return conversations;
  }
  Future<void> startChat() async {
    final query = TextEditingController();
    await showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: panel, title: const Text('Find a member'),
      content: SizedBox(width: 420, child: TextField(controller: query, decoration: const InputDecoration(hintText: 'Search by name or username'))),
      actions: [TextButton(onPressed: () => material_widgets_ui.Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final q = sanitizeSearchTerm(query.text); if (q.length < 2) return;
          try {
            final found = await db.from('public_profiles').select('id,full_name,username,avatar_url')
              .or('full_name.ilike.%$q%,username.ilike.%$q%').neq('id', db.auth.currentUser!.id).limit(12);
            if (!ctx.mounted) return;
            material_widgets_ui.Navigator.pop(ctx);
            if (!mounted) return;
            await showDialog(context: context, builder: (pickCtx) => AlertDialog(backgroundColor: panel, title: const Text('Choose a member'),
              content: SizedBox(width: 420, child: ListView(shrinkWrap: true, children: [
                for (final person in List<Map<String, dynamic>>.from(found))
                  ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text((person['full_name'] ?? person['username'] ?? 'Member').toString()),
                    subtitle: Text('@${person['username'] ?? ''}'), onTap: () async {
                      final me = db.auth.currentUser!.id, other = person['id'].toString();
                      try {
                        final existing = await db.from('cv_conversations').select('id')
                          .or('and(user_a.eq.$me,user_b.eq.$other),and(user_a.eq.$other,user_b.eq.$me)').maybeSingle();
                        String id;
                        if (existing != null) { id = existing['id'].toString(); }
                        else {
                          final a = me.compareTo(other) < 0 ? me : other, b = me.compareTo(other) < 0 ? other : me;
                          final created = await db.from('cv_conversations').insert({'user_a': a, 'user_b': b, 'created_by': me}).select('id').single();
                          id = created['id'].toString();
                        }
                        if (!pickCtx.mounted) return;
                        material_widgets_ui.Navigator.pop(pickCtx);
                        if (!mounted) return;
                        await material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => MessageThreadScreen(conversationId: id, person: person)));
                        if (mounted) setState(() => inbox = loadInbox());
                      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start chat: $e'))); }
                    }),
              ]))));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e'))); }
        }, child: const Text('Search'))]));
  }
  Future<void> startGroupChat() async {
    final nameController=TextEditingController();
    final searchController=TextEditingController();
    final selected=<String,Map<String,dynamic>>{};
    List<Map<String,dynamic>> friends=[];
    List<Map<String,dynamic>> results=[];
    bool searching=false,creating=false;
    try{
      final me=db.auth.currentUser!.id;
      final follows=await db.from('community_follows').select('following_id').eq('follower_id',me);
      final friendIds=List<Map<String,dynamic>>.from(follows)
        .map((row)=>row['following_id'].toString()).where((id)=>id!=me).toSet().toList();
      if(friendIds.isNotEmpty){
        final profiles=await db.from('public_profiles').select('id,full_name,username,avatar_url')
          .inFilter('id',friendIds);
        friends=List<Map<String,dynamic>>.from(profiles);
        friends.sort((a,b)=>(a['full_name']??a['username']??'').toString()
          .toLowerCase().compareTo((b['full_name']??b['username']??'').toString().toLowerCase()));
      }
    }catch(e){
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Could not load your followed people: $e')));}
    }
    if(!mounted){nameController.dispose();searchController.dispose();return;}
    Future<void> performSearch(StateSetter update) async {
      final q=sanitizeSearchTerm(searchController.text);
      if(q.length<2){return;}
      update(()=>searching=true);
      try{
        final found=await db.from('public_profiles').select('id,full_name,username,avatar_url')
          .or('full_name.ilike.%$q%,username.ilike.%$q%').neq('id',db.auth.currentUser!.id).limit(20);
        update(()=>results=List<Map<String,dynamic>>.from(found));
      }catch(e){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Member search failed: $e')));
      }finally{update(()=>searching=false);}
    }
    await showDialog<void>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
      backgroundColor:panel,
      title:const Text('Create a group'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:Column(
        mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        TextField(controller:nameController,decoration:const InputDecoration(labelText:'Group name',hintText:'e.g. Design learners')),
        const SizedBox(height:12),
        ExpansionTile(
          tilePadding:EdgeInsets.zero,
          initiallyExpanded:true,
          leading:const Icon(Icons.people_outline,color:emerald),
          title:const Text('Add friends'),
          subtitle:Text(friends.isEmpty?'You are not following anyone yet':'${friends.length} people you follow'),
          children:friends.isEmpty
            ?[const Padding(padding:EdgeInsets.all(12),child:Text(
              'Follow people in Community first, and they will appear here. You can also search for members below.',
              style:TextStyle(color:muted,fontSize:12)))]
            :friends.map((p){
              final id=p['id'].toString(),isSelected=selected.containsKey(id);
              return CheckboxListTile(
                dense:true,contentPadding:EdgeInsets.zero,
                value:isSelected,activeColor:emerald,
                title:Text((p['full_name']??p['username']??'Member').toString()),
                subtitle:Text('@${p['username']??''}'),
                secondary:CircleAvatar(
                  backgroundColor:panel,
                  backgroundImage:(p['avatar_url']??'').toString().isNotEmpty
                    ?NetworkImage(p['avatar_url'].toString()):null,
                  child:(p['avatar_url']??'').toString().isEmpty
                    ?const Icon(Icons.person_outline,color:muted):null),
                onChanged:(value)=>update((){
                  if(value==true){selected[id]=p;}else{selected.remove(id);}
                }));
            }).toList(),
        ),
        const Divider(height:18),
        TextField(controller:searchController,decoration:const InputDecoration(
          labelText:'Search other members',hintText:'Name or username',prefixIcon:Icon(Icons.search)),
          onSubmitted:(_)=>performSearch(update)),
        if(searching)const Center(child:Padding(padding:EdgeInsets.all(12),
          child:CircularProgressIndicator(color:emerald))),
        if(results.isNotEmpty)SizedBox(height:150,child:ListView.builder(
          shrinkWrap:true,itemCount:results.length,itemBuilder:(_,i){
            final p=results[i],id=p['id'].toString(),isSelected=selected.containsKey(id);
            return ListTile(dense:true,title:Text((p['full_name']??p['username']??'Member').toString()),
              subtitle:Text('@${p['username']??''}'),
              trailing:Icon(isSelected?Icons.check_circle:Icons.add_circle_outline,
                color:isSelected?emerald:muted),
              onTap:()=>update(()=>isSelected?selected.remove(id):selected[id]=p));
          })),
        if(selected.isNotEmpty)...[
          const SizedBox(height:10),
          Text('${selected.length} selected',style:const TextStyle(
            color:emerald,fontWeight:FontWeight.w700)),
          Wrap(spacing:6,children:[for(final entry in selected.entries)
            InputChip(label:Text((entry.value['full_name']??entry.value['username']??'Member').toString()),
              onDeleted:()=>update(()=>selected.remove(entry.key)))])
        ],
      ]))),
      actions:[
        TextButton(onPressed:creating?null:()=>material_widgets_ui.Navigator.pop(ctx),
          child:const Text('Cancel')),
        FilledButton(onPressed:creating?null:()async{
          final groupName=nameController.text.trim();
          if(groupName.length<2||groupName.length>80||selected.isEmpty){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:Text('Enter a group name and select at least one person.')));
            return;
          }
          update(()=>creating=true);
          try{
            final result=await db.rpc('cv_create_group_conversation',
              params:{'p_group_name':groupName,'p_member_ids':selected.keys.toList()});
            final id=result.toString();
            if(!ctx.mounted)return;
            material_widgets_ui.Navigator.pop(ctx);
            if(!mounted)return;
            await material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>MessageThreadScreen(
              conversationId:id,person:{'id':'','full_name':groupName,'username':'',
                'is_group':true,'member_count':selected.length+1})));
            if(mounted)await refreshInbox();
          }catch(e){
            update(()=>creating=false);
            if(mounted){ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content:Text('Group creation unavailable: $e')));}
          }
        },child:creating?const SizedBox(width:18,height:18,
          child:CircularProgressIndicator(strokeWidth:2)):const Text('Create group')),
      ],
    )));
    nameController.dispose();searchController.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Messages'), actions: [
      IconButton(onPressed:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>const CallHistoryScreen())),tooltip:'Call history',icon:const Icon(Icons.history,color:muted)),
      IconButton(onPressed: startGroupChat, tooltip: 'Create group', icon: const Icon(Icons.group_add_outlined, color: emerald)),
      IconButton(onPressed: startChat, tooltip: 'New message', icon: const Icon(Icons.edit_square, color: gold)),
    ]),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: inbox,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: emerald));
        }
        if (snap.hasError) {
          return Center(child: Text('Messages could not load: ${snap.error}',
            style: const TextStyle(color: muted)));
        }
        final rows = snap.data ?? [];
        final me = db.auth.currentUser?.id;
        final filtered = rows.where((conversation) {
          final person = Map<String, dynamic>.from(conversation['person'] as Map? ?? {});
          final name = (person['full_name'] ?? person['username'] ?? '').toString().toLowerCase();
          final username = (person['username'] ?? '').toString().toLowerCase();
          final matchesSearch = _searchTerm.trim().isEmpty ||
            name.contains(_searchTerm.toLowerCase()) || username.contains(_searchTerm.toLowerCase());
          final matchesUnread = !_unreadOnly || ((conversation['unread_count'] ?? 0) as int) > 0;
          return matchesSearch && matchesUnread;
        }).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchTerm = value),
              decoration: InputDecoration(
                hintText: 'Search chats or people',
                prefixIcon: const Icon(Icons.search, color: muted),
                suffixIcon: _searchTerm.isEmpty ? null : IconButton(
                  onPressed: () { _searchController.clear(); setState(() => _searchTerm = ''); },
                  icon: const Icon(Icons.close, color: muted),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              ChoiceChip(label: const Text('All'), selected: !_unreadOnly,
                onSelected: (_) => setState(() => _unreadOnly = false)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Unread'), selected: _unreadOnly,
                onSelected: (_) => setState(() => _unreadOnly = true)),
            ]),
          ),
          Expanded(child: rows.isEmpty
            ? Center(child: material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chat_bubble_outline, color: emerald, size: 44),
                const SizedBox(height: 12),
                const Text('No conversations yet'),
                const SizedBox(height: 8),
                FilledButton.icon(onPressed: startChat, icon: const Icon(Icons.add),
                  label: const Text('Start a conversation')),
              ]))
            : filtered.isEmpty
              ? const Center(child: Text('No chats match this view.', style: TextStyle(color: muted)))
              : RefreshIndicator(
                  color: emerald,
                  onRefresh: refreshInbox,
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final person = Map<String, dynamic>.from(c['person'] as Map? ?? {});
                      final latest = c['latest'] as Map?;
                      final name = (person['full_name'] ?? person['username'] ?? 'CreatorVerse member').toString();
                      final avatar = (person['avatar_url'] ?? '').toString();
                      final isGroup=person['is_group']==true;
                      final unread = (c['unread_count'] ?? 0) as int;
                      final body = (latest?['body'] ?? '').toString();
                      final hasAttachment = (latest?['attachment_path'] ?? '').toString().isNotEmpty;
                      final preview = hasAttachment
                        ? ((latest?['attachment_mime'] ?? '').toString().startsWith('audio/') ? 'Voice message' : ((latest?['attachment_mime'] ?? '').toString().startsWith('video/') ? 'Video' : 'Photo'))
                        : (body.isEmpty ? 'Start a conversation' : body);
                      final prefix = latest != null && latest['sender_id'] == me ? 'You: ' : '';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0x3320B887),
                          backgroundImage: avatar.startsWith('https://') ? NetworkImage(avatar) : null,
                          child: avatar.startsWith('https://') ? null : Icon(isGroup?Icons.groups_rounded:Icons.person, color: emerald),
                        ),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600)),
                        subtitle: Text(isGroup?'Group · ${person['member_count']??0} members · $preview':'$prefix$preview', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: unread > 0 ? Colors.white : muted,
                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400)),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(_timeAgo(latest?['created_at']?.toString()),
                              style: TextStyle(fontSize: 10, color: unread > 0 ? emerald : muted)),
                            const SizedBox(height: 6),
                            if (unread > 0) Container(
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: emerald, borderRadius: BorderRadius.circular(20)),
                              child: Text(unread > 99 ? '99+' : unread.toString(), textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ]),
                        onTap: () async {
                          await material_widgets_ui.Navigator.push(context, MaterialPageRoute(
                            builder: (_) => MessageThreadScreen(conversationId: c['id'].toString(), person: person)));
                          if (mounted) await refreshInbox();
                        },
                      );
                    },
                  ),
                )),
        ]);
      },
    ),
  );
}

class MessageThreadScreen extends StatefulWidget {
  final String conversationId; final Map<String, dynamic> person;
  const MessageThreadScreen({super.key, required this.conversationId, required this.person});
  @override State<MessageThreadScreen> createState()=>_MessageThreadScreenState();
}
class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final db=Supabase.instance.client, input=TextEditingController();
  final ScrollController _chatScrollController=ScrollController();
  final List<Map<String,dynamic>> _rows=[];
  final Map<String,String> _senderNames={};
  final Map<String,int> _groupReadCounts=<String,int>{};
  RealtimeChannel? _messageChannel;
  bool _initialLoading=true,_sendingAttachment=false,_showJumpToLatest=false;
  String? _loadError;
  Color _wallpaper=const Color(0xFF07151A),_myBubble=const Color(0xFF155E48); final Color _theirBubble=panel;
  static const _wallpapers=<Color>[Color(0xFF07151A),Color(0xFF102329),Color(0xFF17142B),Color(0xFF202020),Color(0xFF0D2630),Color(0xFF292016)];
  static const _myBubbles=<Color>[Color(0xFF155E48),Color(0xFF184D70),Color(0xFF553A78),Color(0xFF76502C),Color(0xFF343F4D)];
  Timer? _typingHeartbeatTimer,_typingStopTimer;
  bool _otherTyping=false,_otherOnline=false;
  final Set<String> _groupMemberIds=<String>{};
  int _onlineGroupCount=0;
  final AudioRecorder _voiceRecorder=AudioRecorder();
  Timer? _voiceClockTimer;
  bool _recordingVoice=false,_uploadingVoiceNote=false;
  String? _activeRecordingPath,_voicePreviewPath;
  DateTime? _voiceRecordingStartedAt;
  Duration _voiceRecordingDuration=Duration.zero;
  @override void initState(){super.initState();_loadChatTheme();_loadInitialMessages();_loadGroupMemberIds();_subscribeToMessages();
    input.addListener(_handleTypingInput);
    _chatScrollController.addListener(_handleScroll);}
  @override void dispose(){input.removeListener(_handleTypingInput);_typingHeartbeatTimer?.cancel();_typingStopTimer?.cancel();
    input.dispose();_chatScrollController.removeListener(_handleScroll);_chatScrollController.dispose();
    _voiceClockTimer?.cancel();unawaited(_voiceRecorder.dispose());
    final c=_messageChannel;if(c!=null)unawaited(c.unsubscribe());super.dispose();}
  void _handleTypingInput(){
    if(input.text.trim().isEmpty){_typingHeartbeatTimer?.cancel();_typingHeartbeatTimer=null;_broadcastTyping(false);return;}
    if(_typingHeartbeatTimer!=null)return;
    _broadcastTyping(true);
    _typingHeartbeatTimer=Timer.periodic(const Duration(milliseconds:1200),(_){if(input.text.trim().isEmpty){_typingHeartbeatTimer?.cancel();_typingHeartbeatTimer=null;_broadcastTyping(false);}else{_broadcastTyping(true);}});
  }
  void _broadcastTyping(bool typing){
    final channel=_messageChannel,userId=db.auth.currentUser?.id;
    if(channel==null||userId==null)return;
    unawaited(_sendTypingBroadcast(channel,userId,typing));
  }
  Future<void> _sendTypingBroadcast(RealtimeChannel channel,String userId,bool typing) async{
    try{await channel.sendBroadcastMessage(event:'typing',payload:{'user_id':userId,'typing':typing});}catch(_){}
  }
  void _receiveTyping(Map<String,dynamic> payload){
    if(payload['user_id']==db.auth.currentUser?.id)return;
    final typing=payload['typing']==true;
    _typingStopTimer?.cancel();
    if(!typing){if(mounted)setState(()=>_otherTyping=false);return;}
    if(mounted)setState(()=>_otherTyping=true);
    _typingStopTimer=Timer(const Duration(milliseconds:2400),(){if(mounted)setState(()=>_otherTyping=false);});
  }
  Future<void> _startCall({required bool video}) async{
    if(widget.person['is_group']==true)return;
    final peerId=(widget.person['id']??'').toString();
    if(peerId.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:Text('This conversation does not have a valid call recipient.')));
      return;
    }
    final mode=video?'video':'audio';
    try{
      final created=await db.rpc('cv_create_call_invite',params:{
        'p_conversation_id':widget.conversationId,'p_callee_id':peerId,'p_mode':mode
      });
      final callId=created.toString();
      if(!mounted)return;
      await material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CreatorVerseCallScreen(
        conversationId:widget.conversationId,callId:callId,
        peerName:(widget.person['full_name']??widget.person['username']??'CreatorVerse member').toString(),
        mode:mode,isCaller:true)));
    }catch(e){
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Could not start the call: $e')));}
    }
  }
  String get _themeKey=>'cv_chat_theme_${widget.conversationId}';
  Color _parseChatColor(String value,Color fallback){try{return Color(int.parse('FF${value.replaceFirst('#','')}',radix:16));}catch(_){return fallback;}}
  String _chatColorHex(Color color)=>'#${color.value.toRadixString(16).padLeft(8,'0').substring(2)}';
  Future<void> _loadChatTheme() async{
    final p=await SharedPreferences.getInstance();final w=p.getInt('${_themeKey}_wallpaper'),b=p.getInt('${_themeKey}_bubble');
    Color wallpaper=w!=null&&w>=0&&w<_wallpapers.length?_wallpapers[w]:_wallpaper;
    Color bubble=b!=null&&b>=0&&b<_myBubbles.length?_myBubbles[b]:_myBubble;
    try{final userId=db.auth.currentUser?.id;if(userId!=null){final row=await db.from('cv_chat_preferences').select('wallpaper_color,outgoing_bubble_color').eq('user_id',userId).eq('conversation_id',widget.conversationId).maybeSingle();
      if(row!=null){wallpaper=_parseChatColor((row['wallpaper_color']??'').toString(),wallpaper);bubble=_parseChatColor((row['outgoing_bubble_color']??'').toString(),bubble);}}}catch(_){}
    if(!mounted)return;setState((){_wallpaper=wallpaper;_myBubble=bubble;});
  }
  Future<void> _saveChatTheme() async{
    final p=await SharedPreferences.getInstance();await p.setInt('${_themeKey}_wallpaper',_wallpapers.indexOf(_wallpaper));await p.setInt('${_themeKey}_bubble',_myBubbles.indexOf(_myBubble));
    final userId=db.auth.currentUser?.id;if(userId!=null){await db.from('cv_chat_preferences').upsert({'user_id':userId,'conversation_id':widget.conversationId,'wallpaper_color':_chatColorHex(_wallpaper),'outgoing_bubble_color':_chatColorHex(_myBubble),'updated_at':DateTime.now().toUtc().toIso8601String()},onConflict:'user_id,conversation_id');}
  }
  void _handleScroll(){if(!_chatScrollController.hasClients)return;final atBottom=_chatScrollController.position.maxScrollExtent-_chatScrollController.position.pixels<100;
    if(mounted&&_showJumpToLatest==atBottom)setState(()=>_showJumpToLatest=!atBottom);}
  void _scrollToLatest({bool force=false}){WidgetsBinding.instance.addPostFrameCallback((_){if(!_chatScrollController.hasClients)return;
    final p=_chatScrollController.position;if(force||p.maxScrollExtent-p.pixels<180)_chatScrollController.animateTo(p.maxScrollExtent,duration:const Duration(milliseconds:180),curve:Curves.easeOut);});}
  void _upsertMessage(Map<String,dynamic> row,{String? replaceLocalId}){
    final id=(row['id']??'').toString();if(id.isEmpty)return;
    if(replaceLocalId!=null)_rows.removeWhere((m)=>m['id']==replaceLocalId);
    final i=_rows.indexWhere((m)=>m['id']==id);
    if(i>=0){_rows[i]={..._rows[i],...row};}else{_rows.add(Map<String,dynamic>.from(row));}
    _rows.sort((a,b)=>(a['created_at']??'').toString().compareTo((b['created_at']??'').toString()));
    if(mounted)setState((){});_scrollToLatest();
  }
  void _subscribeToMessages(){
    _messageChannel=db.channel('cv-chat-live-${widget.conversationId}')
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'cv_direct_messages',
        filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'conversation_id',value:widget.conversationId),
        callback:(payload){
          final row=payload.newRecord;
          if(row.isEmpty)return;
          final id=(row['id']??'').toString();
          final wasIncoming=row['sender_id']!=db.auth.currentUser?.id;
          _upsertMessage(Map<String,dynamic>.from(row));
          if(wasIncoming)unawaited(_loadSenderNames([row['sender_id']]));
          if(wasIncoming&&row['read_at']==null)unawaited(_markMessageRead(id));
        })
      .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'cv_message_receipts',callback:(payload){
        final row=payload.newRecord;
        final id=(row['message_id']??'').toString();
        if(id.isNotEmpty&&_rows.any((m)=>m['id'].toString()==id&&m['sender_id']==db.auth.currentUser?.id)){
          unawaited(_refreshGroupReadCounts([id]));
        }
      })
      .onBroadcast(event:'typing',callback:(payload)=>_receiveTyping(Map<String,dynamic>.from(payload)))
      .onPresenceSync((_)=>_syncPeerPresence())
      .subscribe((status,[error])async{
        if(status==RealtimeSubscribeStatus.subscribed){
          final userId=db.auth.currentUser?.id;
          if(userId!=null){try{await _messageChannel?.track({'user_id':userId,'online_at':DateTime.now().toUtc().toIso8601String()});}catch(_){}}
          _syncPeerPresence();
        }
      });
  }
  void _syncPeerPresence(){
    final channel=_messageChannel;
    if(channel==null)return;
    if(widget.person['is_group']==true){
      final online=<String>{};
      final me=db.auth.currentUser?.id;
      try{
        for(final state in channel.presenceState()){
          for(final presence in state.presences){
            final id=presence.payload['user_id']?.toString()??'';
            if(id.isNotEmpty&&id!=me&&_groupMemberIds.contains(id))online.add(id);
          }
        }
      }catch(_){}
      if(mounted&&online.length!=_onlineGroupCount)setState(()=>_onlineGroupCount=online.length);
      return;
    }
    final peerId=(widget.person['id']??'').toString();
    if(peerId.isEmpty)return;
    var online=false;
    try{
      for(final state in channel.presenceState()){
        for(final presence in state.presences){
          if(presence.payload['user_id']?.toString()==peerId){online=true;break;}
        }
        if(online)break;
      }
    }catch(_){}
    if(mounted&&online!=_otherOnline)setState(()=>_otherOnline=online);
  }
  Future<void> _refreshGroupReadCounts(Iterable<String> messageIds) async{
    if(widget.person['is_group']!=true)return;
    final ids=messageIds.where((id)=>id.isNotEmpty).toSet().toList();
    if(ids.isEmpty)return;
    try{
      final raw=await db.from('cv_message_receipts').select('message_id,user_id')
        .inFilter('message_id',ids).not('read_at','is',null);
      final counts=<String,int>{};
      for(final receipt in List<Map<String,dynamic>>.from(raw)){
        final id=receipt['message_id'].toString();
        counts[id]=(counts[id]??0)+1;
      }
      if(!mounted)return;
      setState((){
        for(final id in ids){_groupReadCounts[id]=counts[id]??0;}
      });
    }catch(_){}
  }
  Future<void> _loadGroupMemberIds() async{
    if(widget.person['is_group']!=true)return;
    try{
      final raw=await db.from('cv_conversation_members').select('user_id').eq('conversation_id',widget.conversationId);
      _groupMemberIds
        ..clear()
        ..addAll(List<Map<String,dynamic>>.from(raw).map((m)=>m['user_id'].toString()));
      _syncPeerPresence();
    }catch(_){}
  }
  Future<void> _loadSenderNames(Iterable<dynamic> senderIds) async{
    if(widget.person['is_group']!=true)return;
    final ids=senderIds.map((id)=>id.toString()).where((id)=>id.isNotEmpty&&id!=db.auth.currentUser?.id).toSet()
      .where((id)=>!_senderNames.containsKey(id)).toList();
    if(ids.isEmpty)return;
    try{
      final raw=await db.from('public_profiles').select('id,full_name,username').inFilter('id',ids);
      if(!mounted)return;
      setState((){
        for(final p in List<Map<String,dynamic>>.from(raw)){
          _senderNames[p['id'].toString()]=(p['full_name']??p['username']??'Member').toString();
        }
      });
    }catch(_){}
  }
  Future<void> _addGroupMembers(Set<String> existingIds) async{
    final search=TextEditingController();
    final selected=<String>{};
    var found=<Map<String,dynamic>>[];
    var searching=false;
    var saving=false;
    var added=0;
    await showDialog<void>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(dialogContext,update)=>AlertDialog(
      backgroundColor:panel,
      title:const Text('Add people to group'),
      content:SizedBox(width:420,height:420,child:Column(children:[
        Row(children:[
          Expanded(child:TextField(controller:search,decoration:const InputDecoration(hintText:'Search name or username',prefixIcon:Icon(Icons.search)))),
          const SizedBox(width:8),
          IconButton(onPressed:searching?null:()async{
            final term=sanitizeSearchTerm(search.text);
            if(term.length<2)return;
            update(()=>searching=true);
            try{
              final raw=await db.from('public_profiles').select('id,full_name,username,avatar_url')
                .or('full_name.ilike.%$term%,username.ilike.%$term%')
                .neq('id',db.auth.currentUser!.id).limit(30);
              update(()=>found=List<Map<String,dynamic>>.from(raw)
                .where((p)=>!existingIds.contains(p['id'].toString())).toList());
            }catch(e){
              if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Member search failed: $e')));
            }finally{update(()=>searching=false);}
          },icon:const Icon(Icons.search,color:emerald))
        ]),
        const SizedBox(height:10),
        Expanded(child:searching?const Center(child:CircularProgressIndicator(color:emerald))
          :found.isEmpty?const Center(child:Text('Search for people to add.',style:TextStyle(color:muted)))
          :ListView(children:[for(final person in found)
            CheckboxListTile(
              value:selected.contains(person['id'].toString()),
              onChanged:saving?null:(value)=>update((){
                if(value==true){
                  if(selected.length<50){selected.add(person['id'].toString());}
                }else{
                  selected.remove(person['id'].toString());
                }
              }),
              title:Text((person['full_name']??person['username']??'CreatorVerse member').toString()),
              subtitle:Text('@${person['username']??''}'),
              activeColor:emerald,
              secondary:CircleAvatar(child:const Icon(Icons.person_outline))
            )])),
        Align(alignment:Alignment.centerLeft,child:Text('${selected.length} selected',style:const TextStyle(color:muted,fontSize:12)))
      ])),
      actions:[
        TextButton(onPressed:saving?null:()=>Navigator.pop(dialogContext),child:const Text('Cancel')),
        FilledButton(onPressed:saving||selected.isEmpty?null:()async{
          update(()=>saving=true);
          try{
            final result=await db.rpc('cv_add_group_members',params:{
              'p_conversation_id':widget.conversationId,'p_member_ids':selected.toList()
            });
            added=(result as num?)?.toInt()??0;
            if(dialogContext.mounted)Navigator.pop(dialogContext);
          }catch(e){
            update(()=>saving=false);
            if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not add members: $e')));
          }
        },child:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Text('Add selected'))
      ]
    )));
    search.dispose();
    if(added>0&&mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$added member${added==1?'':'s'} added to the group.')));
      Navigator.of(context).pop();
      await _showGroupInfo();
    }
  }
  Future<void> _changeGroupMember(String memberId,String action) async{
    try{
      if(action=='remove'){
        final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
          backgroundColor:panel,title:const Text('Remove member?'),
          content:const Text('This person will no longer be able to read or send messages in this group.'),
          actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
            FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Remove'))]));
        if(confirmed!=true)return;
        await db.rpc('cv_remove_group_member',params:{'p_conversation_id':widget.conversationId,'p_member_id':memberId});
      }else{
        await db.rpc('cv_update_group_member_role',params:{
          'p_conversation_id':widget.conversationId,'p_member_id':memberId,'p_new_role':action
        });
      }
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(action=='remove'?'Member removed.':action=='admin'?'Group admin updated.':'Admin role removed.')));
      Navigator.of(context).pop();
      await _showGroupInfo();
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Group update failed: $e')));
    }
  }
  Future<void> _leaveGroupAndClose() async{
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      backgroundColor:panel,title:const Text('Leave this group?'),
      content:const Text('You will stop receiving messages from this group. An admin must add you again if you want to rejoin.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Stay')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Leave group'))]));
    if(confirmed!=true)return;
    try{
      await db.rpc('cv_leave_group',params:{'p_conversation_id':widget.conversationId});
      if(!mounted)return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('You left the group.')));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not leave group: $e')));
    }
  }
  Future<void> _showGroupInfo() async{
    if(widget.person['is_group']!=true)return;
    try{
      final members=await db.from('cv_conversation_members').select('user_id,member_role,joined_at')
        .eq('conversation_id',widget.conversationId).order('joined_at');
      final rows=List<Map<String,dynamic>>.from(members);
      final ids=rows.map((m)=>m['user_id'].toString()).toList();
      _groupMemberIds..clear()..addAll(ids);
      _syncPeerPresence();
      final profiles=ids.isEmpty?[]:await db.from('public_profiles').select('id,full_name,username,avatar_url').inFilter('id',ids);
      final people={for(final p in List<Map<String,dynamic>>.from(profiles))p['id'].toString():p};
      final me=db.auth.currentUser?.id??'';
      final mine=rows.where((m)=>m['user_id'].toString()==me).toList();
      final myRole=mine.isEmpty?'member':(mine.first['member_role']??'member').toString();
      final isAdmin=myRole=='admin';
      if(!mounted)return;
      await showModalBottomSheet<void>(context:context,backgroundColor:panel,isScrollControlled:true,builder:(ctx)=>SafeArea(child:Padding(
        padding:const EdgeInsets.fromLTRB(18,18,18,28),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text((widget.person['full_name']??'Group').toString(),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
              const SizedBox(height:4),Text('${rows.length} members · ${isAdmin?'Admin':'Member'}',style:const TextStyle(color:muted))
            ])),
            if(isAdmin)IconButton(tooltip:'Add members',onPressed:()=>_addGroupMembers(ids.toSet()),icon:const Icon(Icons.person_add_alt_1,color:emerald))
          ]),
          const Divider(height:24),
          Flexible(child:ListView(shrinkWrap:true,children:[for(final member in rows)
            Builder(builder:(_){
              final memberId=member['user_id'].toString();
              final p=people[memberId]??{};
              final name=(p['full_name']??p['username']??'CreatorVerse member').toString();
              final avatar=(p['avatar_url']??'').toString();
              final role=(member['member_role']??'member').toString();
              return ListTile(dense:true,leading:CircleAvatar(backgroundImage:avatar.startsWith('https://')?NetworkImage(avatar):null,
                child:avatar.startsWith('https://')?null:const Icon(Icons.person,color:emerald)),
                title:Text(name),subtitle:Text('@${p['username']??''}'),
                trailing:memberId==me||!isAdmin?Text(role.toUpperCase(),style:const TextStyle(color:gold,fontSize:10,fontWeight:FontWeight.w800))
                  :PopupMenuButton<String>(tooltip:'Manage member',onSelected:(value)=>_changeGroupMember(memberId,value),itemBuilder:(_)=>[
                    if(role!='admin')const PopupMenuItem(value:'admin',child:Text('Make group admin')),
                    if(role=='admin')const PopupMenuItem(value:'member',child:Text('Remove admin role')),
                    const PopupMenuItem(value:'remove',child:Text('Remove from group')),
                  ],child:Row(mainAxisSize:MainAxisSize.min,children:[
                    Text(role.toUpperCase(),style:const TextStyle(color:gold,fontSize:10,fontWeight:FontWeight.w800)),
                    const Icon(Icons.more_vert,size:18)
                  ])));
            })])),
          const SizedBox(height:12),
          SizedBox(width:double.infinity,child:OutlinedButton.icon(
            onPressed:()=>_leaveGroupAndClose(),
            icon:const Icon(Icons.exit_to_app),label:const Text('Leave group'),
            style:OutlinedButton.styleFrom(foregroundColor:Colors.redAccent)
          ))
        ]))));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Group details are unavailable: $e')));
    }
  }
  Future<void> _markMessageRead(String id) async{
    final now=DateTime.now().toUtc().toIso8601String();
    try{
      if(widget.person['is_group']==true){
        final me=db.auth.currentUser!.id;
        await db.from('cv_message_receipts').upsert({
          'message_id':id,'user_id':me,'delivered_at':now,'read_at':now
        },onConflict:'message_id,user_id');
      }else{
        await db.from('cv_direct_messages').update({'read_at':now}).eq('id',id).eq('conversation_id',widget.conversationId)
          .neq('sender_id',db.auth.currentUser!.id);
      }
      final i=_rows.indexWhere((m)=>m['id'].toString()==id);
      if(i>=0){_rows[i]['read_at']=now;if(mounted)setState((){});}
    }catch(_){}
  }
  Future<void> _loadInitialMessages() async{
    try{
      final raw=await db.from('cv_direct_messages').select('id,sender_id,body,created_at,read_at,attachment_path,attachment_name,attachment_mime,attachment_size')
        .eq('conversation_id',widget.conversationId).order('created_at',ascending:true);
      final loaded=List<Map<String,dynamic>>.from(raw);
      unawaited(_loadSenderNames(loaded.map((m)=>m['sender_id'])));
      final me=db.auth.currentUser?.id;
      if(widget.person['is_group']==true&&me!=null){
        await _refreshGroupReadCounts(loaded.where((m)=>m['sender_id']==me).map((m)=>m['id'].toString()));
      }
      if(me!=null&&widget.person['is_group']==true){
        final incomingIds=loaded.where((m)=>m['sender_id']!=me).map((m)=>m['id'].toString()).toList();
        final readIds=<String>{};
        if(incomingIds.isNotEmpty){
          try{
            final receipts=await db.from('cv_message_receipts').select('message_id')
              .eq('user_id',me).inFilter('message_id',incomingIds).not('read_at','is',null);
            readIds.addAll(List<Map<String,dynamic>>.from(receipts).map((r)=>r['message_id'].toString()));
          }catch(_){}
        }
        final unread=incomingIds.where((id)=>!readIds.contains(id)).toList();
        if(unread.isNotEmpty){
          final now=DateTime.now().toUtc().toIso8601String();
          try{
            await db.from('cv_message_receipts').upsert(unread.map((id)=>{
              'message_id':id,'user_id':me,'delivered_at':now,'read_at':now
            }).toList(),onConflict:'message_id,user_id');
            for(final m in loaded){if(unread.contains(m['id'].toString()))m['read_at']=now;}
          }catch(_){}
        }
      }else{
        final unread=loaded.where((m)=>m['sender_id']!=me&&m['read_at']==null).map((m)=>m['id'].toString()).toList();
        if(unread.isNotEmpty&&me!=null){final now=DateTime.now().toUtc().toIso8601String();
          try{await db.from('cv_direct_messages').update({'read_at':now}).inFilter('id',unread).eq('conversation_id',widget.conversationId);
            for(final m in loaded){if(unread.contains(m['id'].toString()))m['read_at']=now;}}catch(_){}
        }
      }
      if(!mounted)return;final live={for(final row in _rows)row['id'].toString():row};for(final row in loaded){live[row['id'].toString()]=row;}final merged=live.values.toList()..sort((a,b)=>(a['created_at']??'').toString().compareTo((b['created_at']??'').toString()));setState((){_rows..clear()..addAll(merged);_initialLoading=false;});
      _scrollToLatest(force:true);
    }catch(e){if(!mounted)return;setState(()=>_loadError=e.toString());setState(()=>_initialLoading=false);}
  }
  Future<void> _openChatAppearance() async{
    await showModalBottomSheet<void>(context:context,backgroundColor:panel,isScrollControlled:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>SafeArea(child:Padding(
      padding:const EdgeInsets.fromLTRB(18,18,18,26),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Chat appearance',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),const SizedBox(height:16),
        const Text('Chat wallpaper',style:TextStyle(color:muted,fontWeight:FontWeight.w700)),const SizedBox(height:9),
        Wrap(spacing:12,runSpacing:12,children:[for(var i=0;i<_wallpapers.length;i++)GestureDetector(onTap:(){update(()=>_wallpaper=_wallpapers[i]);},
          child:Container(width:48,height:48,decoration:BoxDecoration(color:_wallpapers[i],shape:BoxShape.circle,border:Border.all(color:_wallpaper==_wallpapers[i]?gold:Colors.white24,width:_wallpaper==_wallpapers[i]?3:1)),
            child:_wallpaper==_wallpapers[i]?const Icon(Icons.check,color:Colors.white):null))]),
        const SizedBox(height:18),const Text('Your message bubble',style:TextStyle(color:muted,fontWeight:FontWeight.w700)),const SizedBox(height:9),
        Wrap(spacing:12,children:[for(var i=0;i<_myBubbles.length;i++)GestureDetector(onTap:(){update(()=>_myBubble=_myBubbles[i]);},
          child:Container(width:48,height:36,decoration:BoxDecoration(color:_myBubbles[i],borderRadius:BorderRadius.circular(12),border:Border.all(color:_myBubble==_myBubbles[i]?gold:Colors.white24,width:_myBubble==_myBubbles[i]?3:1)),
            child:_myBubble==_myBubbles[i]?const Icon(Icons.check,color:Colors.white,size:17):null))]),
        const SizedBox(height:20),FilledButton(onPressed:()async{await _saveChatTheme();if(ctx.mounted)material_widgets_ui.Navigator.pop(ctx);if(mounted)setState((){});},
          style:FilledButton.styleFrom(backgroundColor:emerald,minimumSize:const Size.fromHeight(46)),child:const Text('Apply chat theme')),
      ])))));
  }
  Future<void> attachMedia() async{
    if(_sendingAttachment)return;
    final choice=await showModalBottomSheet<String>(context:context,backgroundColor:panel,builder:(ctx)=>SafeArea(child:Wrap(children:[
      ListTile(leading:const Icon(Icons.photo_outlined,color:emerald),title:const Text('Send a photo'),onTap:()=>material_widgets_ui.Navigator.pop(ctx,'image')),
      ListTile(leading:const Icon(Icons.videocam_outlined,color:emerald),title:const Text('Send a video'),onTap:()=>material_widgets_ui.Navigator.pop(ctx,'video'))])));
    if(choice==null||!mounted)return;
    final picker=ImagePicker();final XFile? file=choice=='video'?await picker.pickVideo(source:ImageSource.gallery,maxDuration:const Duration(seconds:90)):
      await picker.pickImage(source:ImageSource.gallery,imageQuality:85,maxWidth:1920);
    if(file==null)return;setState(()=>_sendingAttachment=true);
    final localId='local-${DateTime.now().microsecondsSinceEpoch}';final me=db.auth.currentUser!.id;
    try{
      final bytes=await file.readAsBytes();if(bytes.length>50*1024*1024)throw Exception('Please choose a file smaller than 50 MB.');
      final name=file.name,ext=name.contains('.')?name.split('.').last.toLowerCase():'',isVideo=choice=='video';
      final mime=isVideo?(ext=='mov'?'video/quicktime':ext=='webm'?'video/webm':'video/mp4'):(ext=='png'?'image/png':ext=='webp'?'image/webp':ext=='gif'?'image/gif':'image/jpeg');
      final path='${widget.conversationId}/$me/${DateTime.now().microsecondsSinceEpoch}_${name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'_')}';
      final optimistic={'id':localId,'sender_id':me,'body':isVideo?'Shared a video':'Shared a photo','created_at':DateTime.now().toUtc().toIso8601String(),'pending':true};
      _upsertMessage(optimistic);
      await db.storage.from('cv-chat-files').uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mime,upsert:false));
      final result=await db.from('cv_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':me,
        'body':optimistic['body'],'attachment_path':path,'attachment_name':name,'attachment_mime':mime,'attachment_size':bytes.length})
        .select('id,sender_id,body,created_at,read_at,attachment_path,attachment_name,attachment_mime,attachment_size').single();
      _upsertMessage(Map<String,dynamic>.from(result),replaceLocalId:localId);
    }catch(e){if(mounted){setState(()=>_rows.removeWhere((m)=>m['id']==localId));ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not send attachment: $e')));}}
    finally{if(mounted)setState(()=>_sendingAttachment=false);}
  }
  Future<void> _startVoiceRecording() async{
    if(_recordingVoice||_uploadingVoiceNote||_sendingAttachment)return;
    try{
      final allowed=await _voiceRecorder.hasPermission();
      if(!allowed){
        if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:Text('Allow microphone access to record a voice note.')));}
        return;
      }
      final path='${Directory.systemTemp.path}/creatorverse_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _voiceRecorder.start(const RecordConfig(
        encoder:AudioEncoder.aacLc,bitRate:64000,sampleRate:44100,numChannels:1),path:path);
      if(!mounted){await _voiceRecorder.cancel();return;}
      setState((){
        _recordingVoice=true;_activeRecordingPath=path;
        _voiceRecordingStartedAt=DateTime.now();_voiceRecordingDuration=Duration.zero;
        _voicePreviewPath=null;
      });
      _voiceClockTimer?.cancel();
      _voiceClockTimer=Timer.periodic(const Duration(seconds:1),(_){
        final started=_voiceRecordingStartedAt;
        if(mounted&&started!=null)setState(()=>_voiceRecordingDuration=DateTime.now().difference(started));
      });
    }catch(e){
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Could not start voice recording: $e')));}
    }
  }
  Future<void> _finishVoiceRecording() async{
    if(!_recordingVoice)return;
    _voiceClockTimer?.cancel();_voiceClockTimer=null;
    final started=_voiceRecordingStartedAt;
    try{
      final path=await _voiceRecorder.stop();
      final duration=started==null?Duration.zero:DateTime.now().difference(started);
      if(!mounted)return;
      setState((){
        _recordingVoice=false;_activeRecordingPath=null;
        _voiceRecordingStartedAt=null;_voiceRecordingDuration=duration;
        _voicePreviewPath=path;
      });
      if(path==null||duration<const Duration(milliseconds:600)){
        if(path!=null){try{await File(path).delete();}catch(_){}}
        if(mounted){setState(()=>_voicePreviewPath=null);}
        if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:Text('Record a little longer before sending your voice note.')));}
      }
    }catch(e){
      if(mounted){setState(()=>_recordingVoice=false);}
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Could not finish voice recording: $e')));}
    }
  }
  Future<void> _cancelVoiceRecording() async{
    _voiceClockTimer?.cancel();_voiceClockTimer=null;
    final path=_activeRecordingPath;
    try{await _voiceRecorder.cancel();}catch(_){}
    if(path!=null){try{await File(path).delete();}catch(_){}}
    if(mounted){setState((){
      _recordingVoice=false;_activeRecordingPath=null;
      _voiceRecordingStartedAt=null;_voiceRecordingDuration=Duration.zero;
    });}
  }
  Future<void> _discardVoiceNote() async{
    final path=_voicePreviewPath;
    if(path!=null){try{await File(path).delete();}catch(_){}}
    if(mounted){setState(()=>_voicePreviewPath=null);}
  }
  Future<void> _sendVoiceNote() async{
    final localPath=_voicePreviewPath;
    if(localPath==null||_uploadingVoiceNote||_recordingVoice)return;
    final localId='local-${DateTime.now().microsecondsSinceEpoch}';
    final me=db.auth.currentUser!.id;
    final timestamp=DateTime.now().microsecondsSinceEpoch;
    final storagePath='${widget.conversationId}/$me/voice_$timestamp.m4a';
    setState(()=>_uploadingVoiceNote=true);
    try{
      final bytes=await File(localPath).readAsBytes();
      if(bytes.length>20*1024*1024)throw Exception('Voice note is larger than 20 MB.');
      _upsertMessage({
        'id':localId,'sender_id':me,'body':'Voice message',
        'created_at':DateTime.now().toUtc().toIso8601String(),'read_at':null,
        'attachment_mime':'audio/mp4','attachment_name':'Voice message.m4a',
        'attachment_size':bytes.length,'pending':true
      });
      await db.storage.from('cv-chat-files').uploadBinary(storagePath,bytes,
        fileOptions:const FileOptions(contentType:'audio/mp4',upsert:false));
      final result=await db.from('cv_direct_messages').insert({
        'conversation_id':widget.conversationId,'sender_id':me,'body':'Voice message',
        'attachment_path':storagePath,'attachment_name':'Voice message.m4a',
        'attachment_mime':'audio/mp4','attachment_size':bytes.length
      }).select('id,sender_id,body,created_at,read_at,attachment_path,attachment_name,attachment_mime,attachment_size').single();
      _upsertMessage(Map<String,dynamic>.from(result),replaceLocalId:localId);
      try{await File(localPath).delete();}catch(_){}
      if(mounted)setState(()=>_voicePreviewPath=null);
    }catch(e){
      if(mounted){
        setState(()=>_rows.removeWhere((m)=>m['id']==localId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content:Text('Voice note was not sent: $e')));
      }
    }finally{if(mounted)setState(()=>_uploadingVoiceNote=false);}
  }
  Future<void> send() async{
    final body=input.text.trim();if(body.isEmpty)return;
    _typingHeartbeatTimer?.cancel();_typingHeartbeatTimer=null;_broadcastTyping(false);
    final me=db.auth.currentUser!.id,localId='local-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic=<String,dynamic>{'id':localId,'sender_id':me,'body':body,'created_at':DateTime.now().toUtc().toIso8601String(),'read_at':null,'pending':true};
    input.clear();_upsertMessage(optimistic);
    try{
      final result=await db.from('cv_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':me,'body':body})
        .select('id,sender_id,body,created_at,read_at,attachment_path,attachment_name,attachment_mime,attachment_size').single();
      _upsertMessage(Map<String,dynamic>.from(result),replaceLocalId:localId);
    }catch(e){
      if(!mounted)return;setState(()=>_rows.removeWhere((m)=>m['id']==localId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Message not sent: $e')));
    }
  }
  Widget _messageBubble(Map<String,dynamic> m){
    final mine=m['sender_id']==db.auth.currentUser!.id,pending=m['pending']==true;
    final groupReadCount=widget.person['is_group']==true?(_groupReadCounts[m['id'].toString()]??0):0;
    final read=widget.person['is_group']==true?groupReadCount>0:m['read_at']!=null;
    final time=DateTime.tryParse((m['created_at']??'').toString());
    final body=(m['body']??'').toString();
    final path=(m['attachment_path']??'').toString();
    final mime=(m['attachment_mime']??'').toString();
    final hasAttachment=path.isNotEmpty;
    final isAudio=mime.startsWith('audio/');
    final standaloneMedia=hasAttachment&&!isAudio;
    final senderName=_senderNames[(m['sender_id']??'').toString()]??'Group member';
    final metadata=Row(mainAxisSize:MainAxisSize.min,children:[
      Text(time==null?'':TimeOfDay.fromDateTime(time.toLocal()).format(context),
        style:const TextStyle(fontSize:9,color:Colors.white60)),
      if(mine)...[
        if(widget.person['is_group']==true&&groupReadCount>0)Padding(
          padding:const EdgeInsets.only(right:4),
          child:Text('Seen by $groupReadCount',style:const TextStyle(fontSize:8,color:Colors.white70))),
        const SizedBox(width:5),
        Icon(pending?Icons.schedule:read?Icons.done_all:Icons.done,size:14,
          color:pending?Colors.white54:read?const Color(0xFF66C8FF):Colors.white60)
      ]
    ]);
    if(standaloneMedia){
      return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,
        child:Column(crossAxisAlignment:mine?CrossAxisAlignment.end:CrossAxisAlignment.start,
          mainAxisSize:MainAxisSize.min,children:[
            if(widget.person['is_group']==true&&!mine)Padding(
              padding:const EdgeInsets.only(left:5,bottom:3),
              child:Text(senderName,style:const TextStyle(fontSize:10,color:gold,fontWeight:FontWeight.w700))),
            if(body.trim().isNotEmpty)Container(
              constraints:const BoxConstraints(maxWidth:310),
              margin:const EdgeInsets.symmetric(vertical:2),
              padding:const EdgeInsets.symmetric(horizontal:13,vertical:10),
              decoration:BoxDecoration(color:mine?_myBubble:_theirBubble,borderRadius:BorderRadius.circular(15)),
              child:Text(body,style:const TextStyle(height:1.35))),
            Container(constraints:const BoxConstraints(maxWidth:310),
              margin:const EdgeInsets.symmetric(vertical:3),
              child:MessageAttachmentPreview(path:path,mime:mime,
                name:(m['attachment_name']??'Attachment').toString())),
            Padding(padding:const EdgeInsets.symmetric(horizontal:4,vertical:2),child:metadata),
          ]));
    }
    return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,
      child:Container(constraints:const BoxConstraints(maxWidth:310),
        margin:const EdgeInsets.symmetric(vertical:4),
        padding:const EdgeInsets.symmetric(horizontal:13,vertical:10),
        decoration:BoxDecoration(color:mine?_myBubble:_theirBubble,borderRadius:BorderRadius.circular(15)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.end,mainAxisSize:MainAxisSize.min,children:[
          if(widget.person['is_group']==true&&!mine)Align(alignment:Alignment.centerLeft,
            child:Padding(padding:const EdgeInsets.only(bottom:4),
              child:Text(senderName,style:const TextStyle(fontSize:10,color:gold,fontWeight:FontWeight.w700)))),
          if(body.isNotEmpty&&!isAudio)Align(alignment:Alignment.centerLeft,
            child:Text(body,style:const TextStyle(height:1.35))),
          if(hasAttachment&&isAudio)VoiceMessagePlayer(key:ValueKey(m['id']),path:path),
          const SizedBox(height:4),
          metadata,
        ])));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:_wallpaper,
    appBar:AppBar(title:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
      Text((widget.person['full_name']??widget.person['username']??'Chat').toString()),
      if(widget.person['is_group']==true)Text(_otherTyping?'Someone is typing…':'Group · ${widget.person['member_count']??0} members · $_onlineGroupCount online',style:TextStyle(fontSize:11,color:_otherTyping?emerald:muted,fontWeight:_otherTyping?FontWeight.w600:FontWeight.normal))
      else if(_otherTyping)const Text('typing…',style:TextStyle(fontSize:11,color:emerald,fontWeight:FontWeight.w500))
      else Text(_otherOnline?'online':'offline',style:TextStyle(fontSize:11,color:_otherOnline?emerald:muted,fontWeight:FontWeight.w500))
    ]),
      actions:[
        if(widget.person['is_group']==true)IconButton(tooltip:'Group information',onPressed:_showGroupInfo,icon:const Icon(Icons.group_outlined,color:emerald)),
        if(widget.person['is_group']!=true)IconButton(tooltip:'Audio call',onPressed:()=>_startCall(video:false),icon:const Icon(Icons.call_outlined,color:emerald)),
        if(widget.person['is_group']!=true)IconButton(tooltip:'Video call',onPressed:()=>_startCall(video:true),icon:const Icon(Icons.videocam_outlined,color:gold)),
        if(widget.person['is_group']!=true)IconButton(tooltip:'Call history',onPressed:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CallHistoryScreen(conversationId:widget.conversationId,peerName:(widget.person['full_name']??widget.person['username']??'CreatorVerse member').toString()))),icon:const Icon(Icons.history,color:muted)),
        IconButton(tooltip:'Chat wallpaper and theme',onPressed:_openChatAppearance,icon:const Icon(Icons.palette_outlined,color:gold))
      ]),
    body:Stack(children:[
      Column(children:[
        Expanded(child:_initialLoading?const Center(child:CircularProgressIndicator(color:emerald)):
          _loadError!=null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Could not load this conversation.',style:TextStyle(color:muted)),TextButton(onPressed:(){setState((){_initialLoading=true;_loadError=null;});_loadInitialMessages();},child:const Text('Try again'))])):
          _rows.isEmpty?const Center(child:Text('Say hello to start the conversation.',style:TextStyle(color:muted))):
          ListView.builder(controller:_chatScrollController,padding:const EdgeInsets.all(14),itemCount:_rows.length,
            itemBuilder:(ctx,i)=>_messageBubble(_rows[i]))),
        SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(8,8,10,10),child:
          _recordingVoice
            ?Row(children:[
              const Icon(Icons.fiber_manual_record,color:Colors.redAccent,size:14),
              const SizedBox(width:8),
              Expanded(child:Text('Recording voice note · ${_voiceRecordingDuration.inMinutes.toString().padLeft(2,'0')}:${(_voiceRecordingDuration.inSeconds%60).toString().padLeft(2,'0')}',
                style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600))),
              IconButton(tooltip:'Cancel recording',onPressed:_cancelVoiceRecording,
                icon:const Icon(Icons.delete_outline,color:Colors.redAccent)),
              IconButton(tooltip:'Stop and preview',onPressed:_finishVoiceRecording,
                icon:const Icon(Icons.stop_circle,color:emerald,size:30)),
            ])
            :_voicePreviewPath!=null
              ?Row(children:[
                Expanded(child:VoiceMessagePlayer(path:_voicePreviewPath!,local:true)),
                IconButton(tooltip:'Discard voice note',onPressed:_uploadingVoiceNote?null:_discardVoiceNote,
                  icon:const Icon(Icons.delete_outline,color:Colors.redAccent)),
                IconButton(tooltip:'Send voice note',onPressed:_uploadingVoiceNote?null:_sendVoiceNote,
                  icon:_uploadingVoiceNote?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send,color:emerald)),
              ])
              :Row(children:[
                IconButton(tooltip:'Attach photo or video',onPressed:_sendingAttachment?null:attachMedia,
                  icon:_sendingAttachment?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.attach_file,color:gold)),
                Expanded(child:TextField(controller:input,minLines:1,maxLines:4,textInputAction:TextInputAction.newline,
                  onSubmitted:(_)=>send(),decoration:const InputDecoration(hintText:'Message...'))),
                const SizedBox(width:2),
                IconButton(tooltip:'Record voice note',onPressed:_startVoiceRecording,
                  icon:const Icon(Icons.mic_none,color:gold)),
                IconButton(tooltip:'Send message',onPressed:send,icon:const Icon(Icons.send,color:emerald)),
              ])))
      ]),
      if(_showJumpToLatest)Positioned(right:16,bottom:82,child:FloatingActionButton.small(heroTag:'chat-latest',backgroundColor:panel,onPressed:()=>_scrollToLatest(force:true),child:const Icon(Icons.keyboard_arrow_down,color:gold)))
    ]));
}
class MessageAttachmentPreview extends StatefulWidget {
  final String path, mime, name;
  const MessageAttachmentPreview({super.key, required this.path, required this.mime, required this.name});
  @override
  State<MessageAttachmentPreview> createState() => _MessageAttachmentPreviewState();
}
class _MessageAttachmentPreviewState extends State<MessageAttachmentPreview> {
  late Future<String> signedUrl;
  @override
  void initState() { super.initState(); _load(); }
  void _load() { signedUrl = Supabase.instance.client.storage.from('cv-chat-files').createSignedUrl(widget.path, 3600); }
  @override
  void didUpdateWidget(covariant MessageAttachmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) { setState(_load); }
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(future: signedUrl, builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(padding: EdgeInsets.all(10),
        child: SizedBox(width: 150, height: 70, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: emerald))));
    }
    if (snapshot.hasError || !snapshot.hasData) {
      return const Text('Attachment unavailable', style: TextStyle(color: muted, fontSize: 11));
    }
    final url = snapshot.data!;
    if (widget.mime.startsWith('video/')) {
      return SizedBox(width:245,child:Stack(alignment:Alignment.topRight,children:[
        InlineVideoPlayer(url:url),
        IconButton.filled(onPressed:()=>_saveRemoteMedia(context,url,widget.mime,widget.name),
          icon:const Icon(Icons.download_rounded),tooltip:'Save video',style:IconButton.styleFrom(backgroundColor:Colors.black87)),
      ]));
    }
    if (widget.mime.startsWith('image/')) {
      return SizedBox(width:245,child:Stack(alignment:Alignment.topRight,children:[
        GestureDetector(onTap:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>Scaffold(
          backgroundColor:Colors.black,appBar:AppBar(backgroundColor:Colors.black),body:Center(child:InteractiveViewer(
            minScale:.7,maxScale:4,child:Image.network(url,fit:BoxFit.contain)))))),
          child:ClipRRect(borderRadius:BorderRadius.circular(9),child:Image.network(url,width:245,fit:BoxFit.cover,
            errorBuilder:(_,__,___)=>const Text('Image unavailable',style:TextStyle(color:muted))))),
        IconButton.filled(onPressed:()=>_saveRemoteMedia(context,url,widget.mime,widget.name),
          icon:const Icon(Icons.download_rounded),tooltip:'Save image',style:IconButton.styleFrom(backgroundColor:Colors.black87)),
      ]));
    }
    return TextButton.icon(onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.download_outlined), label: Text(widget.name, overflow: TextOverflow.ellipsis));
  });
}

class VoiceMessagePlayer extends StatefulWidget {
  final String path;
  final bool local;
  const VoiceMessagePlayer({super.key,required this.path,this.local=false});
  @override State<VoiceMessagePlayer> createState()=>_VoiceMessagePlayerState();
}
class _VoiceMessagePlayerState extends State<VoiceMessagePlayer>{
  late final AudioPlayer _player;
  bool _ready=false,_failed=false;
  @override void initState(){super.initState();_player=AudioPlayer();_load();}
  Future<void> _load() async{
    try{
      if(widget.local){
        await _player.setFilePath(widget.path);
      }else{
        final url=await Supabase.instance.client.storage.from('cv-chat-files')
          .createSignedUrl(widget.path,3600);
        await _player.setUrl(url);
      }
      if(mounted)setState(()=>_ready=true);
    }catch(_){if(mounted)setState(()=>_failed=true);}
  }
  @override void didUpdateWidget(covariant VoiceMessagePlayer oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.path!=widget.path||oldWidget.local!=widget.local){
      _ready=false;_failed=false;_player.stop();_load();
    }
  }
  String _clock(Duration value)=>'${value.inMinutes.toString().padLeft(2,'0')}:${(value.inSeconds%60).toString().padLeft(2,'0')}';
  @override void dispose(){unawaited(_player.dispose());super.dispose();}
  @override Widget build(BuildContext context)=>SizedBox(width:widget.local?double.infinity:250,child:Row(children:[
    if(!_ready)
      SizedBox(width:38,height:38,child:Center(child:_failed
        ?const Icon(Icons.error_outline,color:Colors.redAccent,size:20)
        :const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:emerald))))
    else
      StreamBuilder<PlayerState>(stream:_player.playerStateStream,builder:(context,snapshot){
        final playing=snapshot.data?.playing??false;
        final completed=snapshot.data?.processingState==ProcessingState.completed;
        return IconButton(padding:EdgeInsets.zero,constraints:const BoxConstraints.tightFor(width:38,height:38),
          onPressed:()async{
            if(completed){await _player.seek(Duration.zero);await _player.play();}
            else if(playing){await _player.pause();}
            else{await _player.play();}
          },icon:Icon(playing?Icons.pause_circle_filled:Icons.play_circle_fill,
            color:Colors.white,size:31));
      }),
    const SizedBox(width:6),
    Expanded(child:Column(mainAxisSize:MainAxisSize.min,children:[
      StreamBuilder<Duration?>(stream:_player.durationStream,builder:(context,durationSnap){
        final duration=durationSnap.data??Duration.zero;
        return StreamBuilder<Duration>(stream:_player.positionStream,builder:(context,positionSnap){
          final position=positionSnap.data??Duration.zero;
          final maxMs=duration.inMilliseconds.clamp(1,1<<30).toDouble();
          final current=position.inMilliseconds.clamp(0,duration.inMilliseconds>0?duration.inMilliseconds:0).toDouble();
          return Column(children:[
            Slider(value:current,min:0,max:maxMs,onChanged:!_ready?null:(value)=>_player.seek(Duration(milliseconds:value.round())),
              activeColor:gold,inactiveColor:Colors.white24),
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              Text(_clock(position),style:const TextStyle(fontSize:9,color:Colors.white70)),
              Text(_clock(duration),style:const TextStyle(fontSize:9,color:Colors.white70)),
            ])
          ]);
        });
      })
    ]))
  ]));
}

class CallHistoryScreen extends StatefulWidget {
  final String? conversationId,peerName;
  const CallHistoryScreen({super.key,this.conversationId,this.peerName});
  @override State<CallHistoryScreen> createState()=>_CallHistoryScreenState();
}
class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final db=Supabase.instance.client;
  late Future<List<Map<String,dynamic>>> calls;
  @override void initState(){super.initState();calls=_load();}
  Future<List<Map<String,dynamic>>> _load() async {
    final me=db.auth.currentUser?.id;
    if(me==null)return [];
    final raw=widget.conversationId!=null
      ?await db.from('cv_call_invites').select('id,conversation_id,caller_id,callee_id,mode,status,created_at,answered_at,ended_at')
        .eq('conversation_id',widget.conversationId!).order('created_at',ascending:false).limit(100)
      :await db.from('cv_call_invites').select('id,conversation_id,caller_id,callee_id,mode,status,created_at,answered_at,ended_at')
        .or('caller_id.eq.$me,callee_id.eq.$me').order('created_at',ascending:false).limit(200);
    final rows=List<Map<String,dynamic>>.from(raw);
    if(widget.conversationId==null&&rows.isNotEmpty){
      final others=rows.map((r)=>r['caller_id']==me?r['callee_id'].toString():r['caller_id'].toString()).toSet().toList();
      final profiles=await db.from('public_profiles').select('id,full_name,username').inFilter('id',others);
      final names={for(final p in List<Map<String,dynamic>>.from(profiles))
        p['id'].toString():(p['full_name']??p['username']??'CreatorVerse member').toString()};
      for(final row in rows){
        final other=row['caller_id']==me?row['callee_id'].toString():row['caller_id'].toString();
        row['peer_name']=names[other]??'CreatorVerse member';
      }
    }
    return rows;
  }
  String _label(Map<String,dynamic> row,String me) {
    final status=(row['status']??'').toString(),incoming=row['callee_id']==me;
    if(status=='missed')return incoming?'Missed call':'No answer';
    if(status=='declined')return incoming?'You declined':'Declined';
    if(status=='cancelled')return 'Call cancelled';
    if(status=='accepted')return incoming?'Incoming call answered':'Outgoing call answered';
    if(status=='ended')return 'Call ended';
    return incoming?'Incoming call':'Outgoing call';
  }
  Future<void> _callBack(Map<String,dynamic> row) async {
    final me=db.auth.currentUser?.id;if(me==null)return;
    final recipient=row['caller_id']==me?row['callee_id'].toString():row['caller_id'].toString();
    final conversationId=(widget.conversationId??row['conversation_id']??'').toString();
    if(conversationId.isEmpty)return;
    final peerName=(widget.peerName??row['peer_name']??'CreatorVerse member').toString();
    try{
      final created=await db.rpc('cv_create_call_invite',params:{
        'p_conversation_id':conversationId,'p_callee_id':recipient,
        'p_mode':row['mode']=='video'?'video':'audio'
      });
      if(!mounted)return;
      await material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CreatorVerseCallScreen(
        conversationId:conversationId,callId:created.toString(),peerName:peerName,
        mode:row['mode']=='video'?'video':'audio',isCaller:true)));
      if(mounted)setState(()=>calls=_load());
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not call back: $e')));
    }
  }
  @override Widget build(BuildContext context) {
    final me=db.auth.currentUser?.id??'';
    return Scaffold(appBar:AppBar(title:Text(widget.conversationId==null?'Calls':'Call history')),
      body:FutureBuilder<List<Map<String,dynamic>>>(future:calls,builder:(context,snapshot){
        if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
        if(snapshot.hasError)return Center(child:Text('Could not load call history: ${snapshot.error}'));
        final rows=snapshot.data??[];
        if(rows.isEmpty)return const Center(child:Text('No calls yet.',style:TextStyle(color:muted)));
        return RefreshIndicator(onRefresh:()async{setState(()=>calls=_load());await calls;},
          child:ListView.separated(itemCount:rows.length,padding:const EdgeInsets.all(12),
            separatorBuilder:(_,__)=>const Divider(color:Colors.white10),
            itemBuilder:(context,index){
              final row=rows[index],status=(row['status']??'').toString();
              final incoming=row['callee_id']==me,missed=status=='missed';
              final date=DateTime.tryParse((row['created_at']??'').toString())?.toLocal();
              final when=date==null?'':'${date.day}/${date.month}/${date.year} · ${TimeOfDay.fromDateTime(date).format(context)}';
              final peer=(row['peer_name']??widget.peerName??'').toString();
              return ListTile(
                leading:CircleAvatar(backgroundColor:(missed?Colors.redAccent:emerald).withValues(alpha:.14),
                  child:Icon(missed?Icons.call_missed:incoming?Icons.call_received:Icons.call_made,color:missed?Colors.redAccent:emerald)),
                title:Text(widget.conversationId==null?'${_label(row,me)} · $peer':_label(row,me),
                  style:TextStyle(fontWeight:FontWeight.w700,color:missed?Colors.redAccent:null)),
                subtitle:Text('${row['mode']=='video'?'Video':'Audio'} call · ${incoming?'Incoming':'Outgoing'} · $when',
                  style:const TextStyle(color:muted,fontSize:11)),
                trailing:IconButton(tooltip:'Call back',onPressed:()=>_callBack(row),icon:const Icon(Icons.call,color:emerald)),
              );
            }));
      }));
  }
}

class CreatorVerseCallScreen extends StatefulWidget{
  final String conversationId,callId,peerName,mode;
  final bool isCaller;
  const CreatorVerseCallScreen({super.key,required this.conversationId,required this.callId,required this.peerName,required this.mode,required this.isCaller});
  @override State<CreatorVerseCallScreen> createState()=>_CreatorVerseCallScreenState();
}
class _CreatorVerseCallScreenState extends State<CreatorVerseCallScreen> with SingleTickerProviderStateMixin{
  final db=Supabase.instance.client;
  late final Room _room;
  bool _connecting=true,_muted=false,_cameraEnabled=false,_speakerEnabled=true,_ending=false;
  String? _error,_callStatus;
  RealtimeChannel? _callStatusChannel;
  late final AnimationController _ringController;
  @override void initState(){
    super.initState();
    _ringController=AnimationController(vsync:this,duration:const Duration(milliseconds:1700))..repeat();
    _room=Room(roomOptions:const RoomOptions(adaptiveStream:true,dynacast:true));
    _room.addListener(_onRoomChanged);
    _callStatusChannel=db.channel('cv-call-status-${widget.callId}')
      .onPostgresChanges(event:PostgresChangeEvent.update,schema:'public',table:'cv_call_invites',
        filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'id',value:widget.callId),
        callback:(payload){
          final status=(payload.newRecord['status']??'').toString();
          if(mounted)setState(()=>_callStatus=status);
        }).subscribe();
    _loadCallStatus();
    _connect();
  }
  void _onRoomChanged(){if(mounted)setState((){});}
  Future<void> _loadCallStatus() async{
    try{final row=await db.from('cv_call_invites').select('status').eq('id',widget.callId).single();
      if(mounted)setState(()=>_callStatus=(row['status']??'').toString());}catch(_){}
  }
  Future<void> _connect() async{
    try{
      final mic=await Permission.microphone.request();
      if(!mic.isGranted)throw Exception('Microphone permission is required for calls.');
      if(widget.mode=='video'){
        final camera=await Permission.camera.request();
        if(!camera.isGranted)throw Exception('Camera permission is required for video calls.');
      }
      final response=await db.functions.invoke('livekit-token',body:{
        'conversation_id':widget.conversationId,'call_id':widget.callId,'mode':widget.mode
      });
      if(response.status<200||response.status>=300)throw Exception('Call server returned status ${response.status}.');
      final data=Map<String,dynamic>.from(response.data as Map);
      final url=(data['url']??'').toString(),token=(data['token']??'').toString();
      if(url.isEmpty||token.isEmpty)throw Exception('Call server did not return connection credentials.');
      await _room.connect(url,token);
      await _room.localParticipant?.setMicrophoneEnabled(true);
      if(widget.mode=='video'){
        await _room.localParticipant?.setCameraEnabled(true);
        _cameraEnabled=true;
      }
      await AudioManager.instance.setSpeakerOutputPreferred(true);
      if(mounted)setState(()=>_connecting=false);
    }catch(e){
      if(mounted)setState(()=>_error=e.toString());
    }
  }
  Future<void> _toggleMicrophone() async{
    final next=!_muted;
    try{await _room.localParticipant?.setMicrophoneEnabled(!next);if(mounted)setState(()=>_muted=next);}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Microphone control failed: $e')));}
  }
  Future<void> _toggleCamera() async{
    final next=!_cameraEnabled;
    try{await _room.localParticipant?.setCameraEnabled(next);if(mounted)setState(()=>_cameraEnabled=next);}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Camera control failed: $e')));}
  }
  Future<void> _toggleSpeaker() async{
    final next=!_speakerEnabled;
    try{await AudioManager.instance.setSpeakerOutputPreferred(next);if(mounted)setState(()=>_speakerEnabled=next);}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Audio output could not be changed: $e')));}
  }
  VideoTrack? _remoteVideoTrack(){
    for(final participant in _room.remoteParticipants.values){
      for(final publication in participant.videoTrackPublications){
        final track=publication.track;
        if(publication.subscribed&&!publication.muted&&track is VideoTrack)return track;
      }
    }
    return null;
  }
  VideoTrack? _localVideoTrack(){
    for(final publication in _room.localParticipant?.videoTrackPublications??[]){
      final track=publication.track;
      if(!publication.muted&&track is VideoTrack)return track;
    }
    return null;
  }
  Future<void> _endCall() async{
    if(_ending)return;
    _ending=true;
    try{
      if(!['declined','cancelled','ended','missed'].contains(_callStatus??'')){
        final status=widget.isCaller&&_callStatus!='accepted'&&_room.remoteParticipants.isEmpty?'cancelled':'ended';
        await db.rpc('cv_set_call_invite_status',params:{
          'p_call_id':widget.callId,'p_status':status
        });
      }
    }catch(_){}
    try{await _room.disconnect();}catch(_){}
    if(mounted)material_widgets_ui.Navigator.pop(context);
  }
  Future<void> _disposeLiveKitRoom() async{await _room.dispose();}
  @override void dispose(){
    _ringController.dispose();
    _room.removeListener(_onRoomChanged);
    final statusChannel=_callStatusChannel;if(statusChannel!=null)unawaited(statusChannel.unsubscribe());
    unawaited(_disposeLiveKitRoom());
    super.dispose();
  }
  @override Widget build(BuildContext context){
    final remote=_remoteVideoTrack();
    final local=_localVideoTrack();
    final participantCount=_room.remoteParticipants.length;
    return Scaffold(
      backgroundColor:const Color(0xFF06130C),
      appBar:AppBar(title:Text(widget.mode=='video'?'Video call':'Audio call')),
      body:SafeArea(child:Stack(children:[
        Positioned.fill(child:widget.mode=='video'&&remote!=null
          ?VideoTrackRenderer(remote,fit:VideoViewFit.cover)
          :Container(color:const Color(0xFF102329),child:Center(child:Column(
            mainAxisSize:MainAxisSize.min,children:[
              SizedBox(width:176,height:176,child:AnimatedBuilder(
                animation:_ringController,
                builder:(context,child){
                  final phase=_ringController.value;
                  return Stack(alignment:Alignment.center,children:[
                    for(var ring=0;ring<2;ring++)
                      Opacity(opacity:(1-((phase+ring*.5)%1)).clamp(0.0,1.0).toDouble(),
                        child:Transform.scale(scale:(1+(((phase+ring*.5)%1)*.48)).toDouble(),
                          child:Container(width:112,height:112,decoration:BoxDecoration(
                            shape:BoxShape.circle,border:Border.all(
                              color:emerald.withValues(alpha:.45),width:1.5))))),
                    Container(width:108,height:108,decoration:BoxDecoration(
                      shape:BoxShape.circle,color:emerald.withValues(alpha:.16),
                      border:Border.all(color:emerald.withValues(alpha:.55),width:1.5)),
                      child:const Icon(Icons.person,color:emerald,size:56)),
                  ]);
                })),
              const SizedBox(height:18),
              Text(widget.peerName,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800)),
              const SizedBox(height:8),
              Text(_error??(_callStatus=='declined'?'Call declined':_callStatus=='cancelled'?'Call cancelled':_callStatus=='ended'?'Call ended':_callStatus=='missed'?'Missed call':_connecting?'Connecting securely…':participantCount==0?'Calling… waiting for answer':'Connected'),
                style:const TextStyle(color:muted)),
              if(_error!=null)Padding(padding:const EdgeInsets.all(20),child:Text(
                'Check that LiveKit is configured for CreatorVerse and try again.',
                textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:12))),
            ])))),
        if(widget.mode=='video'&&local!=null)Positioned(right:16,top:16,width:112,height:160,
          child:ClipRRect(borderRadius:BorderRadius.circular(16),
            child:VideoTrackRenderer(local,fit:VideoViewFit.cover))),
        if(_connecting)const Positioned(top:24,left:0,right:0,
          child:Center(child:Text('Connecting securely…',style:TextStyle(color:Colors.white70,fontSize:12)))),
        Positioned(left:0,right:0,bottom:28,child:Row(
          mainAxisAlignment:MainAxisAlignment.center,children:[
            _callControl(_muted?Icons.mic_off:Icons.mic,_muted?'Unmute':'Mute',_toggleMicrophone),
            const SizedBox(width:18),
            _callControl(_speakerEnabled?Icons.volume_up:Icons.hearing,_speakerEnabled?'Speaker':'Earpiece',_toggleSpeaker),
            if(widget.mode=='video')...[
              const SizedBox(width:18),
              _callControl(_cameraEnabled?Icons.videocam:Icons.videocam_off,'Camera',_toggleCamera),
            ],
            const SizedBox(width:18),
            _callControl(Icons.call_end,'End call',_endCall,color:Colors.redAccent),
          ])),
      ])));
  }
  Widget _callControl(IconData icon,String label,VoidCallback action,{Color color=panel})=>
    Column(mainAxisSize:MainAxisSize.min,children:[
      Material(color:color,shape:const CircleBorder(),child:IconButton(
        onPressed:action,color:Colors.white,icon:Icon(icon))),
      const SizedBox(height:5),Text(label,style:const TextStyle(color:Colors.white70,fontSize:10))
    ]);
}

class AdminWorkspaceScreen extends StatefulWidget {
  const AdminWorkspaceScreen({super.key});
  @override
  State<AdminWorkspaceScreen> createState() => _AdminWorkspaceScreenState();
}

class _AdminWorkspaceScreenState extends State<AdminWorkspaceScreen> {
  final db = Supabase.instance.client;
  late Future<Map<String, dynamic>> overview;

  @override
  void initState() {
    super.initState();
    overview = loadOverview();
  }

  Future<Map<String, dynamic>> loadOverview() async {
    final user = db.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to access the admin workspace.');
    }
    final ownProfile = await db.from('profiles').select('role')
      .eq('id', user.id).single();
    final role = (ownProfile['role'] ?? '').toString();
    if (role != 'admin' && role != 'super_admin') {
      throw StateError('This account does not have administrator access.');
    }
    final users = await db.from('profiles').select('id').count(CountOption.exact);
    final courses = await db.from('courses').select('id')
      .eq('published', true).count(CountOption.exact);
    final pendingPayments = await db.from('payment_orders').select('id')
      .eq('status', 'pending').count(CountOption.exact);
    final applications = await db.from('academy_applications').select('id')
      .count(CountOption.exact);
    final orders = await db.from('payment_orders')
      .select('id,user_id,amount_ngn,status,reference,created_at,transfer_reference,courses(title)')
      .order('created_at', ascending: false).limit(8);
    final admissions = await db.from('academy_applications')
      .select('id,application_no,first_name,last_name,application_type,status,submitted_at')
      .order('submitted_at', ascending: false).limit(8);
    return {
      'users': users.count,
      'courses': courses.count,
      'pending_payments': pendingPayments.count,
      'applications': applications.count,
      'orders': List<Map<String, dynamic>>.from(orders),
      'admissions': List<Map<String, dynamic>>.from(admissions),
      'role': role,
    };
  }

  Future<void> refresh() async {
    final next = loadOverview();
    setState(() => overview = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: overview,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: emerald));
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: material_widgets_ui.Column(
          mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.admin_panel_settings_outlined, color: gold, size: 42),
            const SizedBox(height: 12),
            const Text('Admin workspace unavailable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: muted)),
            const SizedBox(height: 14),
            OutlinedButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh), label: const Text('Try again')),
          ])));
      }
      final data = snapshot.data ?? {};
      final orders = data['orders'] as List<Map<String, dynamic>>? ?? [];
      final admissions = data['admissions'] as List<Map<String, dynamic>>? ?? [];
      Widget metric(String label, dynamic value, IconData icon) => Expanded(child: Card(
        color: panel, child: Padding(padding: const EdgeInsets.all(14), child: material_widgets_ui.Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: emerald), const SizedBox(height: 10),
            Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: muted, fontSize: 11)),
          ]))));
      return RefreshIndicator(color: emerald, onRefresh: refresh, child: ListView(
        padding: const EdgeInsets.all(18), children: [
          Row(children: [
            const Expanded(child: Text('Operations overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            Chip(label: Text((data['role'] ?? 'admin').toString().toUpperCase())),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            metric('Members', data['users'], Icons.people_outline),
            const SizedBox(width: 8), metric('Published courses', data['courses'], Icons.menu_book_outlined),
          ]),
          Row(children: [
            metric('Pending payments', data['pending_payments'], Icons.payments_outlined),
            const SizedBox(width: 8), metric('Applications', data['applications'], Icons.assignment_outlined),
          ]),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Payment review')), body: const AdminPaymentReviewScreen()))),
            icon: const Icon(Icons.fact_check_outlined), label: const Text('Review payment requests'),
            style: FilledButton.styleFrom(backgroundColor: emerald, minimumSize: const Size.fromHeight(46))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceAdminScreen())),
            icon: const Icon(Icons.store_mall_directory_outlined), label: const Text('Manage Marketplace')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseAdminScreen())),
            icon: const Icon(Icons.menu_book_outlined), label: const Text('Manage Courses & Lessons')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCreatorApplicationsScreen())),
            icon: const Icon(Icons.assignment_ind_outlined), label: const Text('Review Creator Applications')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCertificatesScreen())),
            icon: const Icon(Icons.workspace_premium_outlined), label: const Text('Approve Certificates')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityModerationScreen())),
            icon: const Icon(Icons.flag_outlined), label: const Text('Moderate Community reports')),
          const SizedBox(height: 22),
          const Text('Recent payment orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (orders.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No payment orders found.', style: TextStyle(color: muted))),
          for (final order in orders) Card(color: panel, child: ListTile(
            title: Text((order['courses'] is Map ? order['courses']['title'] : null) ?? 'Course payment'),
            subtitle: Text('${order['reference']} · ${order['status']}',
              style: const TextStyle(color: muted, fontSize: 12)),
            trailing: Text('₦${order['amount_ngn']}', style: const TextStyle(color: gold, fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 22),
          const Text('Recent applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (admissions.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No applications found.', style: TextStyle(color: muted))),
          for (final application in admissions) Card(color: panel, child: ListTile(
            title: Text('${application['first_name'] ?? ''} ${application['last_name'] ?? ''}'.trim()),
            subtitle: Text('${application['application_no'] ?? ''} · ${application['application_type'] ?? ''}',
              style: const TextStyle(color: muted, fontSize: 12)),
            trailing: Text((application['status'] ?? 'unknown').toString(),
              style: const TextStyle(color: gold, fontSize: 11)),
          )),
        ]));
    });
}

Future<void> openAcademyWebPage(BuildContext context,String path,{bool requiresMedia=true}) async {
  if(requiresMedia){
    final statuses=await [Permission.camera,Permission.microphone].request();
    if(!statuses.values.every((status)=>status.isGranted)){
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Camera and microphone permissions are needed for this interview room.')));
      return;
    }
  }
  if(!context.mounted)return;
  material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>AuthenticatedAcademyWebScreen(path:path)));
}

class AuthenticatedAcademyWebScreen extends StatefulWidget {
  final String path;
  const AuthenticatedAcademyWebScreen({super.key,required this.path});
  @override State<AuthenticatedAcademyWebScreen> createState()=>_AuthenticatedAcademyWebScreenState();
}
class _AuthenticatedAcademyWebScreenState extends State<AuthenticatedAcademyWebScreen>{
  InAppWebViewController? controller;
  bool injected=false,closing=false,pageReady=false;
  String? loadError;
  static const sessionKey='sb-xgdngnekihhnkzurhvpe-auth-token';
  static const origin='https://creatorverse-ai.vercel.app';
  String get targetUrl {
    final uri = Uri.parse('$origin${widget.path}');
    // Native WebView pages use the Flutter loading/error surface. Suppress
    // the website's second full-screen loader to prevent a second flash.
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'cv_native': '1',
    }).toString();
  }
  String get pageTitle=>widget.path.contains('admin.html')?'CreatorVerse Admin Portal':widget.path.contains('live-room')?'Live interview room':widget.path.contains('interviewer')?'Interview workspace':'Recorded interview response';
  Future<void> injectSessionAndOpen() async {
    if(injected||controller==null)return;
    final session=Supabase.instance.client.auth.currentSession;
    if(session==null){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Your CreatorVerse session has expired. Sign in again.')));
      return;
    }
    final sessionJson=jsonEncode(session.toJson());
    final script="localStorage.setItem('$sessionKey', ${jsonEncode(sessionJson)});";
    await controller!.evaluateJavascript(source:script);
    injected=true;
    await controller!.loadUrl(urlRequest:URLRequest(url:WebUri(targetUrl)));
  }
  Future<void> closeRoom() async {
    if(closing)return;closing=true;
    try{await controller?.evaluateJavascript(source:"localStorage.removeItem('$sessionKey');");}catch(_){}
    if(mounted)material_widgets_ui.Navigator.of(context).pop();
  }
  Future<void> retryPageLoad() async {
    if(!mounted)return;
    setState((){loadError=null;pageReady=false;injected=false;});
    try{await controller?.loadUrl(urlRequest:URLRequest(url:WebUri('$origin/certificate.html')));}
    catch(e){if(mounted)setState(()=>loadError='Could not start the page: $e');}
  }
  @override Widget build(BuildContext context)=>PopScope(
    canPop:false,
    onPopInvokedWithResult:(didPop,result){if(!didPop)closeRoom();},
    child:Stack(fit:StackFit.expand,children:[
      Scaffold(appBar:AppBar(title:Text(pageTitle),leading:IconButton(onPressed:closeRoom,icon:const Icon(Icons.arrow_back))),
        body:InAppWebView(
          initialUrlRequest:URLRequest(url:WebUri('$origin/certificate.html')),
          initialSettings:InAppWebViewSettings(
            javaScriptEnabled:true,domStorageEnabled:true,mediaPlaybackRequiresUserGesture:false,
            allowsInlineMediaPlayback:true,supportZoom:false,thirdPartyCookiesEnabled:true,
          ),
          onWebViewCreated:(webController)=>controller=webController,
          onLoadStop:(webController,url) async {
            if(url?.host=='creatorverse-ai.vercel.app'&&url?.path=='/certificate.html'){
              try{await injectSessionAndOpen();}
              catch(e){if(mounted)setState(()=>loadError='Could not open the secure page: $e');}
              return;
            }
            if(url?.host=='creatorverse-ai.vercel.app'&&mounted){
              setState(()=>pageReady=true);
            }
          },
          onReceivedError:(webController,request,error) {
            if(request.isForMainFrame==true&&mounted){
              setState(()=>loadError='The page could not be loaded. Check your connection and try again.');
            }
          },
          onPermissionRequest:(webController,request) async {
            final allowed=request.resources.where((resource)=>resource==PermissionResourceType.CAMERA||resource==PermissionResourceType.MICROPHONE).toList();
            if(allowed.length!=request.resources.length){
              return PermissionResponse(resources:allowed,action:PermissionResponseAction.DENY);
            }
            return PermissionResponse(resources:allowed,action:PermissionResponseAction.GRANT);
          },
        )),
      if(!pageReady)
        Positioned.fill(child:loadError==null
          ? const _CreatorVerseLoadingGate()
          : Scaffold(backgroundColor:ink,body:Center(child:Padding(
              padding:const EdgeInsets.all(28),
              child:Column(mainAxisSize:MainAxisSize.min,children:[
                SvgPicture.asset('assets/creatorverse-brand.svg',width:82,height:82),
                const SizedBox(height:20),
                const Text('Unable to load this page',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
                const SizedBox(height:10),
                Text(loadError!,textAlign:TextAlign.center,style:const TextStyle(color:muted,height:1.5)),
                const SizedBox(height:20),
                FilledButton.icon(onPressed:retryPageLoad,icon:const Icon(Icons.refresh),label:const Text('Try again'),
                  style:FilledButton.styleFrom(backgroundColor:emerald)),
              ]),
            )))),
    ]),
  );
}

class MyAcademyApplicationsScreen extends StatefulWidget {
  const MyAcademyApplicationsScreen({super.key});
  @override State<MyAcademyApplicationsScreen> createState()=>_MyAcademyApplicationsScreenState();
}
class _MyAcademyApplicationsScreenState extends State<MyAcademyApplicationsScreen>{
  final db=Supabase.instance.client;late Future<Map<String,dynamic>> data;
  bool busy=false;
  @override void initState(){super.initState();data=load();}
  Future<Map<String,dynamic>> load() async {
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in to continue.');
    final applications=await db.from('academy_applications').select('id,application_no,application_type,status,first_name,last_name,specialty,proposed_level,submitted_at,decision_reason,created_at')
      .eq('user_id',user.id).order('created_at',ascending:false);
    final offers=await db.from('academy_admission_offers').select('id,application_id,course_id,status,issued_at,expires_at,offer_message')
      .eq('user_id',user.id).order('created_at',ascending:false);
    final invitations=await db.from('academy_interview_invitations').select('id,interview_id,application_id,interview_type,status,starts_at,ends_at,timezone,learner_instructions,meeting_join_url,response_due_at')
      .eq('user_id',user.id).not('published_at','is',null).order('starts_at',ascending:false);
    return {'applications':List<Map<String,dynamic>>.from(applications),'offers':List<Map<String,dynamic>>.from(offers),'invitations':List<Map<String,dynamic>>.from(invitations)};
  }
  Future<void> refresh() async {final next=load();setState(()=>data=next);await next;}
  Future<void> createApplication() async {
    final first=TextEditingController(text:(db.auth.currentUser?.userMetadata?['first_name']??'').toString());
    final last=TextEditingController(text:(db.auth.currentUser?.userMetadata?['last_name']??'').toString());
    final phone=TextEditingController(),country=TextEditingController(text:'Nigeria'),region=TextEditingController();
    final education=TextEditingController(),occupation=TextEditingController(),experience=TextEditingController();
    final portfolio=TextEditingController(),motivation=TextEditingController(),goals=TextEditingController();
    final certificate=TextEditingController(),specialty=TextEditingController(),work=TextEditingController();
    String type='creator',level='Beginner';bool consent=false;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(
      backgroundColor:panel,title:const Text('Creator & Instructor application'),
      content:SizedBox(width:460,child:SingleChildScrollView(child:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('This pathway is for people applying to create, teach, instruct or exhibit work on CreatorVerse. Ordinary course learners should enrol or pay through the course catalogue instead.',style:TextStyle(color:muted,height:1.45,fontSize:12)),
        const SizedBox(height:12),DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'Application pathway'),
          items:const [DropdownMenuItem(value:'creator',child:Text('Creator')),DropdownMenuItem(value:'instructor',child:Text('Instructor')),DropdownMenuItem(value:'teacher',child:Text('Teacher')),DropdownMenuItem(value:'exhibitor',child:Text('Exhibitor / showcase applicant'))],
          onChanged:(v)=>setDialog(()=>type=v??type)),
        const SizedBox(height:8),TextField(controller:first,decoration:const InputDecoration(labelText:'First name')),
        const SizedBox(height:8),TextField(controller:last,decoration:const InputDecoration(labelText:'Last name')),
        const SizedBox(height:8),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone number')),
        const SizedBox(height:8),TextField(controller:country,decoration:const InputDecoration(labelText:'Country')),
        const SizedBox(height:8),TextField(controller:region,decoration:const InputDecoration(labelText:'State / region')),
        const SizedBox(height:8),TextField(controller:education,decoration:const InputDecoration(labelText:'Highest education (optional)')),
        const SizedBox(height:8),TextField(controller:occupation,decoration:const InputDecoration(labelText:'Current role / occupation')),
        const SizedBox(height:8),TextField(controller:specialty,decoration:const InputDecoration(labelText:'Specialty / area of contribution')),
        const SizedBox(height:8),DropdownButtonFormField<String>(value:level,decoration:const InputDecoration(labelText:'Your proposed experience level'),
          items:const [DropdownMenuItem(value:'Beginner',child:Text('Beginner')),DropdownMenuItem(value:'Foundation',child:Text('Foundation')),DropdownMenuItem(value:'Intermediate',child:Text('Intermediate')),DropdownMenuItem(value:'Advanced',child:Text('Advanced')),DropdownMenuItem(value:'Professional',child:Text('Professional'))],
          onChanged:(v)=>setDialog(()=>level=v??level)),
        const SizedBox(height:8),TextField(controller:experience,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Relevant experience')),
        const SizedBox(height:8),TextField(controller:portfolio,decoration:const InputDecoration(labelText:'Portfolio URL (optional)')),
        const SizedBox(height:8),TextField(controller:work,minLines:2,maxLines:3,decoration:const InputDecoration(labelText:'Work sample links (optional)')),
        const SizedBox(height:8),TextField(controller:motivation,minLines:3,maxLines:5,decoration:const InputDecoration(labelText:'Why do you want to join CreatorVerse?')),
        const SizedBox(height:8),TextField(controller:goals,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'What will you contribute or teach?')),
        const SizedBox(height:8),TextField(controller:certificate,decoration:const InputDecoration(labelText:'Preferred name for future certificate')),
        const SizedBox(height:12),CheckboxListTile(value:consent,activeColor:emerald,contentPadding:EdgeInsets.zero,
          onChanged:(v)=>setDialog(()=>consent=v==true),
          title:const Text('I consent to CreatorVerse using the information in this application to assess my creator, instructor, teacher or exhibitor application.',style:TextStyle(fontSize:12,height:1.4))),
      ]))),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:consent?()=>material_widgets_ui.Navigator.pop(ctx,true):null,child:const Text('Submit application'))])));
    if(!mounted){
      for(final x in [first,last,phone,country,region,education,occupation,experience,portfolio,motivation,goals,certificate,specialty,work]){x.dispose();}
      return;
    }
    final values={
      'first_name':first.text.trim(),'last_name':last.text.trim(),'phone':phone.text.trim(),'country':country.text.trim(),
      'region':region.text.trim(),'education_level':education.text.trim(),'occupation':occupation.text.trim(),
      'prior_experience':experience.text.trim(),'portfolio_url':portfolio.text.trim(),'motivation':motivation.text.trim(),
      'learning_goals':goals.text.trim(),'certificate_name':certificate.text.trim(),'specialty':specialty.text.trim(),
      'work_sample_urls':work.text.trim(),
    };
    for(final x in [first,last,phone,country,region,education,occupation,experience,portfolio,motivation,goals,certificate,specialty,work]){x.dispose();}
    if(ok!=true)return;
    if(values['first_name']!.length<2||values['last_name']!.length<2||values['motivation']!.length<20||values['learning_goals']!.length<10){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please complete your name, motivation and contribution details.')));return;
    }
    setState(()=>busy=true);
    try{
      final course=await db.from('courses').select('id').eq('slug','creator-partner-application').eq('published',false).single();
      final now=DateTime.now().toUtc().toIso8601String();
      final inserted=await db.from('academy_applications').insert({
        'user_id':db.auth.currentUser!.id,'course_id':course['id'],'application_type':type,
        'status':'draft','proposed_level':level,'consented_at':now,'privacy_version':'creatorverse-academy-partner-privacy-v1',
        for(final entry in values.entries) entry.key:entry.value.isEmpty?null:entry.value,
      }).select('id').single();
      await db.from('academy_applications').update({'status':'submitted','submitted_at':now,'updated_at':now}).eq('id',inserted['id']);
      try{await db.from('academy_application_events').insert({'application_id':inserted['id'],'actor_id':db.auth.currentUser!.id,'event_type':'submitted','from_status':'draft','to_status':'submitted','message':'Application submitted from the CreatorVerse mobile app.'});}catch(_){}
      await refresh();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Application submitted. The CreatorVerse team will review it and contact you through notifications.')));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not submit application: $e')));
    }finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> submitDraft(Map<String,dynamic> app) async {
    setState(()=>busy=true);
    try{
      final now=DateTime.now().toUtc().toIso8601String();
      await db.from('academy_applications').update({'status':'submitted','submitted_at':now,'updated_at':now}).eq('id',app['id']);
      await db.from('academy_application_events').insert({'application_id':app['id'],'actor_id':db.auth.currentUser!.id,
        'event_type':'submitted','from_status':'draft','to_status':'submitted','message':'Application submitted from the CreatorVerse mobile app.'});
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not submit draft: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> respondToInvitation(Map<String,dynamic> invitation,String response) async {
    setState(()=>busy=true);
    try{await db.rpc('respond_to_academy_interview_invitation',params:{'p_invitation_id':invitation['id'],'p_response':response});await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update interview invitation: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> acceptOffer(Map<String,dynamic> offer) async {
    setState(()=>busy=true);
    try{
      final result=await db.rpc('accept_academy_admission_offer',params:{'p_offer_id':offer['id']});
      await refresh();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text((result is Map?result['message']:'Admission response recorded.').toString())));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not accept offer: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Creator & Instructor Pathway'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<Map<String,dynamic>>(future:data,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Padding(padding:const EdgeInsets.all(20),child:Text('Academy application data unavailable: ${snap.error}',textAlign:TextAlign.center,style:const TextStyle(color:muted))));
      final d=snap.data??{};final applications=d['applications'] as List<Map<String,dynamic>>? ?? [];
      final offers=d['offers'] as List<Map<String,dynamic>>? ?? [];final invitations=d['invitations'] as List<Map<String,dynamic>>? ?? [];
      return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(18),children:[
        const Text('CreatorVerse Academy',style:TextStyle(fontSize:23,fontWeight:FontWeight.w800)),
        const SizedBox(height:6),const Text('This application is only for creators, instructors, teachers and exhibitors. It is separate from ordinary paid course enrolment.',style:TextStyle(color:muted,height:1.5)),
        const SizedBox(height:14),
        if(applications.isEmpty)FilledButton.icon(onPressed:busy?null:createApplication,style:FilledButton.styleFrom(backgroundColor:emerald),icon:const Icon(Icons.assignment_outlined),label:const Text('Start creator / instructor application')),
        if(applications.isNotEmpty)...[
          const Text('Your application',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
          for(final app in applications)Card(color:panel,child:ListTile(
            leading:const Icon(Icons.assignment_turned_in_outlined,color:emerald),
            title:Text((app['application_no']??'Application').toString()),
            subtitle:Text('${app['application_type']} · ${app['status'].toString().replaceAll('_',' ')}\n${app['decision_reason']??'Your application is being handled by the Academy team.'}',style:const TextStyle(color:muted,height:1.5)),
            trailing:app['status']=='draft'?TextButton(onPressed:busy?null:()=>submitDraft(app),child:const Text('Submit draft')):const Icon(Icons.lock_outline,color:muted),
          )),
        ],
        if(offers.isNotEmpty)...[
          const SizedBox(height:18),const Text('Admission offers',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
          for(final offer in offers)Card(color:panel,child:Padding(padding:const EdgeInsets.all(14),child:material_widgets_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Offer · ${offer['status']}',style:const TextStyle(fontWeight:FontWeight.w800)),
            if((offer['offer_message']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(offer['offer_message'].toString(),style:const TextStyle(color:muted,height:1.5))),
            Text('Expires: ${offer['expires_at']}',style:const TextStyle(color:muted,fontSize:11)),
            if(offer['status']=='offered')FilledButton(onPressed:busy?null:()=>acceptOffer(offer),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('Accept admission offer')),
          ]))),
        ],
        if(invitations.isNotEmpty)...[
          const SizedBox(height:18),const Text('Interview invitations',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
          for(final inv in invitations)Card(color:panel,child:Padding(padding:const EdgeInsets.all(14),child:material_widgets_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((inv['interview_type']??'Interview').toString().replaceAll('_',' ').toUpperCase(),style:const TextStyle(fontWeight:FontWeight.w800,color:gold)),
            const SizedBox(height:6),Text('${inv['starts_at']} · ${inv['timezone']}',style:const TextStyle(color:muted,fontSize:12)),
            if((inv['learner_instructions']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(inv['learner_instructions'].toString(),style:const TextStyle(height:1.5))),
            Text('Status: ${inv['status']}',style:const TextStyle(color:muted)),
            if(['scheduled','confirmed'].contains(inv['status']))Wrap(spacing:8,children:[
              OutlinedButton(onPressed:busy?null:()=>respondToInvitation(inv,'reschedule_requested'),child:const Text('Request reschedule')),
              if(inv['status']=='scheduled')FilledButton(onPressed:busy?null:()=>respondToInvitation(inv,'confirmed'),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('Confirm attendance')),
            ]),
            if(inv['interview_type']=='live')FilledButton.icon(onPressed:busy?null:()=>openAcademyWebPage(context,'/academy-live-room.html?interview=${inv['interview_id']}'),
              style:FilledButton.styleFrom(backgroundColor:emerald),icon:const Icon(Icons.video_call_outlined),label:const Text('Join secure in-app interview room')),
            if(['recorded_video','recorded_audio'].contains(inv['interview_type']))OutlinedButton.icon(onPressed:busy?null:()=>openAcademyWebPage(context,'/academy-interview.html?interview=${inv['interview_id']}'),
              icon:const Icon(Icons.mic_outlined),label:const Text('Open in-app response studio')),
            if((inv['meeting_join_url']??'').toString().startsWith('https://')&&inv['interview_type']!='live')TextButton(onPressed:()=>launchUrl(Uri.parse(inv['meeting_join_url'].toString()),mode:LaunchMode.externalApplication),child:const Text('Open additional meeting link')),
          ]))),
        ],
        if(applications.isEmpty&&offers.isEmpty&&invitations.isEmpty)const Padding(padding:EdgeInsets.symmetric(vertical:22),child:Text('No applications or invitations yet. Ordinary course learners can continue directly through Learn.',style:TextStyle(color:muted,height:1.5))),
      ]));
    }));
}

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});
  @override State<MyCertificatesScreen> createState()=>_MyCertificatesScreenState();
}
class _MyCertificatesScreenState extends State<MyCertificatesScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> certificates;
  @override void initState(){super.initState();certificates=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in first.');
    final rows=await db.from('certificates').select('id,certificate_no,student_name,course_title,issued_at,revoked')
      .eq('user_id',user.id).order('issued_at',ascending:false);
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> refresh() async {final next=load();setState(()=>certificates=next);await next;}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('My certificates'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:certificates,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Certificates unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final items=snap.data??[];
      if(items.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No certificates have been issued to your account yet. Course completion and certificate approval are reviewed by CreatorVerse Academy administrators.',textAlign:TextAlign.center,style:TextStyle(color:muted,height:1.5))));
      return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(16),children:[
        for(final item in items)Card(color:panel,child:ListTile(
          leading:Icon(item['revoked']==true?Icons.cancel_outlined:Icons.workspace_premium_outlined,color:item['revoked']==true?Colors.red:gold,size:30),
          title:Text((item['course_title']??'Course certificate').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
          subtitle:Text('${item['certificate_no']}\nIssued: ${item['issued_at']}\n${item['revoked']==true?'Revoked':'Verified record'}',style:const TextStyle(color:muted,height:1.5)),
          onTap:item['revoked']==true?null:()=>launchUrl(Uri.parse('https://creatorverse-ai.vercel.app/certificate.html?n=${Uri.encodeComponent(item['certificate_no'].toString())}'),mode:LaunchMode.externalApplication),
        )),
      ]));
    }));
}

class AdminCertificatesScreen extends StatefulWidget {
  const AdminCertificatesScreen({super.key});
  @override State<AdminCertificatesScreen> createState()=>_AdminCertificatesScreenState();
}
class _AdminCertificatesScreenState extends State<AdminCertificatesScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> enrolments;bool busy=false;
  @override void initState(){super.initState();enrolments=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in first.');
    final p=await db.from('profiles').select('role').eq('id',user.id).single();
    if(!['admin','super_admin'].contains(p['role']))throw StateError('Administrator access required.');
    final rows=await db.from('enrolments').select('user_id,course_id,created_at,profiles(full_name,email),courses(title,published)')
      .order('created_at',ascending:false).limit(250);
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> refresh() async {final next=load();setState(()=>enrolments=next);await next;}
  Future<void> issue(Map<String,dynamic> item) async {
    final profile=Map<String,dynamic>.from(item['profiles'] as Map? ?? {});
    final course=Map<String,dynamic>.from(item['courses'] as Map? ?? {});
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Review certificate eligibility'),
      content:Text('Issue a certificate for ${profile['full_name']??profile['email']??'this student'} in ${course['title']??'this course'}?\n\nThe server will check every lesson, quiz and graded assignment. If any requirement is incomplete, it will refuse to issue the certificate.'),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Check & issue'))]));
    if(ok!=true||!mounted)return;
    setState(()=>busy=true);
    try{
      final result=await db.rpc('admin_issue_certificate',params:{'p_user_id':item['user_id'],'p_course_id':item['course_id']});
      final cert=Map<String,dynamic>.from(result as Map);
      await refresh();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Certificate ${cert['certificate_no']} ${cert['already_issued']==true?'was already issued':'issued successfully'}.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Certificate not issued: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Certificate approval'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:enrolments,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Certificate review unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final items=snap.data??[];
      return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(16),children:[
        const Text('Certificate issuance is administrator-controlled. The database verifies enrolment, all lesson completions, passed quizzes and graded assignments before issuing.',style:TextStyle(color:muted,height:1.5)),
        for(final item in items)Card(color:panel,child:ListTile(
          title:Text(((item['profiles'] as Map?)?['full_name']??(item['profiles'] as Map?)?['email']??'Student').toString()),
          subtitle:Text('${(item['courses'] as Map?)?['title']??'Course'} · ${((item['courses'] as Map?)?['published']==true)?'Published':'Unpublished'}',style:const TextStyle(color:muted)),
          trailing:IconButton(onPressed:busy||((item['courses'] as Map?)?['published']!=true)?null:()=>issue(item),icon:const Icon(Icons.workspace_premium_outlined,color:gold)),
        )),
      ]));
    }));
}

class AdminCreatorApplicationsScreen extends StatefulWidget {
  const AdminCreatorApplicationsScreen({super.key});
  @override State<AdminCreatorApplicationsScreen> createState()=>_AdminCreatorApplicationsScreenState();
}
class _AdminCreatorApplicationsScreenState extends State<AdminCreatorApplicationsScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> rows;bool busy=false,superAdmin=false;
  @override void initState(){super.initState();rows=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in first.');
    final p=await db.from('profiles').select('role').eq('id',user.id).single();
    if(!['admin','super_admin'].contains(p['role']))throw StateError('Administrator access required.');
    superAdmin=p['role']=='super_admin';
    final apps=await db.from('academy_applications').select('id,application_no,user_id,application_type,status,first_name,last_name,phone,country,region,specialty,proposed_level,prior_experience,portfolio_url,motivation,learning_goals,work_sample_urls,decision_reason,created_at,submitted_at')
      .inFilter('application_type',['creator','instructor','teacher','exhibitor']).order('created_at',ascending:false).limit(200);
    return List<Map<String,dynamic>>.from(apps);
  }
  Future<void> refresh() async {final next=load();setState(()=>rows=next);await next;}
  Future<void> review(Map<String,dynamic> app,String status) async {
    final reason=TextEditingController(text:(app['decision_reason']??'').toString());
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:Text('Set application to ${status.replaceAll('_',' ')}'),
      content:TextField(controller:reason,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Decision reason / feedback')),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Save decision'))]));
    if(!mounted){reason.dispose();return;}final note=reason.text.trim();reason.dispose();if(ok!=true)return;
    setState(()=>busy=true);
    try{
      await db.from('academy_applications').update({'status':status,'decision_reason':note.isEmpty?null:note,'reviewed_by':db.auth.currentUser!.id,'reviewed_at':DateTime.now().toUtc().toIso8601String(),'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',app['id']);
      await db.from('academy_application_events').insert({'application_id':app['id'],'actor_id':db.auth.currentUser!.id,'event_type':'admin_review','from_status':app['status'],'to_status':status,'message':note.isEmpty?'Application status updated.':note});
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update application: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> grantCreator(Map<String,dynamic> app) async {
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Grant creator access?'),
      content:const Text('The server will verify that the application is approved and that at least one interview has been completed and scored before granting the Creator role.'),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Verify & grant'))]));
    if(ok!=true||!mounted)return;
    setState(()=>busy=true);
    try{
      await db.rpc('admin_grant_creator_access',params:{'p_application_id':app['id']});
      await refresh();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Creator access granted by the server.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Creator access was not granted: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Creator applications'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:rows,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Applications unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final items=snap.data??[];
      if(items.isEmpty)return const Center(child:Text('No creator or instructor applications yet.',style:TextStyle(color:muted)));
      return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(16),children:[
        OutlinedButton.icon(onPressed:()=>openAcademyWebPage(context,'/academy-interviewer.html'),icon:const Icon(Icons.video_call_outlined),label:const Text('Open interview workspace')),
        const SizedBox(height:8),
        for(final app in items)Card(color:panel,child:Padding(padding:const EdgeInsets.all(14),child:material_widgets_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${app['application_no']} · ${app['application_type']}',style:const TextStyle(color:gold,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),Text('${app['first_name']} ${app['last_name']}',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
          Text('${app['specialty']??'No specialty'} · Proposed: ${app['proposed_level']}',style:const TextStyle(color:muted)),
          Text('Status: ${app['status']}',style:const TextStyle(color:muted,fontSize:12)),
          if((app['motivation']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(app['motivation'].toString(),maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(height:1.4))),
          if((app['portfolio_url']??'').toString().startsWith('https://'))TextButton(onPressed:()=>launchUrl(Uri.parse(app['portfolio_url'].toString()),mode:LaunchMode.externalApplication),child:const Text('Open portfolio')),
          Wrap(spacing:8,runSpacing:6,children:[
            OutlinedButton(onPressed:busy?null:()=>review(app,'under_review'),child:const Text('Under review')),
            OutlinedButton(onPressed:busy?null:()=>review(app,'more_information_requested'),child:const Text('Request info')),
            OutlinedButton(onPressed:busy?null:()=>review(app,'rejected'),child:const Text('Reject')),
            FilledButton(onPressed:busy?null:()=>review(app,'approved'),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('Approve')),
            if(superAdmin&&app['status']=='approved')OutlinedButton(onPressed:busy?null:()=>grantCreator(app),child:const Text('Grant Creator role')),
          ]),
        ]))),
      ]));
    }));
}

class CourseAdminScreen extends StatefulWidget {
  const CourseAdminScreen({super.key});
  @override State<CourseAdminScreen> createState()=>_CourseAdminScreenState();
}
class _CourseAdminScreenState extends State<CourseAdminScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> courses;bool busy=false;
  @override void initState(){super.initState();courses=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in first.');
    final p=await db.from('profiles').select('role').eq('id',user.id).single();
    if(!['admin','super_admin'].contains(p['role']))throw StateError('Course administration access is required.');
    final rows=await db.from('courses').select('id,slug,title,description,category_slug,level,duration_text,price_ngn,published,featured,duration_months,study_hours_per_week')
      .order('created_at',ascending:false);
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> refresh() async {final next=load();setState(()=>courses=next);await next;}
  Future<void> addCourse() async {
    final title=TextEditingController(),description=TextEditingController(),category=TextEditingController(),price=TextEditingController(text:'0'),duration=TextEditingController(text:'1');
    String level='Beginner';
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(backgroundColor:panel,title:const Text('Create course'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Course title')),
        const SizedBox(height:8),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Description')),
        const SizedBox(height:8),TextField(controller:category,decoration:const InputDecoration(labelText:'Category slug (e.g. digital-skills)')),
        const SizedBox(height:8),DropdownButtonFormField<String>(value:level,decoration:const InputDecoration(labelText:'Level'),
          items:const [DropdownMenuItem(value:'Beginner',child:Text('Beginner')),DropdownMenuItem(value:'Intermediate',child:Text('Intermediate')),DropdownMenuItem(value:'Advanced',child:Text('Advanced'))],
          onChanged:(v)=>setDialog(()=>level=v??level)),
        const SizedBox(height:8),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Price in naira (0 for free)')),
        const SizedBox(height:8),TextField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Duration in months (1–36)')),
      ]))),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Create draft'))])));
    if(!mounted){title.dispose();description.dispose();category.dispose();price.dispose();duration.dispose();return;}
    final t=title.text.trim(),d=description.text.trim(),cat=category.text.trim(),p=price.text.trim(),months=duration.text.trim();
    title.dispose();description.dispose();category.dispose();price.dispose();duration.dispose();if(ok!=true)return;
    final slug=t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'),'-').replaceAll(RegExp(r'^-+|-+$'),'');
    if(t.length<4||d.length<10||slug.length<4||int.tryParse(p)==null||int.tryParse(months)==null||int.parse(months)<1||int.parse(months)>36){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Check title, description, price and duration.')));return;
    }
    setState(()=>busy=true);
    try{
      await db.from('courses').insert({'title':t,'slug':slug,'description':d,'category_slug':cat.isEmpty?null:cat,
        'level':level,'price_ngn':int.parse(p),'duration_months':int.parse(months),'duration_text':'$months months',
        'published':false,'featured':false});
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not create course: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> editCourse(Map<String,dynamic> course) async {
    final title=TextEditingController(text:(course['title']??'').toString());
    final description=TextEditingController(text:(course['description']??'').toString());
    final category=TextEditingController(text:(course['category_slug']??'').toString());
    final price=TextEditingController(text:(course['price_ngn']??0).toString());
    String level=(course['level']??'Beginner').toString();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(
      backgroundColor:panel,title:const Text('Edit course'),
      content:SingleChildScrollView(child:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),
        const SizedBox(height:8),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Description')),
        const SizedBox(height:8),TextField(controller:category,decoration:const InputDecoration(labelText:'Category slug')),
        const SizedBox(height:8),DropdownButtonFormField<String>(value:level,decoration:const InputDecoration(labelText:'Level'),
          items:const [DropdownMenuItem(value:'Beginner',child:Text('Beginner')),DropdownMenuItem(value:'Intermediate',child:Text('Intermediate')),DropdownMenuItem(value:'Advanced',child:Text('Advanced'))],
          onChanged:(v)=>setDialog(()=>level=v??level)),
        const SizedBox(height:8),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Price in naira')),
      ])),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Save changes'))])));
    if(!mounted){title.dispose();description.dispose();category.dispose();price.dispose();return;}
    final t=title.text.trim(),d=description.text.trim(),cat=category.text.trim(),p=price.text.trim();
    title.dispose();description.dispose();category.dispose();price.dispose();
    if(ok!=true)return;
    if(t.length<4||d.length<10||int.tryParse(p)==null){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Check the course title, description and price.')));
      return;
    }
    var slug=t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'),'-');
    while(slug.startsWith('-')){slug=slug.substring(1);}
    while(slug.endsWith('-')){slug=slug.substring(0,slug.length-1);}
    setState(()=>busy=true);
    try{
      await db.from('courses').update({'title':t,'slug':slug,'description':d,
        'category_slug':cat.isEmpty?null:cat,'level':level,'price_ngn':int.parse(p)}).eq('id',course['id']);
      await refresh();
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update course: $e')));
    }finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> toggleCourse(Map<String,dynamic> course,String field) async {
    setState(()=>busy=true);
    try{
      await db.from('courses').update({field:!(course[field]==true)}).eq('id',course['id']);
      await refresh();
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update course: $e')));
    }finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Course administration'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:courses,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Course manager unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final rows=snap.data??[];
      return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(16),children:[
        FilledButton.icon(onPressed:busy?null:addCourse,style:FilledButton.styleFrom(backgroundColor:emerald),icon:const Icon(Icons.add),label:const Text('Create course draft')),
        const SizedBox(height:14),if(rows.isEmpty)const Text('No courses have been created yet.',style:TextStyle(color:muted)),
        for(final course in rows)Card(color:panel,child:Column(children:[
          ListTile(title:Text((course['title']??'Course').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
            subtitle:Text('${course['level']} · ${course['price_ngn']==0?'Free':'₦${course['price_ngn']}'} · ${course['published']==true?'Published':'Draft'}',style:const TextStyle(color:muted)),
            trailing:IconButton(onPressed:busy?null:()=>editCourse(course),icon:const Icon(Icons.edit_outlined,color:gold)),
            onTap:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseModulesAdminScreen(course:course))).then((_)=>refresh())),
          Row(children:[
            Expanded(child:SwitchListTile(dense:true,title:const Text('Published',style:TextStyle(fontSize:12)),value:course['published']==true,activeColor:emerald,onChanged:busy?null:(_)=>toggleCourse(course,'published'))),
            Expanded(child:SwitchListTile(dense:true,title:const Text('Featured',style:TextStyle(fontSize:12)),value:course['featured']==true,activeColor:gold,onChanged:busy?null:(_)=>toggleCourse(course,'featured'))),
          ]),
        ])),
      ]));
    }));
}

class CourseModulesAdminScreen extends StatefulWidget {
  final Map<String,dynamic> course;
  const CourseModulesAdminScreen({super.key,required this.course});
  @override State<CourseModulesAdminScreen> createState()=>_CourseModulesAdminScreenState();
}
class _CourseModulesAdminScreenState extends State<CourseModulesAdminScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> modules;bool busy=false;
  @override void initState(){super.initState();modules=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final rows=await db.from('modules').select('id,course_id,title,description,position,stage_number,duration_text,lessons(id,title,position)')
      .eq('course_id',widget.course['id']).order('position');
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> refresh() async {final next=load();setState(()=>modules=next);await next;}
  Future<void> editModule(Map<String,dynamic> module) async {
    final title=TextEditingController(text:(module['title']??'').toString());
    final description=TextEditingController(text:(module['description']??'').toString());
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Edit module'),
      content:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Module title')),
        const SizedBox(height:8),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Description')),
      ]),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Save'))]));
    if(!mounted){title.dispose();description.dispose();return;}
    final t=title.text.trim(),d=description.text.trim();title.dispose();description.dispose();if(ok!=true||t.length<3)return;
    setState(()=>busy=true);
    try{await db.from('modules').update({'title':t,'description':d.isEmpty?null:d}).eq('id',module['id']);await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update module: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> addModule() async {
    final title=TextEditingController(),description=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Add course module'),
      content:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Module title')),
        const SizedBox(height:8),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Module description')),
      ]),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Add module'))]));
    if(!mounted){title.dispose();description.dispose();return;}
    final t=title.text.trim(),d=description.text.trim();title.dispose();description.dispose();if(ok!=true||t.length<3)return;
    setState(()=>busy=true);
    try{
      final existing=await db.from('modules').select('id').eq('course_id',widget.course['id']);
      final nextPosition=existing.length+1;
      await db.from('modules').insert({'course_id':widget.course['id'],'title':t,'description':d.isEmpty?null:d,
        'position':nextPosition,'stage_number':nextPosition});
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not add module: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text((widget.course['title']??'Course modules').toString()),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:modules,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Modules unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final rows=snap.data??[];
      return ListView(padding:const EdgeInsets.all(16),children:[
        FilledButton.icon(onPressed:busy?null:addModule,icon:const Icon(Icons.add),label:const Text('Add module'),style:FilledButton.styleFrom(backgroundColor:emerald)),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseQuizAdminScreen(course:widget.course))).then((_)=>refresh()),
          icon:const Icon(Icons.quiz_outlined),label:const Text('Manage assessments')),
        for(final module in rows)Card(color:panel,child:ListTile(title:Text((module['title']??'Module').toString()),
          subtitle:Text('${(module['lessons'] as List? ?? []).length} lessons · Stage ${module['stage_number']}',style:const TextStyle(color:muted)),
          trailing:IconButton(onPressed:busy?null:()=>editModule(module),icon:const Icon(Icons.edit_outlined,color:gold)),
          onTap:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseLessonsAdminScreen(module:module))).then((_)=>refresh()))),
      ]);
    }));
}

class CourseQuizAdminScreen extends StatefulWidget {
  final Map<String,dynamic> course;
  const CourseQuizAdminScreen({super.key,required this.course});
  @override State<CourseQuizAdminScreen> createState()=>_CourseQuizAdminScreenState();
}
class _CourseQuizAdminScreenState extends State<CourseQuizAdminScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> quizzes;bool busy=false;
  @override void initState(){super.initState();quizzes=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final rows=await db.from('quizzes').select('id,course_id,title,pass_mark,created_at,quiz_questions(id)')
      .eq('course_id',widget.course['id']).order('created_at');
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> refresh() async {final next=load();setState(()=>quizzes=next);await next;}
  Future<void> addQuiz() async {
    final title=TextEditingController();final pass=TextEditingController(text:'70');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Create assessment'),
      content:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Assessment title')),
        const SizedBox(height:8),TextField(controller:pass,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Pass mark (1–100)')),
      ]),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Create'))]));
    if(!mounted){title.dispose();pass.dispose();return;}
    final t=title.text.trim(),p=int.tryParse(pass.text.trim())??70;title.dispose();pass.dispose();if(ok!=true||t.length<3||p<1||p>100)return;
    setState(()=>busy=true);
    try{await db.from('quizzes').insert({'course_id':widget.course['id'],'title':t,'pass_mark':p});await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not create assessment: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Course assessments'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:quizzes,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Assessments unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final rows=snap.data??[];
      return ListView(padding:const EdgeInsets.all(16),children:[
        FilledButton.icon(onPressed:busy?null:addQuiz,icon:const Icon(Icons.add),label:const Text('Create assessment'),style:FilledButton.styleFrom(backgroundColor:emerald)),
        for(final quiz in rows)Card(color:panel,child:ListTile(
          title:Text((quiz['title']??'Assessment').toString()),
          subtitle:Text('Pass mark: ${quiz['pass_mark']}% · ${(quiz['quiz_questions'] as List? ?? []).length} questions',style:const TextStyle(color:muted)),
          trailing:const Icon(Icons.chevron_right,color:emerald),
          onTap:()=>material_widgets_ui.Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseQuizQuestionsAdminScreen(quiz:quiz))).then((_)=>refresh()),
        )),
      ]);
    }));
}

class CourseQuizQuestionsAdminScreen extends StatefulWidget {
  final Map<String,dynamic> quiz;
  const CourseQuizQuestionsAdminScreen({super.key,required this.quiz});
  @override State<CourseQuizQuestionsAdminScreen> createState()=>_CourseQuizQuestionsAdminScreenState();
}
class _CourseQuizQuestionsAdminScreenState extends State<CourseQuizQuestionsAdminScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> questions;bool busy=false;
  @override void initState(){super.initState();questions=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final rows=await db.from('quiz_questions').select('id,quiz_id,question,options,correct_index,position')
      .eq('quiz_id',widget.quiz['id']).order('position');
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> refresh() async {final next=load();setState(()=>questions=next);await next;}
  Future<void> addQuestion() async {
    final question=TextEditingController();final options=List.generate(4,(_)=>TextEditingController());int correct=0;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(backgroundColor:panel,title:const Text('Add quiz question'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:question,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Question')),
        for(var i=0;i<4;i++)Padding(padding:const EdgeInsets.only(top:8),child:Row(children:[
          Expanded(child:TextField(controller:options[i],decoration:InputDecoration(labelText:'Option ${String.fromCharCode(65+i)}'))),
          Radio<int>(value:i,groupValue:correct,activeColor:emerald,onChanged:(v)=>setDialog(()=>correct=v??correct)),
        ])),
        const SizedBox(height:6),const Text('Select the radio button beside the correct answer.',style:TextStyle(color:muted,fontSize:11)),
      ]))),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Save question'))])));
    if(!mounted){question.dispose();for(final x in options){x.dispose();}return;}
    final q=question.text.trim(),choices=options.map((x)=>x.text.trim()).toList();question.dispose();for(final x in options){x.dispose();}
    if(ok!=true||q.length<5||choices.any((v)=>v.isEmpty)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a question and all four answer options.')));return;}
    setState(()=>busy=true);
    try{
      await db.from('quiz_questions').insert({'quiz_id':widget.quiz['id'],'question':q,'options':choices,'correct_index':correct,'position':(await db.from('quiz_questions').select('id').eq('quiz_id',widget.quiz['id'])).length+1});
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not add question: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text((widget.quiz['title']??'Questions').toString()),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:questions,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Questions unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final rows=snap.data??[];
      return ListView(padding:const EdgeInsets.all(16),children:[
        FilledButton.icon(onPressed:busy?null:addQuestion,icon:const Icon(Icons.add),label:const Text('Add question'),style:FilledButton.styleFrom(backgroundColor:emerald)),
        for(var i=0;i<rows.length;i++)Card(color:panel,child:ListTile(
          title:Text('${i+1}. ${rows[i]['question']}'),
          subtitle:Text((rows[i]['options'] as List? ?? []).asMap().entries.map((e)=>'${String.fromCharCode(65+e.key)}. ${e.value}').join('\n'),style:const TextStyle(color:muted)),
        )),
      ]);
    }));
}

class CourseLessonsAdminScreen extends StatefulWidget {
  final Map<String,dynamic> module;
  const CourseLessonsAdminScreen({super.key,required this.module});
  @override State<CourseLessonsAdminScreen> createState()=>_CourseLessonsAdminScreenState();
}
class _CourseLessonsAdminScreenState extends State<CourseLessonsAdminScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> lessons;bool busy=false;
  @override void initState(){super.initState();lessons=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final rows=await db.from('lessons').select('id,module_id,title,content,video_url,position,estimated_minutes,chapter_number,topic_outline')
      .eq('module_id',widget.module['id']).order('position');
    return List<Map<String,dynamic>>.from(rows);
  }
  Future<void> refresh() async {final next=load();setState(()=>lessons=next);await next;}
  Future<void> editLesson(Map<String,dynamic> lesson) async {
    final title=TextEditingController(text:(lesson['title']??'').toString());
    final content=TextEditingController(text:(lesson['content']??'').toString());
    final video=TextEditingController(text:(lesson['video_url']??'').toString());
    final minutes=TextEditingController(text:(lesson['estimated_minutes']??30).toString());
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Edit lesson'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Lesson title')),
        const SizedBox(height:8),TextField(controller:content,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Lesson content')),
        const SizedBox(height:8),TextField(controller:video,decoration:const InputDecoration(labelText:'Video URL')),
        const SizedBox(height:8),TextField(controller:minutes,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Estimated minutes')),
      ]))),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Save changes'))]));
    if(!mounted){title.dispose();content.dispose();video.dispose();minutes.dispose();return;}
    final t=title.text.trim(),body=content.text.trim(),url=video.text.trim(),mins=int.tryParse(minutes.text.trim())??30;
    title.dispose();content.dispose();video.dispose();minutes.dispose();if(ok!=true||t.length<3||mins<5||mins>600)return;
    setState(()=>busy=true);
    try{await db.from('lessons').update({'title':t,'content':body.isEmpty?null:body,'video_url':url.isEmpty?null:url,'estimated_minutes':mins}).eq('id',lesson['id']);await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update lesson: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> addLesson() async {
    final title=TextEditingController(),content=TextEditingController(),video=TextEditingController(),minutes=TextEditingController(text:'30');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Add lesson'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:material_widgets_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Lesson title')),
        const SizedBox(height:8),TextField(controller:content,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Lesson content / notes')),
        const SizedBox(height:8),TextField(controller:video,decoration:const InputDecoration(labelText:'Video URL (optional)')),
        const SizedBox(height:8),TextField(controller:minutes,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Estimated minutes (5–600)')),
      ]))),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Add lesson'))]));
    if(!mounted){title.dispose();content.dispose();video.dispose();minutes.dispose();return;}
    final t=title.text.trim(),body=content.text.trim(),url=video.text.trim(),mins=int.tryParse(minutes.text.trim())??30;
    title.dispose();content.dispose();video.dispose();minutes.dispose();if(ok!=true||t.length<3||mins<5||mins>600)return;
    setState(()=>busy=true);
    try{
      final existing=await db.from('lessons').select('id').eq('module_id',widget.module['id']);
      await db.from('lessons').insert({'module_id':widget.module['id'],'title':t,'content':body.isEmpty?null:body,
        'video_url':url.isEmpty?null:url,'estimated_minutes':mins,'position':existing.length+1,'chapter_number':1});
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not add lesson: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text((widget.module['title']??'Lessons').toString()),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:lessons,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Lessons unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final rows=snap.data??[];
      return ListView(padding:const EdgeInsets.all(16),children:[
        FilledButton.icon(onPressed:busy?null:addLesson,icon:const Icon(Icons.add),label:const Text('Add lesson'),style:FilledButton.styleFrom(backgroundColor:emerald)),
        for(final lesson in rows)Card(color:panel,child:ListTile(
          leading:const Icon(Icons.play_circle_outline,color:emerald),
          title:Text((lesson['title']??'Lesson').toString()),
          subtitle:Text('${lesson['estimated_minutes']} min · Chapter ${lesson['chapter_number']}',style:const TextStyle(color:muted)),
          trailing:IconButton(onPressed:busy?null:()=>editLesson(lesson),icon:const Icon(Icons.edit_outlined,color:gold)),
        )),
      ]);
    }));
}

class CommunityModerationScreen extends StatefulWidget {
  const CommunityModerationScreen({super.key});
  @override State<CommunityModerationScreen> createState()=>_CommunityModerationScreenState();
}
class _CommunityModerationScreenState extends State<CommunityModerationScreen>{
  final db=Supabase.instance.client;late Future<List<Map<String,dynamic>>> reports;bool busy=false;
  @override void initState(){super.initState();reports=load();}
  Future<List<Map<String,dynamic>>> load() async {
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in first.');
    final p=await db.from('profiles').select('role').eq('id',user.id).single();
    if(!['admin','super_admin','moderator'].contains(p['role']))throw StateError('Moderation access is required.');
    final raw=await db.from('community_reports').select('id,reporter_id,post_id,comment_id,reason,details,status,created_at,community_posts(title,description)')
      .inFilter('status',['open','reviewing']).order('created_at',ascending:false).limit(100);
    return List<Map<String,dynamic>>.from(raw);
  }
  Future<void> refresh() async {final next=load();setState(()=>reports=next);await next;}
  Future<void> updateReport(Map<String,dynamic> report,String status) async {
    setState(()=>busy=true);
    try{await db.from('community_reports').update({'status':status}).eq('id',report['id']);await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update report: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> hidePost(Map<String,dynamic> report) async {
    if(report['post_id']==null)return;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Hide this community post?'),
      content:const Text('The post will no longer appear in the public community feed.'),
      actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(ctx,true),child:const Text('Hide post'))]));
    if(ok!=true||!mounted)return;
    setState(()=>busy=true);
    try{
      await db.from('community_posts').update({'status':'hidden'}).eq('id',report['post_id']);
      await db.from('community_reports').update({'status':'resolved'}).eq('id',report['id']);
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not hide post: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Community moderation'),actions:[IconButton(onPressed:busy?null:refresh,icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:reports,builder:(context,snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
      if(snap.hasError)return Center(child:Text('Moderation unavailable: ${snap.error}',style:const TextStyle(color:muted)));
      final items=snap.data??[];
      if(items.isEmpty)return const Center(child:Text('No open community reports.',style:TextStyle(color:muted)));
      return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(14),children:[
        for(final item in items)Card(color:panel,child:Padding(padding:const EdgeInsets.all(14),child:material_widgets_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text((item['reason']??'Community report').toString().toUpperCase(),style:const TextStyle(color:gold,fontWeight:FontWeight.w800)),
          const SizedBox(height:6),Text((item['community_posts'] is Map?item['community_posts']['title']:'Reported post/comment').toString(),style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700)),
          if((item['details']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:6),child:Text(item['details'].toString(),style:const TextStyle(color:muted))),
          const SizedBox(height:8),Text('Status: ${item['status']} · ${_timeAgo(item['created_at']?.toString())}',style:const TextStyle(color:muted,fontSize:11)),
          Wrap(spacing:8,runSpacing:6,children:[
            OutlinedButton(onPressed:busy?null:()=>updateReport(item,'reviewing'),child:const Text('Mark reviewing')),
            OutlinedButton(onPressed:busy?null:()=>updateReport(item,'dismissed'),child:const Text('Dismiss')),
            if(item['post_id']!=null)FilledButton(onPressed:busy?null:()=>hidePost(item),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('Hide post & resolve'))
            else FilledButton(onPressed:busy?null:()=>updateReport(item,'resolved'),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('Resolve')),
          ]),
        ]))),
      ]));
    }));
}


class AdminPaymentReviewScreen extends StatefulWidget {
  const AdminPaymentReviewScreen({super.key});
  @override State<AdminPaymentReviewScreen> createState()=>_AdminPaymentReviewScreenState();
}
class _AdminPaymentReviewScreenState extends State<AdminPaymentReviewScreen>{
  final db=Supabase.instance.client;
  final notes=<String,String>{};
  final searchController=TextEditingController();
  late Future<List<Map<String,dynamic>>> orders;
  String filter='proof_submitted',searchTerm='';
  bool busy=false;
  @override void initState(){super.initState();orders=loadOrders();}
  @override void dispose(){searchController.dispose();super.dispose();}
  Future<List<Map<String,dynamic>>> loadOrders() async{
    final user=db.auth.currentUser;if(user==null)throw StateError('Sign in to continue.');
    final p=await db.from('profiles').select('role').eq('id',user.id).single();
    if(!['admin','super_admin'].contains((p['role']??'').toString()))throw StateError('Administrator access is required.');
    final rows=await db.from('payment_orders').select('id,user_id,course_id,amount_ngn,currency,method,status,reference,created_at,updated_at,expires_at,confirmed_at,transfer_reference,proof_url,admin_note,receipt_number,receipt_issued_at,receipt_course_title,receipt_payer_name,courses(title)').order('created_at',ascending:false).limit(500);
    final ids=rows.map((r)=>r['user_id'].toString()).toSet().toList();
    final profiles=ids.isEmpty?<dynamic>[]:await db.from('profiles').select('id,full_name,username').inFilter('id',ids);
    final names=<String,String>{for(final x in profiles)x['id'].toString():(x['full_name']??x['username']??'CreatorVerse member').toString()};
    return List<Map<String,dynamic>>.from(rows.map((r)=>{...Map<String,dynamic>.from(r),'payer_name':names[r['user_id'].toString()]??'CreatorVerse member'}));
  }
  Future<void> refresh() async{final next=loadOrders();setState(()=>orders=next);await next;}
  Future<void> openProof(Map<String,dynamic> order) async{
    final path=(order['proof_url']??'').toString();if(path.isEmpty)return;
    try{final url=path.startsWith('https://')?path:await db.storage.from('payment-proofs').createSignedUrl(path,60);await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not open payment evidence: $e')));}
  }
  Future<void> showHistory(Map<String,dynamic> order) async{
    try{
      final events=await db.from('payment_order_events').select('event_type,from_status,to_status,note,created_at,actor_id').eq('payment_order_id',order['id']).order('created_at');
      if(!mounted)return;
      await showDialog<void>(context:context,builder:(d)=>AlertDialog(backgroundColor:panel,title:const Text('Payment activity history'),
        content:SizedBox(width:420,child:events.isEmpty?const Text('No activity history is available.'):ListView(shrinkWrap:true,children:[
          for(final e in events)ListTile(dense:true,leading:const Icon(Icons.history,color:emerald),
            title:Text((e['event_type']??'').toString().replaceAll('_',' ').toUpperCase(),style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),
            subtitle:Text('${e['from_status']??'created'} → ${e['to_status']??''}\n${e['created_at']??''}\n${e['note']??''}',style:const TextStyle(color:muted,fontSize:11)))
        ])),actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(d),child:const Text('Close'))]));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not load history: $e')));}
  }
  Future<void> review(Map<String,dynamic> order,String status) async{
    if(order['status']!='proof_submitted'){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Only submitted proofs can be reviewed.')));return;}
    final id=order['id'].toString(),note=(notes[order['id'].toString()]??order['admin_note']??'').trim();
    if(status=='rejected'&&note.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Add a rejection reason first.')));return;}
    if(status=='confirmed'){
      final yes=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(backgroundColor:panel,title:const Text('Confirm money received?'),
        content:const Text('Check your actual bank or USSD transaction history. Verify the exact amount and transfer reference. Do not approve based on a screenshot alone. Confirmation issues the official receipt and activates course access.'),
        actions:[TextButton(onPressed:()=>material_widgets_ui.Navigator.pop(d,false),child:const Text('Go back')),
          FilledButton(onPressed:()=>material_widgets_ui.Navigator.pop(d,true),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('I verified funds received'))]));
      if(yes!=true)return;
    }
    setState(()=>busy=true);
    try{
      final changed=await db.from('payment_orders').update({'status':status,'admin_note':note.isEmpty?null:note}).eq('id',id).eq('status','proof_submitted').select('id').maybeSingle();
      if(changed==null)throw StateError('This payment was already reviewed or changed. Refresh and check its latest status.');
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(status=='confirmed'?'Payment confirmed. Receipt issued and course enrolment activated.':'Payment rejected. Reason recorded.')));
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update payment: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Widget metric(String label,String value,IconData icon)=>SizedBox(width:(MediaQuery.of(context).size.width-52)/2,
    child:Card(color:panel,child:Padding(padding:const EdgeInsets.all(13),child:Row(children:[
      Icon(icon,color:emerald,size:22),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),Text(label,style:const TextStyle(color:muted,fontSize:11))
      ]))
    ]))));
  @override Widget build(BuildContext context)=>FutureBuilder<List<Map<String,dynamic>>>(future:orders,builder:(context,snap){
    if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:emerald));
    if(snap.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Payment management is unavailable: ${snap.error}',textAlign:TextAlign.center,style:const TextStyle(color:muted))));
    final all=snap.data??[];
    final pending=all.where((o)=>o['status']=='pending').length,submitted=all.where((o)=>o['status']=='proof_submitted').length;
    final confirmed=all.where((o)=>o['status']=='confirmed').toList();
    final total=confirmed.fold<int>(0,(sum,o)=>sum+((o['amount_ngn'] as num?)?.toInt()??0));
    final term=searchTerm.toLowerCase();
    final visible=all.where((o){
      final course=(o['courses'] is Map?o['courses']['title']:'').toString();
      final hay='${o['reference']} ${o['transfer_reference']} ${o['payer_name']} $course'.toLowerCase();
      return (filter=='all'||o['status']==filter)&&(term.isEmpty||hay.contains(term));
    }).toList();
    return RefreshIndicator(color:emerald,onRefresh:refresh,child:ListView(padding:const EdgeInsets.fromLTRB(14,14,14,24),children:[
      Row(children:[const Expanded(child:Text('Payment Management',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800))),IconButton(onPressed:busy?null:refresh,icon:const Icon(Icons.refresh))]),
      const Text('Review transfers, keep a traceable financial record and issue official receipts.',style:TextStyle(color:muted,height:1.45,fontSize:12)),
      const SizedBox(height:12),
      Wrap(spacing:8,runSpacing:8,children:[
        metric('Awaiting transfer','$pending',Icons.hourglass_empty),metric('Ready for review','$submitted',Icons.fact_check_outlined),
        metric('Confirmed payments','${confirmed.length}',Icons.verified_outlined),metric('Confirmed total','NGN $total',Icons.account_balance_wallet_outlined)
      ]),
      const SizedBox(height:14),
      TextField(controller:searchController,onChanged:(v)=>setState(()=>searchTerm=v.trim()),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search payer, course or reference')),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(value:filter,decoration:const InputDecoration(labelText:'Show payment status'),items:const[
        DropdownMenuItem(value:'proof_submitted',child:Text('Ready for review')),DropdownMenuItem(value:'pending',child:Text('Awaiting transfer')),
        DropdownMenuItem(value:'confirmed',child:Text('Confirmed')),DropdownMenuItem(value:'rejected',child:Text('Rejected')),
        DropdownMenuItem(value:'expired',child:Text('Expired')),DropdownMenuItem(value:'cancelled',child:Text('Cancelled')),DropdownMenuItem(value:'all',child:Text('All records'))
      ],onChanged:busy?null:(v)=>setState(()=>filter=v??'proof_submitted')),
      const SizedBox(height:12),Text('Payment records · showing ${visible.length} of ${all.length} loaded',style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700)),
      if(visible.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('No payment records match this view.',style:TextStyle(color:muted)))),
      for(final o in visible)...[
        const SizedBox(height:8),Card(color:panel,child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:Text((o['courses'] is Map?o['courses']['title']:null)??'Course payment',style:const TextStyle(fontSize:15,fontWeight:FontWeight.w800))),
            Text('NGN ${o['amount_ngn']}',style:const TextStyle(color:gold,fontWeight:FontWeight.w800))]),
          const SizedBox(height:5),Text((o['payer_name']??'CreatorVerse member').toString(),style:const TextStyle(fontWeight:FontWeight.w600)),
          Text('Status: ${o['status']} · ${(o['method']??'').toString().replaceAll('_',' ')}',style:const TextStyle(color:muted,fontSize:12)),
          Text('CreatorVerse ref: ${o['reference']}',style:const TextStyle(color:muted,fontSize:11)),
          if((o['transfer_reference']??'').toString().isNotEmpty)Text('Bank / USSD ref: ${o['transfer_reference']}',style:const TextStyle(color:muted,fontSize:11)),
          Text('Created: ${o['created_at']??''}',style:const TextStyle(color:muted,fontSize:11)),
          if((o['receipt_number']??'').toString().isNotEmpty)Text('Receipt: ${o['receipt_number']}',style:const TextStyle(color:emerald,fontSize:11,fontWeight:FontWeight.w700)),
          Wrap(spacing:4,children:[
            TextButton.icon(onPressed:()=>showHistory(o),icon:const Icon(Icons.history,size:17),label:const Text('Activity log')),
            if((o['proof_url']??'').toString().isNotEmpty)TextButton.icon(onPressed:()=>openProof(o),icon:const Icon(Icons.image_outlined,size:17),label:const Text('View proof')),
            if(o['status']=='confirmed')TextButton.icon(onPressed:()=>printPaymentReceipt(context,o),icon:const Icon(Icons.print_outlined,size:17),label:const Text('Print receipt'))
          ]),
          if(o['status']=='pending')const Text('Waiting for the learner to submit a transfer reference.',style:TextStyle(color:muted,fontSize:11)),
          if(o['status']=='proof_submitted')...[
            const Divider(color:Colors.white12),
            TextFormField(initialValue:(o['admin_note']??'').toString(),decoration:const InputDecoration(labelText:'Reviewer note / rejection reason'),onChanged:(v)=>notes[o['id'].toString()]=v),
            const SizedBox(height:8),Row(children:[
              Expanded(child:FilledButton.icon(onPressed:busy?null:()=>review(o,'confirmed'),icon:const Icon(Icons.check_circle_outline,size:18),label:const Text('Approve'),style:FilledButton.styleFrom(backgroundColor:emerald))),
              const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:busy?null:()=>review(o,'rejected'),icon:const Icon(Icons.cancel_outlined,size:18),label:const Text('Reject')))
            ])
          ]
        ])))
      ],
      if(all.length>=500)const Text('Showing the latest 500 records. Older records remain stored in the database.',style:TextStyle(color:muted,fontSize:11))
    ]));
  });
}
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});
  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool saving = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    if (password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use at least 8 characters for your new password.')));
      return;
    }
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The passwords do not match.')));
      return;
    }
    setState(() => saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password.text));
      if (!mounted) return;
      password.clear();
      confirmPassword.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password has been updated.')));
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update password: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Account security', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Your CreatorVerse mobile app uses the same account as the website.', style: TextStyle(color: muted, height: 1.5)),
      const SizedBox(height: 20),
      Card(color: panel, child: ListTile(
        leading: const Icon(Icons.email_outlined, color: emerald),
        title: const Text('Signed-in email'),
        subtitle: Text(email, style: const TextStyle(color: muted)),
      )),
      const SizedBox(height: 22),
      const Text('Change password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      TextField(controller: password, obscureText: obscurePassword,
        decoration: InputDecoration(labelText: 'New password', suffixIcon: IconButton(
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
          icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
      const SizedBox(height: 12),
      TextField(controller: confirmPassword, obscureText: obscureConfirm,
        decoration: InputDecoration(labelText: 'Confirm new password', suffixIcon: IconButton(
          onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
          icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: saving ? null : changePassword,
        icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_reset),
        label: Text(saving ? 'Updating…' : 'Update password'),
        style: FilledButton.styleFrom(backgroundColor: emerald, minimumSize: const Size.fromHeight(48))),
    ]);
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> notifications;
  RealtimeChannel? notificationChannel, academyNotificationChannel;

  @override
  void initState() {
    super.initState();
    notifications = loadNotifications();
    final userId=db.auth.currentUser?.id;
    if(userId!=null){
      notificationChannel=db.channel('cv-notifications-$userId')
        .onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'cv_notifications',
          filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'user_id',value:userId),
          callback:(payload){if(mounted)refresh();})
        .subscribe();
      academyNotificationChannel=db.channel('cv-notifications-academy-$userId')
        .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'academy_notifications',
          filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'user_id',value:userId),
          callback:(payload){if(mounted)refresh();})
        .subscribe();
    }
  }

  @override
  void dispose() {
    final channel=notificationChannel, academyChannel=academyNotificationChannel;
    if(channel!=null)db.removeChannel(channel);
    if(academyChannel!=null)db.removeChannel(academyChannel);
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> loadNotifications() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }
    try {
      await OfflineCourseCache.syncPendingReads(db,userId);
      final now=DateTime.now().toUtc().toIso8601String();
      final pair=await Future.wait([
        db.from('cv_notifications').select('id,type,title,body,href,entity_type,entity_id,created_at,read_at,actor_id')
          .eq('user_id',userId).order('created_at',ascending:false).limit(60),
        db.from('academy_notifications').select('id,notification_type,title,body,action_url,created_at,read_at,scheduled_for,related_application_id,related_offer_id,related_interview_id,related_course_id')
          .eq('user_id',userId).lte('scheduled_for',now).order('created_at',ascending:false).limit(60),
      ]);
      final result=<Map<String,dynamic>>[
        ...List<Map<String,dynamic>>.from(pair[0] as List).map((row)=>{...row,'_source':'cv'}),
        ...List<Map<String,dynamic>>.from(pair[1] as List).map((row)=>{...row,
          'type':row['notification_type']??'academy',
          'href':row['action_url']??'academy-status.html',
          '_source':'academy',
        }),
      ];
      final uniqueRows=<String,Map<String,dynamic>>{};
      for(final row in result){uniqueRows.putIfAbsent(row['id'].toString(),()=>row);}
      final limited=uniqueRows.values.toList()
        ..sort((a,b)=>DateTime.parse(b['created_at'].toString()).compareTo(DateTime.parse(a['created_at'].toString())));
      final page=limited.take(60).toList();
      await OfflineCourseCache.saveNotifications(userId,page);
      return page;
    } catch (_) {
      return await OfflineCourseCache.readNotifications(userId);
    }
  }

  Future<void> refresh() async {
    final next = loadNotifications();
    setState(() => notifications = next);
    await next;
  }

  Future<void> markRead(Map<String, dynamic> item) async {
    if (item['read_at'] != null) {
      return;
    }
    final userId=db.auth.currentUser!.id;
    try {
      final table=item['_source']=='academy'?'academy_notifications':'cv_notifications';
      await db.from(table).update({'read_at':DateTime.now().toUtc().toIso8601String()})
        .eq('id',item['id']).eq('user_id',userId);
      if(mounted)await refresh();
    }
    catch(_){await OfflineCourseCache.queueRead(userId,item['id'].toString());final cached=await OfflineCourseCache.readNotifications(userId);final changed=cached.map((row){if(row['id'].toString()==item['id'].toString())row['read_at']=DateTime.now().toUtc().toIso8601String();return row;}).toList();await OfflineCourseCache.saveNotifications(userId,changed);if(mounted)await refresh();}
  }

  Future<void> openNotification(Map<String, dynamic> item) async {
    await markRead(item);
    if (!mounted) return;
    final href = (item['href'] ?? '').toString().trim();
    if (href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host != 'creatorverse-ai.vercel.app') {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    final targetPath = '$path${uri.hasQuery ? '?${uri.query}' : ''}';
    if (path.endsWith('/academy-status.html')) {
      await material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAcademyApplicationsScreen()));
      return;
    }
    if (path.endsWith('/academy-live-room.html') || path.endsWith('/academy-interviewer.html') ||
        path.endsWith('/academy-interview.html')) {
      await openAcademyWebPage(context, targetPath);
      return;
    }
    if (path.endsWith('/profile.html') || path == '/profile') {
      final target = (uri.queryParameters['u'] ?? uri.queryParameters['id'] ?? '').trim();
      if (target.isNotEmpty) await openMemberFromNotification(target);
      return;
    }
    if (path.endsWith('/marketplace-enquiries.html') || path == '/marketplace-enquiries.html') {
      final enquiryId = uri.queryParameters['id'];
      if (enquiryId != null && enquiryId.isNotEmpty) {
        await material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceEnquiryThreadScreen(enquiryId: enquiryId)));
      } else {
        await material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceEnquiriesScreen()));
      }
      return;
    }
    if (path == '/messages.html' || path == '/messages') {
      await material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MessageInboxScreen()));
    } else {
      openFeature(context, path);
    }
  }

  Future<void> openMemberFromNotification(String target) async {
    try {
      final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(target);
      Map<String, dynamic>? row;
      if (isUuid) {
        row = await db.from('public_profiles')
          .select('id,full_name,username,avatar_url,bio,location,skills,verified_badge,role')
          .eq('id', target).maybeSingle();
      }
      row ??= await db.from('public_profiles')
        .select('id,full_name,username,avatar_url,bio,location,skills,verified_badge,role')
        .eq('username', target).maybeSingle();
      if (!mounted) return;
      if (row == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This member profile is no longer available.')));
        return;
      }
      await material_widgets_ui.Navigator.push(context, MaterialPageRoute(
        builder: (_) => PublicMemberProfileScreen(profile: Map<String, dynamic>.from(row!))));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open member profile: $e')));
      }
    }
  }

  Future<void> markAllRead(List<Map<String, dynamic>> items) async {
    final unread = items.where((item) => item['read_at'] == null).toList();
    if (unread.isEmpty) {
      return;
    }
    try {
      final stamp=DateTime.now().toUtc().toIso8601String();
      final userId=db.auth.currentUser!.id;
      await Future.wait([
        db.from('cv_notifications').update({'read_at':stamp}).eq('user_id',userId).isFilter('read_at',null),
        db.from('academy_notifications').update({'read_at':stamp}).eq('user_id',userId)
          .isFilter('read_at',null).lte('scheduled_for',stamp),
      ]);
      if (mounted) await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark notifications as read: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: notifications,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: emerald));
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(
          'Notifications could not be loaded: ${snapshot.error}',
          textAlign: TextAlign.center, style: const TextStyle(color: muted))));
      }
      final rows = snapshot.data ?? [];
      final unread = rows.where((item) => item['read_at'] == null).length;
      if (rows.isEmpty) return const Center(child: Text('You are all caught up.', style: TextStyle(color: muted)));
      return RefreshIndicator(color: emerald, onRefresh: refresh, child: material_widgets_ui.Column(children: [
        if (unread > 0) Align(alignment: Alignment.centerRight, child: TextButton(
          onPressed: () => markAllRead(rows), child: Text('Mark all as read ($unread)'))),
        Expanded(child: ListView.separated(itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, index) {
            final item = rows[index];
            final read = item['read_at'] != null;
            final title = (item['title'] ?? 'CreatorVerse update').toString();
            final body = (item['body'] ?? '').toString();
            return ListTile(
              leading: CircleAvatar(backgroundColor: read ? panel : emerald.withValues(alpha: .16),
                child: Icon(read ? Icons.notifications_none : Icons.notifications_active_outlined,
                  color: read ? muted : emerald)),
              title: Text(title, style: TextStyle(fontWeight: read ? FontWeight.w500 : FontWeight.w800)),
              subtitle: Text(body, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted)),
              trailing: read ? null : const Icon(Icons.circle, color: emerald, size: 9),
              onTap: () => openNotification(item),
            );
          })),
      ]));
    });
}

class LinkPage extends StatelessWidget {
  final IconData icon; final String title, description, button, path;
  const LinkPage({super.key, required this.icon, required this.title, required this.description, required this.button, required this.path});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 54, color: emerald), const SizedBox(height: 18), Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
    const SizedBox(height: 10), Text(description, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.5)),
    const SizedBox(height: 22), FilledButton(onPressed: () => openLink(path), child: Text(button))])));
}
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}
class _ProfileTabState extends State<ProfileTab> {
  final db = Supabase.instance.client;
  late Future<Map<String, dynamic>> profile;
  RealtimeChannel? _syncChannel;
  Timer? _syncTimer;
  @override
  void initState() {
    super.initState(); profile = loadProfile();
    final userId=db.auth.currentUser?.id;
    if(userId!=null){
      _syncChannel=db.channel('cv-profile-sync-$userId')
        .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'profiles',
          filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'id',value:userId),
          callback:(_){
            _syncTimer?.cancel();
            _syncTimer=Timer(const Duration(milliseconds:400),(){
              if(mounted)setState(()=>profile=loadProfile());
            });
          }).subscribe();
    }
  }
  @override
  void dispose(){
    _syncTimer?.cancel();
    final channel=_syncChannel;if(channel!=null)unawaited(channel.unsubscribe());
    super.dispose();
  }
  Future<Map<String, dynamic>> loadProfile() async {
    final user = db.auth.currentUser;
    if (user == null) throw Exception('You are signed out.');
    final row = await db.from('profiles')
      .select('id,full_name,email,avatar_url,username,bio,cover_url,location,website_url,skills,status_text,verified_badge,role,created_at,updated_at')
      .eq('id', user.id).maybeSingle();
    if (row == null) {
      return {'id': user.id, 'full_name': user.userMetadata?['full_name'] ?? '', 'email': user.email ?? '', 'role': 'student'};
    }
    return Map<String, dynamic>.from(row);
  }
  Future<void> refresh() async => setState(() => profile = loadProfile());
  Future<void> editProfile(Map<String, dynamic> current) async {
    final name = TextEditingController(text: (current['full_name'] ?? '').toString());
    final username = TextEditingController(text: (current['username'] ?? '').toString());
    final bio = TextEditingController(text: (current['bio'] ?? '').toString());
    final location = TextEditingController(text: (current['location'] ?? '').toString());
    final website = TextEditingController(text: (current['website_url'] ?? '').toString());
    final skills = TextEditingController(text: current['skills'] is List ? (current['skills'] as List).join(', ') : (current['skills'] ?? '').toString());
    final status = TextEditingController(text: (current['status_text'] ?? '').toString());
    bool saving = false;
    try {
      await showDialog(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) =>
        AlertDialog(backgroundColor: panel, title: const Text('Edit profile'),
          content: SizedBox(width: 440, child: SingleChildScrollView(child: material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10), TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 10), TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
            const SizedBox(height: 10), TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 10), TextField(controller: website, decoration: const InputDecoration(labelText: 'Website URL')),
            const SizedBox(height: 10), TextField(controller: skills, decoration: const InputDecoration(labelText: 'Skills')),
            const SizedBox(height: 10), TextField(controller: status, decoration: const InputDecoration(labelText: 'Status')),
          ]))),
          actions: [
            TextButton(onPressed: saving ? null : () => material_widgets_ui.Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: saving ? null : () async {
              setDialogState(() => saving = true);
              try {
                await db.from('profiles').update({
                  'full_name': name.text.trim(), 'username': username.text.trim(),
                  'bio': bio.text.trim(), 'location': location.text.trim(),
                  'website_url': website.text.trim(),
                  'skills': parseSkillsInput(skills.text),
                  'status_text': status.text.trim(), 'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', db.auth.currentUser!.id);
                if (!dialogContext.mounted) return;
                material_widgets_ui.Navigator.pop(dialogContext);
                await refresh();
                if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
              } catch (e) {
                setDialogState(() => saving = false);
                if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Could not update profile: $e')));
              }
            }, child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save changes')),
          ])));
    } finally {
      name.dispose(); username.dispose(); bio.dispose(); location.dispose(); website.dispose(); skills.dispose(); status.dispose();
    }
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: profile,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
      if (snapshot.hasError) { return Center(child: Padding(padding: const EdgeInsets.all(24), child: material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, color: muted, size: 42), const SizedBox(height: 12),
        const Text('Your profile could not be loaded', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: muted)),
        const SizedBox(height: 14), OutlinedButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh), label: const Text('Try again')),
      ]))); }
      final p = snapshot.data ?? {};
      final user = db.auth.currentUser;
      final name = (p['full_name'] ?? '').toString().trim();
      final role = (p['role'] ?? 'student').toString();
      final avatar = (p['avatar_url'] ?? '').toString();
      final isAdmin = role == 'admin' || role == 'super_admin';
      return RefreshIndicator(color: emerald, onRefresh: refresh, child: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: material_widgets_ui.Column(children: [
          CircleAvatar(radius: 42, backgroundColor: const Color(0x3320B887),
            backgroundImage: avatar.startsWith('https://') ? NetworkImage(avatar) : null,
            child: avatar.startsWith('https://') ? null : const Icon(Icons.person, size: 40, color: emerald)),
          const SizedBox(height: 13),
          Text(name.isEmpty ? 'CreatorVerse member' : name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          if ((p['username'] ?? '').toString().isNotEmpty) Text('@${p['username']}', style: const TextStyle(color: muted)),
          const SizedBox(height: 4), Text(user?.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (isAdmin) Chip(label: Text(role.replaceAll('_', ' ').toUpperCase()), backgroundColor: emerald.withValues(alpha: .15), side: BorderSide(color: emerald.withValues(alpha: .35))),
            if ((p['verified_badge'] ?? 'none') != 'none') ...[const SizedBox(width: 6), const Icon(Icons.verified, color: gold, size: 20)],
          ]),
        ])),
        if ((p['bio'] ?? '').toString().trim().isNotEmpty) ...[
          const SizedBox(height: 16), Text(p['bio'].toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.5)),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: () => editProfile(p), icon: const Icon(Icons.edit_outlined), label: const Text('Edit profile'),
          style: FilledButton.styleFrom(backgroundColor: emerald, minimumSize: const Size.fromHeight(48))),
        const SizedBox(height: 18),
        if ((p['location'] ?? '').toString().isNotEmpty) ListTile(leading: const Icon(Icons.location_on_outlined, color: emerald), title: Text(p['location'].toString()), dense: true),
        if ((p['website_url'] ?? '').toString().isNotEmpty) ListTile(leading: const Icon(Icons.language, color: emerald), title: Text(p['website_url'].toString()), dense: true),
        if (p['skills'] is List && (p['skills'] as List).isNotEmpty) ListTile(leading: const Icon(Icons.auto_awesome_outlined, color: emerald), title: Text((p['skills'] as List).join(', ')), subtitle: const Text('Skills', style: TextStyle(color: muted)), dense: true),
        const SizedBox(height: 12),
        if (isAdmin) FeatureTile(icon: Icons.admin_panel_settings_outlined, title: 'Admin workspace', detail: 'Administrative tools for your account.', path: '/admin.html'),
        FeatureTile(icon: Icons.people_outline, title: 'Find members', detail: 'Discover people using CreatorVerse.', path: '/members'),
        FeatureTile(icon: Icons.settings_outlined, title: 'Account settings', detail: 'Review your account details.', path: '/settings'),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => db.auth.signOut(), icon: const Icon(Icons.logout), label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(foregroundColor: gold, minimumSize: const Size.fromHeight(50))),
      ]));
    });
}
class FeatureTile extends StatelessWidget {
  final IconData icon; final String title, detail, path;
  const FeatureTile({super.key, required this.icon, required this.title, required this.detail, required this.path});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(color: panel,
    borderRadius: BorderRadius.circular(16), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => openFeature(context, path),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: emerald.withValues(alpha: .13), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: emerald)),
        const SizedBox(width: 14), Expanded(child: material_widgets_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 4),
          Text(detail, style: const TextStyle(color: muted, fontSize: 12, height: 1.4))])),
        const Icon(Icons.chevron_right, color: muted)])))));
}

Future<void> openDirectMessage(BuildContext context, Map<String, dynamic> person) async {
  final db = Supabase.instance.client;
  final me = db.auth.currentUser?.id;
  final other = person['id']?.toString();
  if (me == null || other == null || me == other) return;
  try {
    final existing = await db.from('cv_conversations').select('id')
      .or('and(user_a.eq.$me,user_b.eq.$other),and(user_a.eq.$other,user_b.eq.$me)').maybeSingle();
    String id;
    if (existing != null) {
      id = existing['id'].toString();
    } else {
      final a = me.compareTo(other) < 0 ? me : other;
      final b = me.compareTo(other) < 0 ? other : me;
      final created = await db.from('cv_conversations')
        .insert({'user_a': a, 'user_b': b, 'created_by': me}).select('id').single();
      id = created['id'].toString();
    }
    if (!context.mounted) return;
    await material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) =>
      MessageThreadScreen(conversationId: id, person: person)));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open this conversation: $e')));
    }
  }
}

void openFeature(BuildContext context, String path) {
  if (path == '/certificates') {
    material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCertificatesScreen()));
    return;
  }
  if (path == '/academy-applications') {
    material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAcademyApplicationsScreen()));
    return;
  }
  if (path == '/messages.html' || path == '/messages') {
    material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => const MessageInboxScreen()));
    return;
  }
  if (path == '/notifications.html' || path == '/notifications') {
    material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Notifications')), body: const NotificationsScreen())));
    return;
  }
  Widget? destination;
  String title = 'CreatorVerse';
  switch (path) {
    case '/community.html':
      destination = const CommunityTab(); title = 'Community'; break;
    case '/digital-skills.html':
    case '/divisions.html':
      destination = const LearnTab(); title = 'Learn'; break;
    case '/academic.html':
      destination = const AcademicHubScreen(); title = 'Academic Learning'; break;
    case '/academic-secondary.html':
    case '/academic-tertiary.html':
      material_widgets_ui.Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AuthenticatedAcademyWebScreen(path: path)));
      return;
    case '/campus.html':
    case '/campus-life.html':
      destination = const CampusTab(); title = 'Campus Life'; break;
    case '/marketplace.html':
      destination = const MarketplaceScreen(); title = 'Marketplace'; break;
    case '/housing':
      destination = const MarketplaceFilteredScreen(listingType: 'rental', title: 'Verified Housing', description: 'Browse accommodation and rental listings published by verified CreatorVerse sellers.'); title = 'Verified Housing'; break;
    case '/delivery':
      destination = const MarketplaceFilteredScreen(listingType: 'service', title: 'Campus Services & Delivery', description: 'Browse approved services and delivery providers from verified campus sellers.'); title = 'Campus Services'; break;
    case '/profile.html':
      destination = const ProfileTab(); title = 'My profile'; break;
    case '/members':
      destination = const MemberDirectoryScreen(); title = 'Find members'; break;
    case '/settings':
      destination = const AccountSettingsScreen(); title = 'Account settings'; break;
    case '/admin.html':
      // Reuse the complete, role-protected website admin portal in an
      // authenticated WebView until every admin feature has a native screen.
      material_widgets_ui.Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const AuthenticatedAcademyWebScreen(
          path: '/admin.html',
        )));
      return;
    default:
      destination = NativeSpaceScreen(title: path.contains('marketplace') ? 'Marketplace' : 'Academic',
        description: 'This section is part of CreatorVerse. Its native app experience is being built next; your website account and data remain shared.',
        icon: path.contains('marketplace') ? Icons.storefront_outlined : Icons.school_outlined);
      title = path.contains('marketplace') ? 'Marketplace' : 'Academic';
  }
  material_widgets_ui.Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
    appBar: AppBar(title: Text(title)), body: destination!)));
}

class NativeSpaceScreen extends StatelessWidget {
  final String title, description; final IconData icon;
  const NativeSpaceScreen({super.key, required this.title, required this.description, required this.icon});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: material_widgets_ui.Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 54, color: emerald), const SizedBox(height: 18),
    Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
    const SizedBox(height: 10), Text(description, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.5)),
  ])));
}

class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});
  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}
class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  final db = Supabase.instance.client;
  final search = TextEditingController();
  late Future<List<Map<String, dynamic>>> members;
  @override
  void initState() { super.initState(); members = loadMembers(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }
  Future<List<Map<String, dynamic>>> loadMembers() async {
    var query = db.from('public_profiles').select('id,full_name,username,avatar_url,bio,location,verified_badge');
    final term = sanitizeSearchTerm(search.text);
    if (term.length >= 2) query = query.or('full_name.ilike.%$term%,username.ilike.%$term%');
    final rows = await query.neq('id', db.auth.currentUser!.id).limit(40);
    return List<Map<String, dynamic>>.from(rows);
  }
  void runSearch() => setState(() => members = loadMembers());
  @override
  Widget build(BuildContext context) => material_widgets_ui.Column(children: [
    Padding(padding: const EdgeInsets.all(16), child: TextField(controller: search, onSubmitted: (_) => runSearch(),
      decoration: InputDecoration(hintText: 'Search name or username', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: runSearch, icon: const Icon(Icons.arrow_forward, color: emerald))))),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: members, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
      if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Member directory unavailable: ${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: muted))));
      final rows = snap.data ?? [];
      if (rows.isEmpty) return const Center(child: Text('No members found.', style: TextStyle(color: muted)));
      return ListView.separated(itemCount: rows.length, separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
        itemBuilder: (context, index) {
          final p = rows[index]; final avatar = (p['avatar_url'] ?? '').toString();
          return ListTile(leading: CircleAvatar(backgroundColor: const Color(0x3320B887),
            backgroundImage: avatar.startsWith('https://') ? NetworkImage(avatar) : null,
            child: avatar.startsWith('https://') ? null : const Icon(Icons.person, color: emerald)),
            title: Row(children: [Flexible(child: Text((p['full_name'] ?? 'CreatorVerse member').toString(), overflow: TextOverflow.ellipsis)),
              if ((p['verified_badge'] ?? 'none') != 'none') const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified, color: gold, size: 16))]),
            subtitle: Text('@${p['username'] ?? 'member'}', style: const TextStyle(color: muted)),
            onTap: () => material_widgets_ui.Navigator.push(context, MaterialPageRoute(builder: (_) => PublicMemberProfileScreen(profile: p))));
        });
    })),
  ]);
}

class PublicMemberProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const PublicMemberProfileScreen({super.key, required this.profile});
  @override
  State<PublicMemberProfileScreen> createState() => _PublicMemberProfileScreenState();
}

class _PublicMemberProfileScreenState extends State<PublicMemberProfileScreen> {
  final db = Supabase.instance.client;
  bool? isFollowing;
  bool busy = false;
  int followerCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    loadRelationship();
  }

  Future<void> loadRelationship() async {
    final me = db.auth.currentUser?.id;
    final other = widget.profile['id']?.toString();
    if (me == null || other == null) return;
    try {
      final relation = await db.from('community_follows').select('follower_id')
        .eq('follower_id', me).eq('following_id', other).maybeSingle();
      final followers = await db.from('community_follows').select('follower_id')
        .eq('following_id', other).count(CountOption.exact);
      final following = await db.from('community_follows').select('following_id')
        .eq('follower_id', other).count(CountOption.exact);
      if (!mounted) return;
      setState(() {
        isFollowing = relation != null;
        followerCount = followers.count;
        followingCount = following.count;
      });
    } catch (_) {
      if (mounted) {
        setState(() => isFollowing = false);
      }
    }
  }

  Future<void> toggleFollow() async {
    final me = db.auth.currentUser?.id;
    final other = widget.profile['id']?.toString();
    if (me == null || other == null || busy || isFollowing == null) return;
    setState(() => busy = true);
    try {
      if (isFollowing!) {
        await db.from('community_follows').delete().eq('follower_id', me).eq('following_id', other);
        if (mounted) {
          setState(() { isFollowing = false; followerCount = (followerCount - 1).clamp(0, 1 << 30).toInt(); });
        }
      } else {
        await db.from('community_follows').insert({'follower_id': me, 'following_id': other});
        if (mounted) {
          setState(() { isFollowing = true; followerCount += 1; });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update follow status: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final avatar = (profile['avatar_url'] ?? '').toString();
    final me = db.auth.currentUser?.id;
    final ownProfile = me == profile['id']?.toString();
    return Scaffold(appBar: AppBar(title: const Text('Member profile')), body: ListView(padding: const EdgeInsets.all(22), children: [
      Center(child: CircleAvatar(radius: 44, backgroundColor: const Color(0x3320B887),
        backgroundImage: avatar.startsWith('https://') ? NetworkImage(avatar) : null,
        child: avatar.startsWith('https://') ? null : const Icon(Icons.person, color: emerald, size: 42))),
      const SizedBox(height: 14),
      Text((profile['full_name'] ?? 'CreatorVerse member').toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4), Text('@${profile['username'] ?? 'member'}', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
      if ((profile['verified_badge'] ?? 'none') != 'none') const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.verified, color: gold, size: 20)),
      if ((profile['bio'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 14), Text(profile['bio'].toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.5))],
      if ((profile['location'] ?? '').toString().isNotEmpty) ListTile(leading: const Icon(Icons.location_on_outlined, color: emerald), title: Text(profile['location'].toString())),
      if (profile['skills'] is List && (profile['skills'] as List).isNotEmpty) ListTile(leading: const Icon(Icons.auto_awesome_outlined, color: emerald), title: Text((profile['skills'] as List).join(', ')), subtitle: const Text('Skills', style: TextStyle(color: muted))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$followerCount followers', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 18), Text('$followingCount following', style: const TextStyle(color: muted)),
      ]),
      const SizedBox(height: 18),
      if (!ownProfile) Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: busy || isFollowing == null ? null : toggleFollow,
          icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(isFollowing == true ? Icons.person_remove_outlined : Icons.person_add_alt_1),
          label: Text(isFollowing == true ? 'Following' : 'Follow'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton.icon(onPressed: () => openDirectMessage(context, profile),
          icon: const Icon(Icons.chat_bubble_outline), label: const Text('Message'),
          style: FilledButton.styleFrom(backgroundColor: emerald))),
      ]),
    ]));
  }
}

Future<void> openLink(String path) async {
  await launchUrl(Uri.parse('https://creatorverse-ai.vercel.app$path'), mode: LaunchMode.externalApplication);
}
