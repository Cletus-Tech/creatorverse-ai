// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart' as flutter_ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://xgdngnekihhnkzurhvpe.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_RS7zMUhSXPJGooi8lQmMIQ_NyS4pS-h');
const ink = Color(0xFF07151A), panel = Color(0xFF102329), emerald = Color(0xFF18A878), gold = Color(0xFFE6BC55), muted = Color(0xFF9BAEAA);

List<String> parseSkillsInput(String input) => input.split(',')
  .map((value) => value.trim()).where((value) => value.isNotEmpty).toList();

String sanitizeSearchTerm(String input) => input
  .replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ _-]'), ' ')
  .replaceAll(RegExp(r'\s+'), ' ').trim();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(const CreatorVerseApp());
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

class CreatorVerseLaunchGate extends StatefulWidget {
  const CreatorVerseLaunchGate({super.key});
  @override
  State<CreatorVerseLaunchGate> createState() => _CreatorVerseLaunchGateState();
}
class _CreatorVerseLaunchGateState extends State<CreatorVerseLaunchGate> {
  Timer? _dismissTimer;
  bool _showGate = true;
  @override
  void initState() {
    super.initState();
    // Mirrors the website's short branded loading handoff.
    _dismissTimer = Timer(const Duration(milliseconds: 1250), () {
      if (mounted) setState(() => _showGate = false);
    });
  }
  @override
  void dispose() { _dismissTimer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    const AuthGate(),
    IgnorePointer(
      ignoring: !_showGate,
      child: AnimatedOpacity(
        opacity: _showGate ? 1 : 0,
        duration: const Duration(milliseconds: 340),
        child: _showGate ? const _CreatorVerseLoadingGate() : const SizedBox.shrink(),
      ),
    ),
  ]);
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
  void dispose() { email.dispose(); password.dispose(); name.dispose(); super.dispose(); }
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
      child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
        Form(key: form, child: flutter_ui.Column(children: [
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
        const SizedBox(height: 18),
        const Text('Your existing CreatorVerse website account works here too.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
      ]))))));
}
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int index = 0;
  static const labels = ['Home', 'Learn', 'Campus', 'Community', 'Profile'];
  @override
  Widget build(BuildContext context) {
    const pages = [HomeTab(), LearnTab(), CampusTab(), CommunityTab(), ProfileTab()];
    return Scaffold(
      appBar: AppBar(title: Row(children: [SvgPicture.asset('assets/creatorverse-brand.svg', width: 30, height: 30),
        const SizedBox(width: 10), Text(labels[index], style: const TextStyle(fontWeight: FontWeight.w700))]),
        actions: [
          IconButton(tooltip: 'Messages', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessageInboxScreen())), icon: const Icon(Icons.chat_bubble_outline)),
          IconButton(tooltip: 'Notifications', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Notifications')), body: const NotificationsScreen()))), icon: const Icon(Icons.notifications_none))]),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v),
        backgroundColor: panel, indicatorColor: emerald.withValues(alpha: .2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.location_city_outlined), selectedIcon: Icon(Icons.location_city), label: 'Campus'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile')]));
  }
}
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override State<HomeTab> createState()=>_HomeTabState();
}
class _HomeTabState extends State<HomeTab>{
  late Future<Map<String,dynamic>> summary;
  @override void initState(){super.initState();summary=loadSummary();}
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
        child:flutter_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
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
  @override
  void initState() { super.initState(); courses = loadCourses(); }
  Future<List<Map<String, dynamic>>> loadCourses() async {
    final rows = await Supabase.instance.client.from('courses')
      .select('id,slug,title,description,category_slug,level,duration_text,thumbnail_url,price_ngn,featured')
      .eq('published', true).order('featured', ascending: false).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
  @override void dispose() { search.dispose(); super.dispose(); }
  Future<void> reload() async { final next = loadCourses(); setState(() => courses = next); await next; }
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: courses,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: emerald));
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
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
      child: InkWell(onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CourseDetailScreen(course: course)),
        ), child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (image != null && image.startsWith('https://'))
            Image.network(image, height: 150, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 90, color: const Color(0xFF17352F), child: const Icon(Icons.menu_book, color: emerald, size: 34))),
          Padding(padding: const EdgeInsets.all(16), child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text((course['level'] ?? 'Course').toString(), style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w700))),
              Text(price == 0 ? 'FREE' : '₦${price.toString()}', style: const TextStyle(color: emerald, fontWeight: FontWeight.w800)),
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
  bool enrolling = false;
  @override
  void initState() { super.initState(); enrollment = loadEnrollment(); curriculum = loadCurriculum(); quizzes = loadQuizzes(); }

  Future<bool> loadEnrollment() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    final row = await Supabase.instance.client.from('enrolments').select('course_id')
      .eq('user_id', user.id).eq('course_id', widget.course['id']).maybeSingle();
    return row != null;
  }

  void refreshCourse() => setState(() { enrollment = loadEnrollment(); curriculum = loadCurriculum(); quizzes = loadQuizzes(); });

  Future<void> enrolFreeCourse() async {
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;
    if (user == null || enrolling) return;
    if (((widget.course['price_ngn'] as num?)?.toInt() ?? 0) != 0) return;
    setState(() => enrolling = true);
    try {
      await db.from('enrolments').insert({'user_id': user.id, 'course_id': widget.course['id']});
      if (!mounted) return;
      setState(() { enrollment = Future.value(true); curriculum = loadCurriculum(); quizzes = loadQuizzes(); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are enrolled. Start learning!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not enrol: $e')));
    } finally {
      if (mounted) setState(() => enrolling = false);
    }
  }
  Future<List<Map<String, dynamic>>> loadCurriculum() async {
    final db = Supabase.instance.client;
    final modulesRaw = await db.from('modules').select('id,title,description,position,duration_text,stage_number')
      .eq('course_id', widget.course['id']).order('position');
    final modules = List<Map<String, dynamic>>.from(modulesRaw);
    if (modules.isEmpty) return [];
    final ids = modules.map((m) => m['id']).toList();
    final user = db.auth.currentUser;
    final enrolled = user != null && await db.from('enrolments').select('course_id')
      .eq('user_id', user.id).eq('course_id', widget.course['id']).maybeSingle() != null;
    if (!enrolled) {
      for (final module in modules) { module['lessons'] = <Map<String,dynamic>>[]; }
      return modules;
    }
    final lessonsRaw = await db.from('lessons')
      .select('id,module_id,title,video_url,content,position,estimated_minutes,chapter_number,topic_outline')
      .inFilter('module_id', ids).order('position');
    final lessons = List<Map<String, dynamic>>.from(lessonsRaw);
    if (lessons.isNotEmpty) {
      final lessonIds = lessons.map((l) => l['id']).toList();
      final resourcesRaw = await db.from('lesson_resources').select('id,lesson_id,title,url,position')
        .inFilter('lesson_id', lessonIds).order('position');
      final resources = List<Map<String,dynamic>>.from(resourcesRaw);
      final progressRaw = await db.from('lesson_progress').select('lesson_id,completed_at')
        .eq('user_id', user.id).inFilter('lesson_id', lessonIds);
      final completed = List<Map<String,dynamic>>.from(progressRaw).map((r)=>r['lesson_id'].toString()).toSet();
      for (final lesson in lessons) {
        lesson['resources'] = resources.where((r)=>r['lesson_id']==lesson['id']).toList();
        lesson['completed'] = completed.contains(lesson['id'].toString());
      }
    }
    for (final module in modules) {
      module['lessons'] = lessons.where((l) => l['module_id'] == module['id']).toList();
    }
    return modules;
  }

  Future<List<Map<String,dynamic>>> loadQuizzes() async {
    final rows = await db.from('quizzes').select('id,title,pass_mark')
      .eq('course_id',widget.course['id']).order('created_at');
    return List<Map<String,dynamic>>.from(rows);
  }

  Future<void> openLesson(Map<String,dynamic> lesson) async {
    final db=Supabase.instance.client;
    try {
      await db.rpc('record_academy_lesson_view',params:{'p_lesson_id':lesson['id']});
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
      appBar: AppBar(title: const Text('Course overview'), actions: [IconButton(onPressed: refreshCourse, tooltip: 'Refresh enrolment', icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text((c['title'] ?? '').toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text((c['description'] ?? '').toString(), style: const TextStyle(color: muted, height: 1.5)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Chip(label: Text((c['level'] ?? 'All levels').toString())),
          Chip(label: Text((c['duration_text'] ?? 'Self-paced').toString())),
          Chip(label: Text(price == 0 ? 'Free course' : '₦${price.toString()}')),
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
          if (price == 0) {
            return FilledButton.icon(onPressed: enrolling ? null : enrolFreeCourse,
            icon: enrolling ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.school_outlined),
              label: Text(enrolling ? 'Enrolling…' : 'Enrol in free course'), style: FilledButton.styleFrom(backgroundColor: emerald));
          }
          return flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const ListTile(leading: Icon(Icons.lock_outline, color: gold), title: Text('Paid course'),
              subtitle: Text('Payment and administrator verification are required before course access.', style: TextStyle(color: muted))),
            OutlinedButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => CourseCheckoutScreen(course: c))); if (mounted) refreshCourse(); },
              icon: const Icon(Icons.payments_outlined), label: const Text('View payment options')),
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
          return flutter_ui.Column(children: [
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
            return flutter_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Course assessments',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
              const SizedBox(height:8),
              for(final quiz in items)Card(color:panel,child:ListTile(
                leading:const Icon(Icons.quiz_outlined,color:gold),
                title:Text((quiz['title']??'Course quiz').toString()),
                subtitle:Text('Pass mark: ${quiz['pass_mark']}%',style:const TextStyle(color:muted)),
                trailing:const Icon(Icons.chevron_right,color:emerald),
                onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseQuizScreen(quizId:quiz['id'].toString()))),
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
        actions:[FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Continue'))])); }
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
        Card(color:panel,child:Padding(padding:const EdgeInsets.all(14),child:flutter_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
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
      else OutlinedButton.icon(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back),label:const Text('Back to course')),
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
      .select('id,method,status,reference,expires_at,transfer_reference,admin_note,created_at')
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
        'reference': 'CV-MOBILE-PENDING',
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

  Future<void> submitReference(Map<String, dynamic> order) async {
    final reference = transferReference.text.trim();
    if (reference.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the transaction reference from your bank or USSD receipt.')));
      return;
    }
    setState(() => submitting = true);
    try {
      await db.from('payment_orders').update({
        'transfer_reference': reference,
        'status': 'proof_submitted',
      }).eq('id', order['id']).eq('user_id', db.auth.currentUser!.id);
      if (!mounted) return;
      setState(() => checkout = loadCheckout());
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
        final orderStatus = (order?['status'] ?? '').toString();
        final expiry = DateTime.tryParse((order?['expires_at'] ?? '').toString());
        final expired = expiry != null && expiry.isBefore(DateTime.now()) && orderStatus != 'confirmed';
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text((widget.course['title'] ?? 'Course').toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Amount due: ₦${price.toString()}', style: const TextStyle(color: gold, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (orderStatus == 'confirmed') const Card(color: panel, child: ListTile(
            leading: Icon(Icons.check_circle, color: emerald),
            title: Text('Payment confirmed'),
            subtitle: Text('Your course enrolment has been activated.', style: TextStyle(color: muted)))),
          if (order != null && orderStatus != 'confirmed') ...[
            Card(color: panel, child: Padding(padding: const EdgeInsets.all(16), child: flutter_ui.Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expired ? 'Payment window expired' : 'Payment request · $orderStatus',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Reference: ${order['reference']}', style: const TextStyle(color: muted)),
                if (expiry != null) Text('Deadline: ${expiry.toLocal()}', style: const TextStyle(color: muted, fontSize: 12)),
                if (!expired && orderStatus == 'pending') ...[
                  const SizedBox(height: 12),
                  TextField(controller: transferReference, decoration: const InputDecoration(labelText: 'Bank / USSD transaction reference')),
                  const SizedBox(height: 10),
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
            if (bankEnabled) Card(color: panel, child: Padding(padding: const EdgeInsets.all(16), child: flutter_ui.Column(
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
            if (ussdEnabled) Card(color: panel, child: Padding(padding: const EdgeInsets.all(16), child: flutter_ui.Column(
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
      child: const flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
  @override
  void initState() { super.initState(); catalogue = loadCatalogue(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

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
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: flutter_ui.Column(
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
      return flutter_ui.Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 10), child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Campus Marketplace', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5), const Text('Discover approved products and services from the CreatorVerse community.', style: TextStyle(color: muted)),
          const SizedBox(height: 12), TextField(controller: search, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search listings or campus')),
          const SizedBox(height: 10),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceSellerScreen())).then((_) => retry()),
              icon: const Icon(Icons.storefront_outlined), label: const Text('Sell')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceSavedScreen())),
              icon: const Icon(Icons.bookmark_border), label: const Text('Saved')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceEnquiriesScreen())),
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
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceListingScreen(listing: item))),
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
        if(items.isEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:44),child:flutter_ui.Column(children:[
          Icon(widget.listingType=='rental'?Icons.home_work_outlined:Icons.delivery_dining_outlined,color:emerald,size:42),
          const SizedBox(height:10),Text(all.isEmpty?'No approved listings have been published yet.':'No listings match your search.',style:const TextStyle(color:muted),textAlign:TextAlign.center),
          const SizedBox(height:8),const Text('Only verified sellers and administrator-approved listings appear here.',style:TextStyle(color:muted,fontSize:11),textAlign:TextAlign.center),
        ])),
        for(final item in items)Card(color:panel,child:ListTile(
          leading:const Icon(Icons.storefront_outlined,color:emerald,size:30),
          title:Text((item['title']??'Listing').toString(),style:const TextStyle(fontWeight:FontWeight.w700)),
          subtitle:Text('${item['campus']??item['institution']??item['location_label']??''}\n${item['description']??''}',maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted)),
          trailing:Text(item['price_ngn']==null?'Ask':(item['price_ngn']==0?'FREE':'₦${item['price_ngn']}'),style:const TextStyle(color:emerald,fontWeight:FontWeight.w800)),
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MarketplaceListingScreen(listing:item))),
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
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send enquiry')),
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceEnquiryThreadScreen(enquiryId: id.toString())));
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
      content: SizedBox(width: 440, child: SingleChildScrollView(child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
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
      actions: [TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('Submit for review'))],
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
        'listing_type': type, 'price_ngn': priceText.isEmpty ? null : int.parse(priceText),
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
      onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MarketplaceListingScreen(listing:item))),
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
        onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MarketplaceEnquiryThreadScreen(enquiryId:item['id'].toString()))).then((_)=>refresh()),
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
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Keep open')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Close enquiry'))]));
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
      body:flutter_ui.Column(children:[
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
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Continue'))]));
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
        for(final s in sellers)Card(color:panel,child:Padding(padding:const EdgeInsets.all(12),child:flutter_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text((s['display_name']??'Seller').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
          Text('${s['seller_type']} · ${s['campus']??''} · ${s['institution']??''}',style:const TextStyle(color:muted,fontSize:12)),
          if((s['bio']??'').toString().isNotEmpty)Text(s['bio'].toString(),style:const TextStyle(height:1.4)),
          Row(children:[Expanded(child:OutlinedButton(onPressed:busy?null:()=>reviewSeller(s,'rejected'),child:const Text('Reject'))),
            const SizedBox(width:8),Expanded(child:FilledButton(onPressed:busy?null:()=>reviewSeller(s,'verified'),style:FilledButton.styleFrom(backgroundColor:emerald),child:const Text('Verify')))]),
        ]))),
        const SizedBox(height:20),const Text('Listings awaiting approval',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
        if(listings.isEmpty)const Padding(padding:EdgeInsets.all(10),child:Text('No listings awaiting review.',style:TextStyle(color:muted))),
        for(final l in listings)Card(color:panel,child:Padding(padding:const EdgeInsets.all(12),child:flutter_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
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
  @override
  void initState() { super.initState(); feed = loadFeed(); stories = loadStories(); }
  Future<List<Map<String, dynamic>>> loadFeed() async {
    final raw = await db.from('community_posts')
      .select('id,user_id,title,description,image_url,destination_url,category,tags,created_at')
      .eq('status', 'published').order('created_at', ascending: false).limit(40);
    final posts = List<Map<String, dynamic>>.from(raw);
    if (posts.isEmpty) return posts;
    final ids = posts.map((p) => p['id'].toString()).toList();
    final users = posts.map((p) => p['user_id'].toString()).toSet().toList();
    final profilesRaw = await db.from('public_profiles')
      .select('id,full_name,username,avatar_url,verified_badge').inFilter('id', users);
    final profiles = {for (final p in List<Map<String, dynamic>>.from(profilesRaw)) p['id'].toString(): p};
    final likesRaw = await db.from('community_likes').select('post_id,user_id').inFilter('post_id', ids);
    final likes = List<Map<String, dynamic>>.from(likesRaw);
    final commentsRaw = await db.from('community_comments').select('post_id').inFilter('post_id', ids);
    final comments = List<Map<String, dynamic>>.from(commentsRaw);
    final me = db.auth.currentUser?.id;
    final savesRaw = me == null ? <Map<String,dynamic>>[] : List<Map<String,dynamic>>.from(
      await db.from('community_saves').select('post_id').eq('user_id',me).inFilter('post_id',ids));
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
    for(final row in rows){row['author']=byId[row['user_id'].toString()]??{};}
    return rows;
  }
  Future<void> refresh() async {
    final nextFeed=loadFeed(),nextStories=loadStories();
    setState((){feed=nextFeed;stories=nextStories;});
    await Future.wait([nextFeed,nextStories]);
  }
  Future<void> createStory() async {
    final input=TextEditingController();XFile? photo;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(backgroundColor:panel,title:const Text('Share a 24-hour story'),
      content:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:input,minLines:3,maxLines:5,maxLength:500,decoration:const InputDecoration(hintText:'Add a message (optional with a photo)')),
        const SizedBox(height:8),TextButton.icon(onPressed:()async{final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:82,maxWidth:1600);if(picked!=null)setDialog(()=>photo=picked);},
          icon:const Icon(Icons.add_photo_alternate_outlined),label:Text(photo==null?'Add a photo':'Photo: ${photo!.name}')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Share story'))])));
    if(!mounted){input.dispose();return;}
    final content=input.text.trim();input.dispose();
    if(ok!=true)return;
    if(content.isEmpty&&photo==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Add a message or photo to your story.')));return;}
    try{
      final userId=db.auth.currentUser!.id;String? mediaUrl;
      if(photo!=null){
        final ext=photo!.name.split('.').last.toLowerCase();
        final safeExt=['png','webp','gif'].contains(ext)?ext:'jpg';
        final mime=safeExt=='png'?'image/png':safeExt=='webp'?'image/webp':safeExt=='gif'?'image/gif':'image/jpeg';
        final path='$userId/stories/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
        await db.storage.from('community-media').uploadBinary(path,await photo!.readAsBytes(),fileOptions:FileOptions(contentType:mime));
        mediaUrl=db.storage.from('community-media').getPublicUrl(path);
      }
      final now=DateTime.now().toUtc();
      await db.from('cv_stories').insert({'user_id':userId,'content':content,'media_url':mediaUrl,
        'media_type':mediaUrl==null?'text':'image','background':'#123D35','expires_at':now.add(const Duration(hours:24)).toIso8601String()});
      await refresh();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not publish story: $e')));}
  }
  Future<void> viewStory(Map<String,dynamic> story) async {
    final me=db.auth.currentUser?.id;
    if(me!=null&&story['user_id']!=me){
      try{await db.from('cv_story_views').insert({'story_id':story['id'],'viewer_id':me});}catch(_){}
    }
    if(!mounted)return;
    final author=Map<String,dynamic>.from(story['author'] as Map? ?? {});
    await showModalBottomSheet<void>(context:context,backgroundColor:panel,isScrollControlled:true,
      builder:(_)=>SafeArea(child:Padding(padding:const EdgeInsets.all(24),child:flutter_ui.Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((author['full_name']??author['username']??'CreatorVerse member').toString(),style:const TextStyle(color:gold,fontWeight:FontWeight.w800)),
        const SizedBox(height:8),
        if((story['media_url']??'').toString().startsWith('https://') && story['media_type']=='image')
          ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.network(story['media_url'].toString(),fit:BoxFit.cover)),
        if((story['media_url']??'').toString().startsWith('https://') && story['media_type']=='video')
          OutlinedButton.icon(onPressed:()=>launchUrl(Uri.parse(story['media_url'].toString()),mode:LaunchMode.externalApplication),icon:const Icon(Icons.play_circle_outline),label:const Text('Open story video')),
        if((story['content']??'').toString().isNotEmpty)Text((story['content']??'').toString(),style:const TextStyle(fontSize:20,height:1.5)),
        const SizedBox(height:18),Align(alignment:Alignment.centerRight,child:Text(_timeAgo(story['created_at']?.toString()),style:const TextStyle(color:muted,fontSize:11))),
      ]))));
  }
  Future<void> createPost() async {
    final title = TextEditingController(), body = TextEditingController();XFile? photo;
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder:(dialogContext,setDialog)=>AlertDialog(
      backgroundColor: panel, title: const Text('Share with the community'),
      content: SizedBox(width: 420, child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 120, decoration: const InputDecoration(labelText: 'Post title')),
        const SizedBox(height: 10), TextField(controller: body, minLines: 3, maxLines: 6, maxLength: 3000,
          decoration: const InputDecoration(labelText: 'What would you like to share?')),
        const SizedBox(height:8),TextButton.icon(onPressed:()async{final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:82,maxWidth:1600);if(picked!=null)setDialog(()=>photo=picked);},
          icon:const Icon(Icons.add_photo_alternate_outlined),label:Text(photo==null?'Add a photo':'Photo: ${photo!.name}')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Publish'))])));
    if (!mounted) { title.dispose(); body.dispose(); return; }
    if (ok != true) { title.dispose(); body.dispose(); return; }
    final titleText=title.text.trim(),bodyText=body.text.trim();title.dispose();body.dispose();
    if (titleText.length < 3 || (bodyText.isEmpty&&photo==null)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title and some post content or a photo.')));
      return;
    }
    try {
      final userId=db.auth.currentUser!.id;String? imageUrl;
      if(photo!=null){
        final ext=photo!.name.split('.').last.toLowerCase();
        final safeExt=['png','webp','gif'].contains(ext)?ext:'jpg';
        final mime=safeExt=='png'?'image/png':safeExt=='webp'?'image/webp':safeExt=='gif'?'image/gif':'image/jpeg';
        final path='$userId/posts/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
        await db.storage.from('community-media').uploadBinary(path,await photo!.readAsBytes(),fileOptions:FileOptions(contentType:mime));
        imageUrl=db.storage.from('community-media').getPublicUrl(path);
      }
      await db.from('community_posts').insert({'user_id':userId,'title':titleText,'description':bodyText,
        'image_url':imageUrl,'category':'General','tags':<String>[],'status':'published'});
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
      content:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:reason,decoration:const InputDecoration(labelText:'Reason'),
          items:const [DropdownMenuItem(value:'spam',child:Text('Spam or misleading')),DropdownMenuItem(value:'harassment',child:Text('Harassment or bullying')),
            DropdownMenuItem(value:'scam',child:Text('Scam or fraud')),DropdownMenuItem(value:'inappropriate',child:Text('Inappropriate content')),
            DropdownMenuItem(value:'other',child:Text('Other'))],
          onChanged:(v)=>setDialog(()=>reason=v??reason)),
        const SizedBox(height:10),TextField(controller:details,maxLines:3,maxLength:500,decoration:const InputDecoration(labelText:'Additional details (optional)')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Submit report'))])));
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
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, color: muted, size: 42), const SizedBox(height: 12),
          const Text('Community is unavailable right now.'), const SizedBox(height: 12),
          OutlinedButton(onPressed: () => setState(() => feed = loadFeed()), child: const Text('Try again'))])));
      }
      final posts = snapshot.data ?? [];
      return RefreshIndicator(color: emerald, onRefresh: refresh, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        Row(children: [const Expanded(child: Text('Community', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
          TextButton.icon(onPressed:createStory,icon:const Icon(Icons.add_circle_outline,color:gold,size:18),label:const Text('Story')),
          const SizedBox(width:4),
          FilledButton.icon(onPressed: createPost, icon: const Icon(Icons.add, size: 18), label: const Text('Post'),
            style: FilledButton.styleFrom(backgroundColor: emerald))]),
        const SizedBox(height: 6), const Text('Ideas, updates and conversations from CreatorVerse members.', style: TextStyle(color: muted)),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String,dynamic>>>(future:stories,builder:(context,storySnap){
          final items=storySnap.data??[];
          return SizedBox(height:104,child:ListView(scrollDirection:Axis.horizontal,children:[
            InkWell(onTap:createStory,child:Container(width:78,margin:const EdgeInsets.only(right:10),child:flutter_ui.Column(children:[
              Container(width:62,height:62,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:gold,width:2),color:panel),child:const Icon(Icons.add,color:gold,size:28)),
              const SizedBox(height:6),const Text('Your story',style:TextStyle(fontSize:10,color:muted)),
            ]))),
            for(final story in items)InkWell(onTap:()=>viewStory(story),child:Container(width:78,margin:const EdgeInsets.only(right:10),child:flutter_ui.Column(children:[
              Container(width:62,height:62,padding:const EdgeInsets.all(3),decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:emerald,width:2)),
                child:CircleAvatar(backgroundColor:const Color(0xFF174B3B),child:Text((((story['author'] as Map?)?['full_name']??(story['author'] as Map?)?['username']??'C').toString().isEmpty?'C':((story['author'] as Map?)?['full_name']??(story['author'] as Map?)?['username']??'C').toString()[0].toUpperCase()),style:const TextStyle(color:gold,fontWeight:FontWeight.w800)))),
              const SizedBox(height:6),Text(((story['author'] as Map?)?['full_name']??(story['author'] as Map?)?['username']??'Member').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:muted)),
            ]))),
          ]));
        }),
        const SizedBox(height: 14),
        if (posts.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: flutter_ui.Column(children: [
          Icon(Icons.forum_outlined, color: emerald, size: 44), SizedBox(height: 12),
          Text('Your community starts here', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          SizedBox(height: 6), Text('Be the first to share an update.', style: TextStyle(color: muted))])),
        for (final post in posts) CommunityPostCard(post: post, onLike: () => toggleLike(post), onComments: () => showComments(post), onSave: () => toggleSave(post), onReport: () => reportPost(post)),
      ]));
    });
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
      child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          CircleAvatar(radius: 19, backgroundColor: emerald.withValues(alpha: .18),
            backgroundImage: avatar.startsWith('https://') ? NetworkImage(avatar) : null,
            child: avatar.startsWith('https://') ? null : const Icon(Icons.person, color: emerald, size: 20)),
          const SizedBox(width: 10), Expanded(child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
              if (author['verified_badge']?.toString() != null && author['verified_badge'] != 'none') const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified, color: gold, size: 15))]),
            Text((post['category'] ?? 'Community').toString(), style: const TextStyle(color: muted, fontSize: 11))])),
          Text(_timeAgo(post['created_at']?.toString()), style: const TextStyle(color: muted, fontSize: 10)),
          PopupMenuButton<String>(onSelected:(value){if(value=='report')onReport();},itemBuilder:(_)=>const [
            PopupMenuItem(value:'report',child:Row(children:[Icon(Icons.flag_outlined,size:18),SizedBox(width:8),Text('Report post')]))]),

        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text((post['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        Padding(padding: const EdgeInsets.fromLTRB(14, 7, 14, 12), child: Text((post['description'] ?? '').toString(), style: const TextStyle(color: Colors.white70, height: 1.45))),
        if (image.startsWith('https://')) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(image, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink())),
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
    child: SizedBox(height: MediaQuery.of(context).size.height * .72, child: flutter_ui.Column(children: [
      const Text('Comments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12), Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: comments, builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
        if (snap.hasError) return const Center(child: Text('Could not load comments.', style: TextStyle(color: muted)));
        final rows = snap.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('No comments yet. Start the conversation.', style: TextStyle(color: muted)));
        return ListView(children: [for (final row in rows) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(radius: 15, backgroundColor: Color(0x3320B887), child: Icon(Icons.person, size: 16, color: emerald)),
          const SizedBox(width: 9), Expanded(child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
  late Future<List<Map<String, dynamic>>> inbox;
  @override
  void initState() { super.initState(); inbox = loadInbox(); }
  Future<List<Map<String, dynamic>>> loadInbox() async {
    final me = db.auth.currentUser!.id;
    final raw = await db.from('cv_conversations').select('id,user_a,user_b,last_message_at')
      .or('user_a.eq.$me,user_b.eq.$me').order('last_message_at', ascending: false);
    final conversations = List<Map<String, dynamic>>.from(raw);
    if (conversations.isEmpty) return [];
    final ids = conversations.map((c) => c['id'].toString()).toList();
    final otherIds = conversations.map((c) => (c['user_a'] == me ? c['user_b'] : c['user_a']).toString()).toSet().toList();
    final peopleRaw = await db.from('public_profiles').select('id,full_name,username,avatar_url').inFilter('id', otherIds);
    final people = {for (final p in List<Map<String, dynamic>>.from(peopleRaw)) p['id'].toString(): p};
    final msgRaw = await db.from('cv_direct_messages').select('conversation_id,body,sender_id,created_at,read_at')
      .inFilter('conversation_id', ids).order('created_at', ascending: false);
    final latest = <String, Map<String, dynamic>>{};
    for (final m in List<Map<String, dynamic>>.from(msgRaw)) { latest.putIfAbsent(m['conversation_id'].toString(), () => m); }
    for (final c in conversations) {
      c['person'] = people[(c['user_a'] == me ? c['user_b'] : c['user_a']).toString()] ?? {};
      c['latest'] = latest[c['id'].toString()];
    }
    return conversations;
  }
  Future<void> startChat() async {
    final query = TextEditingController();
    await showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: panel, title: const Text('Find a member'),
      content: SizedBox(width: 420, child: TextField(controller: query, decoration: const InputDecoration(hintText: 'Search by name or username'))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final q = sanitizeSearchTerm(query.text); if (q.length < 2) return;
          try {
            final found = await db.from('public_profiles').select('id,full_name,username,avatar_url')
              .or('full_name.ilike.%$q%,username.ilike.%$q%').neq('id', db.auth.currentUser!.id).limit(12);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
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
                        Navigator.pop(pickCtx);
                        if (!mounted) return;
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => MessageThreadScreen(conversationId: id, person: person)));
                        if (mounted) setState(() => inbox = loadInbox());
                      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start chat: $e'))); }
                    }),
              ]))));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e'))); }
        }, child: const Text('Search'))]));
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Messages'), actions: [
    IconButton(onPressed: startChat, tooltip: 'New message', icon: const Icon(Icons.edit_square, color: gold))]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: inbox, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
      if (snap.hasError) return Center(child: Text('Messages could not load: ${snap.error}', style: const TextStyle(color: muted)));
      final rows = snap.data ?? [];
      if (rows.isEmpty) {
        return Center(child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_bubble_outline, color: emerald, size: 44), const SizedBox(height: 12),
          const Text('No conversations yet'), const SizedBox(height: 8),
          FilledButton.icon(onPressed: startChat, icon: const Icon(Icons.add), label: const Text('Start a conversation'))]));
      }
      return ListView.separated(itemCount: rows.length, separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
        itemBuilder: (context, i) {
          final c = rows[i], person = Map<String, dynamic>.from(c['person'] as Map? ?? {}), latest = c['latest'] as Map?;
          final name = (person['full_name'] ?? person['username'] ?? 'CreatorVerse member').toString();
          return ListTile(leading: const CircleAvatar(backgroundColor: Color(0x3320B887), child: Icon(Icons.person, color: emerald)),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text((latest?['body'] ?? 'Start a conversation').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted)),
            trailing: const Icon(Icons.chevron_right, color: muted),
            onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => MessageThreadScreen(conversationId: c['id'].toString(), person: person))); if (mounted) setState(() => inbox = loadInbox()); });
        });
    }));
}
class MessageThreadScreen extends StatefulWidget {
  final String conversationId; final Map<String, dynamic> person;
  const MessageThreadScreen({super.key, required this.conversationId, required this.person});
  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}
class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final db = Supabase.instance.client, input = TextEditingController();
  late Future<List<Map<String, dynamic>>> messages;
  bool sending = false;
  @override
  void initState() { super.initState(); messages = loadMessages(); }
  @override
  void dispose() { input.dispose(); super.dispose(); }
  Future<List<Map<String, dynamic>>> loadMessages() async {
    final raw = await db.from('cv_direct_messages').select('id,sender_id,body,created_at,read_at')
      .eq('conversation_id', widget.conversationId).order('created_at');
    return List<Map<String, dynamic>>.from(raw);
  }
  Future<void> send() async {
    final body = input.text.trim(); if (body.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await db.from('cv_direct_messages').insert({'conversation_id': widget.conversationId, 'sender_id': db.auth.currentUser!.id, 'body': body});
      input.clear(); setState(() => messages = loadMessages());
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message not sent: $e'))); }
    finally { if (mounted) setState(() => sending = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text((widget.person['full_name'] ?? widget.person['username'] ?? 'Chat').toString())),
    body: flutter_ui.Column(children: [
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: messages, builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
        if (snap.hasError) return const Center(child: Text('Could not load this conversation.', style: TextStyle(color: muted)));
        final rows = snap.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('Say hello to start the conversation.', style: TextStyle(color: muted)));
        return ListView(padding: const EdgeInsets.all(14), children: [for (final m in rows) Align(
          alignment: m['sender_id'] == db.auth.currentUser!.id ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(constraints: const BoxConstraints(maxWidth: 300), margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(color: m['sender_id'] == db.auth.currentUser!.id ? const Color(0xFF155E48) : panel,
              borderRadius: BorderRadius.circular(15)),
            child: Text(m['body'].toString(), style: const TextStyle(height: 1.35))))]);
      })),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 10), child: Row(children: [
        Expanded(child: TextField(controller: input, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'Message...'))),
        const SizedBox(width: 8), IconButton(onPressed: sending ? null : send,
          icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: emerald)),
      ]))),
    ]));
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
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: flutter_ui.Column(
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
        color: panel, child: Padding(padding: const EdgeInsets.all(14), child: flutter_ui.Column(
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
          FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Payment review')), body: const AdminPaymentReviewScreen()))),
            icon: const Icon(Icons.fact_check_outlined), label: const Text('Review payment requests'),
            style: FilledButton.styleFrom(backgroundColor: emerald, minimumSize: const Size.fromHeight(46))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceAdminScreen())),
            icon: const Icon(Icons.store_mall_directory_outlined), label: const Text('Manage Marketplace')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseAdminScreen())),
            icon: const Icon(Icons.menu_book_outlined), label: const Text('Manage Courses & Lessons')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityModerationScreen())),
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
      content:SizedBox(width:440,child:SingleChildScrollView(child:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Course title')),
        const SizedBox(height:8),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Description')),
        const SizedBox(height:8),TextField(controller:category,decoration:const InputDecoration(labelText:'Category slug (e.g. digital-skills)')),
        const SizedBox(height:8),DropdownButtonFormField<String>(value:level,decoration:const InputDecoration(labelText:'Level'),
          items:const [DropdownMenuItem(value:'Beginner',child:Text('Beginner')),DropdownMenuItem(value:'Intermediate',child:Text('Intermediate')),DropdownMenuItem(value:'Advanced',child:Text('Advanced'))],
          onChanged:(v)=>setDialog(()=>level=v??level)),
        const SizedBox(height:8),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Price in naira (0 for free)')),
        const SizedBox(height:8),TextField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Duration in months (1–36)')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Create draft'))])));
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
        'level':level,'price_ngn':int.parse(p),'duration_months':int.parse(months),'duration_text':'${months} months',
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
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(backgroundColor:panel,title:const Text('Edit course'),
      content:SingleChildScrollView(child:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),
        const SizedBox(height:8),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Description')),
        const SizedBox(height:8),TextField(controller:category,decoration:const InputDecoration(labelText:'Category slug')),
        const SizedBox(height:8),DropdownButtonFormField<String>(value:level,decoration:const InputDecoration(labelText:'Level'),
          items:const [DropdownMenuItem(value:'Beginner',child:Text('Beginner')),DropdownMenuItem(value:'Intermediate',child:Text('Intermediate')),DropdownMenuItem(value:'Advanced',child:Text('Advanced'))],
          onChanged:(v)=>setDialog(()=>level=v??level)),
        const SizedBox(height:8),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Price in naira')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save changes'))])));
    if(!mounted){title.dispose();description.dispose();category.dispose();price.dispose();return;}
    final t=title.text.trim(),d=description.text.trim(),cat=category.text.trim(),p=price.text.trim();
    title.dispose();description.dispose();category.dispose();price.dispose();if(ok!=true)return;
    if(t.length<4||d.length<10||int.tryParse(p)==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Check the course title, description and price.')));return;}
    final slug=t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'),'-').replaceAll(RegExp(r'^-+|-+
    setState(()=>busy=true);
    try{await db.from('courses').update({field:!(course[field]==true)}).eq('id',course['id']);await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update course: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
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
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseModulesAdminScreen(course:course))).then((_)=>refresh())),
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
      content:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Module title')),
        const SizedBox(height:8),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Description')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save'))]));
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
      content:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Module title')),
        const SizedBox(height:8),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Module description')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Add module'))]));
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
        for(final module in rows)Card(color:panel,child:ListTile(title:Text((module['title']??'Module').toString()),
          subtitle:Text('${(module['lessons'] as List? ?? []).length} lessons · Stage ${module['stage_number']}',style:const TextStyle(color:muted)),
          trailing:IconButton(onPressed:busy?null:()=>editModule(module),icon:const Icon(Icons.edit_outlined,color:gold)),
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseLessonsAdminScreen(module:module))).then((_)=>refresh()))),
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
      content:SizedBox(width:440,child:SingleChildScrollView(child:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Lesson title')),
        const SizedBox(height:8),TextField(controller:content,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Lesson content')),
        const SizedBox(height:8),TextField(controller:video,decoration:const InputDecoration(labelText:'Video URL')),
        const SizedBox(height:8),TextField(controller:minutes,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Estimated minutes')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save changes'))]));
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
      content:SizedBox(width:440,child:SingleChildScrollView(child:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Lesson title')),
        const SizedBox(height:8),TextField(controller:content,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Lesson content / notes')),
        const SizedBox(height:8),TextField(controller:video,decoration:const InputDecoration(labelText:'Video URL (optional)')),
        const SizedBox(height:8),TextField(controller:minutes,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Estimated minutes (5–600)')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Add lesson'))]));
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
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Hide post'))]));
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
        for(final item in items)Card(color:panel,child:Padding(padding:const EdgeInsets.all(14),child:flutter_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
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
  @override
  State<AdminPaymentReviewScreen> createState() => _AdminPaymentReviewScreenState();
}

class _AdminPaymentReviewScreenState extends State<AdminPaymentReviewScreen> {
  final db = Supabase.instance.client;
  final Map<String, String> notes = {};
  late Future<List<Map<String, dynamic>>> orders;
  String filter = 'pending';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    orders = loadOrders();
  }

  Future<List<Map<String, dynamic>>> loadOrders() async {
    final user = db.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to continue.');
    }
    final profile = await db.from('profiles').select('role').eq('id', user.id).single();
    final role = (profile['role'] ?? '').toString();
    if (role != 'admin' && role != 'super_admin') {
      throw StateError('Administrator access is required.');
    }
    final rows = await db.from('payment_orders')
      .select('id,user_id,amount_ngn,status,reference,created_at,expires_at,transfer_reference,proof_url,admin_note,courses(title)')
      .order('created_at', ascending: false).limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> refresh() async {
    final next = loadOrders();
    setState(() => orders = next);
    await next;
  }

  Future<void> updateOrder(Map<String, dynamic> order, String status) async {
    final id = order['id'].toString();
    final message = notes[id]?.trim() ?? (order['admin_note'] ?? '').toString().trim();
    if (status == 'confirmed') {
      final verified = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        title: const Text('Confirm payment received?'),
        content: const Text('Only confirm after you have checked the actual bank or USSD transaction and verified that the full amount arrived. This will activate the course enrolment.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: emerald), child: const Text('I verified the payment')),
        ],
      ));
      if (verified != true) return;
    }
    setState(() => busy = true);
    try {
      await db.from('payment_orders').update({
        'status': status,
        'admin_note': message.isEmpty ? null : message,
      }).eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        status == 'confirmed' ? 'Payment confirmed. Course enrolment is activated by the database workflow.' : 'Payment request rejected.')));
      await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update payment request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: orders,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: emerald));
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(
          'Payment review is unavailable: ${snapshot.error}',
          textAlign: TextAlign.center, style: const TextStyle(color: muted))));
      }
      final all = snapshot.data ?? [];
      final visible = filter == 'all' ? all : all.where((o) => o['status'] == filter).toList();
      return flutter_ui.Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: filter,
            decoration: const InputDecoration(labelText: 'Payment status'),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'proof_submitted', child: Text('Proof submitted')),
              DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              DropdownMenuItem(value: 'expired', child: Text('Expired')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              DropdownMenuItem(value: 'all', child: Text('All statuses')),
            ],
            onChanged: busy ? null : (value) => setState(() => filter = value ?? 'pending'),
          )),
          const SizedBox(width: 8),
          IconButton(onPressed: busy ? null : refresh, icon: const Icon(Icons.refresh)),
        ])),
        Expanded(child: visible.isEmpty
          ? const Center(child: Text('No payment requests in this status.', style: TextStyle(color: muted)))
          : ListView.builder(padding: const EdgeInsets.all(14), itemCount: visible.length, itemBuilder: (context, index) {
              final order = visible[index];
              final id = order['id'].toString();
              final course = order['courses'] is Map ? order['courses']['title'] : 'Course payment';
              final active = order['status'] == 'pending' || order['status'] == 'proof_submitted';
              final expiry = DateTime.tryParse((order['expires_at'] ?? '').toString());
              return Card(color: panel, margin: const EdgeInsets.only(bottom: 12), child: Padding(
                padding: const EdgeInsets.all(14), child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((course ?? 'Course payment').toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text('₦${order['amount_ngn']} · ${order['status']}', style: const TextStyle(color: gold, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text('Reference: ${order['reference']}', style: const TextStyle(color: muted, fontSize: 12)),
                  if ((order['transfer_reference'] ?? '').toString().isNotEmpty)
                    Text('Transfer reference: ${order['transfer_reference']}', style: const TextStyle(color: muted, fontSize: 12)),
                  if (expiry != null) Text('Expires: ${expiry.toLocal()}', style: const TextStyle(color: muted, fontSize: 12)),
                  if ((order['proof_url'] ?? '').toString().startsWith('https://'))
                    TextButton.icon(onPressed: () => launchUrl(Uri.parse(order['proof_url'].toString()), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.receipt_long_outlined), label: const Text('View payment proof')),
                  if (active) ...[
                    const SizedBox(height: 8),
                    TextFormField(initialValue: (order['admin_note'] ?? '').toString(),
                      decoration: const InputDecoration(labelText: 'Optional note to student'),
                      onChanged: (value) => notes[id] = value),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: FilledButton(onPressed: busy ? null : () => updateOrder(order, 'confirmed'),
                        style: FilledButton.styleFrom(backgroundColor: emerald), child: const Text('Confirm received'))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: busy ? null : () => updateOrder(order, 'rejected'),
                        child: const Text('Reject'))),
                    ]),
                  ],
                ]),
              ));
            })),
      ]);
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

  @override
  void initState() {
    super.initState();
    notifications = loadNotifications();
  }

  Future<List<Map<String, dynamic>>> loadNotifications() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }
    final rows = await db.from('cv_notifications')
      .select('id,type,title,body,href,entity_type,entity_id,created_at,read_at,actor_id')
      .eq('user_id', userId).order('created_at', ascending: false).limit(60);
    return List<Map<String, dynamic>>.from(rows);
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
    try {
      await db.from('cv_notifications').update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', item['id']).eq('user_id', db.auth.currentUser!.id);
      if (mounted) {
        await refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update notification: $e')));
      }
    }
  }

  Future<void> openNotification(Map<String, dynamic> item) async {
    await markRead(item);
    if (!mounted) return;
    final href = (item['href'] ?? '').toString().trim();
    if (href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (uri.path.endsWith('/marketplace-enquiries.html') || uri.path == 'marketplace-enquiries.html') {
      final enquiryId = uri.queryParameters['id'];
      if (enquiryId != null && enquiryId.isNotEmpty) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceEnquiryThreadScreen(enquiryId: enquiryId)));
      } else {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceEnquiriesScreen()));
      }
      return;
    }
    var path = uri.path;
    if (!path.startsWith('/')) path = '/$path';
    if (path == '/messages.html' || path == '/messages') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const MessageInboxScreen()));
    } else {
      openFeature(context, path);
    }
  }

  Future<void> markAllRead(List<Map<String, dynamic>> items) async {
    final unread = items.where((item) => item['read_at'] == null).toList();
    if (unread.isEmpty) {
      return;
    }
    try {
      await db.from('cv_notifications').update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', db.auth.currentUser!.id).isFilter('read_at', null);
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
      return RefreshIndicator(color: emerald, onRefresh: refresh, child: flutter_ui.Column(children: [
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
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
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
  @override
  void initState() { super.initState(); profile = loadProfile(); }
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
          content: SizedBox(width: 440, child: SingleChildScrollView(child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10), TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 10), TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
            const SizedBox(height: 10), TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 10), TextField(controller: website, decoration: const InputDecoration(labelText: 'Website URL')),
            const SizedBox(height: 10), TextField(controller: skills, decoration: const InputDecoration(labelText: 'Skills')),
            const SizedBox(height: 10), TextField(controller: status, decoration: const InputDecoration(labelText: 'Status')),
          ]))),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
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
                Navigator.pop(dialogContext);
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
      if (snapshot.hasError) { return Center(child: Padding(padding: const EdgeInsets.all(24), child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
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
        Center(child: flutter_ui.Column(children: [
          CircleAvatar(radius: 42, backgroundColor: const Color(0x3320B887),
            backgroundImage: avatar.startsWith('https://') ? NetworkImage(avatar) : null,
            child: avatar.startsWith('https://') ? null : const Icon(Icons.person, size: 40, color: emerald)),
          const SizedBox(height: 13),
          Text(name.isEmpty ? 'CreatorVerse member' : name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          if ((p['username'] ?? '').toString().isNotEmpty) Text('@${p['username']}', style: const TextStyle(color: muted)),
          const SizedBox(height: 4), Text(user?.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Chip(label: Text(role.replaceAll('_', ' ').toUpperCase()), backgroundColor: emerald.withValues(alpha: .15), side: BorderSide(color: emerald.withValues(alpha: .35))),
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
        const SizedBox(width: 14), Expanded(child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    await Navigator.push(context, MaterialPageRoute(builder: (_) =>
      MessageThreadScreen(conversationId: id, person: person)));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open this conversation: $e')));
    }
  }
}

void openFeature(BuildContext context, String path) {
  if (path == '/messages.html' || path == '/messages') {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MessageInboxScreen()));
    return;
  }
  if (path == '/notifications.html' || path == '/notifications') {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
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
      destination = const NativeSpaceScreen(title: 'Secondary School', description: 'Secondary school examination resources and organised subject learning are being prepared for the native app.', icon: Icons.school_outlined); title = 'Secondary School'; break;
    case '/academic-tertiary.html':
      destination = const NativeSpaceScreen(title: 'Tertiary Institutions', description: 'University and higher-institution academic resources are being prepared for the native app.', icon: Icons.account_balance_outlined); title = 'Tertiary Institutions'; break;
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
      destination = const AdminWorkspaceScreen(); title = 'Admin workspace'; break;
    default:
      destination = NativeSpaceScreen(title: path.contains('marketplace') ? 'Marketplace' : 'Academic',
        description: 'This section is part of CreatorVerse. Its native app experience is being built next; your website account and data remain shared.',
        icon: path.contains('marketplace') ? Icons.storefront_outlined : Icons.school_outlined);
      title = path.contains('marketplace') ? 'Marketplace' : 'Academic';
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
    appBar: AppBar(title: Text(title)), body: destination!)));
}

class NativeSpaceScreen extends StatelessWidget {
  final String title, description; final IconData icon;
  const NativeSpaceScreen({super.key, required this.title, required this.description, required this.icon});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
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
    var query = db.from('public_profiles').select('id,full_name,username,avatar_url,bio,location,verified_badge,role');
    final term = sanitizeSearchTerm(search.text);
    if (term.length >= 2) query = query.or('full_name.ilike.%$term%,username.ilike.%$term%');
    final rows = await query.neq('id', db.auth.currentUser!.id).limit(40);
    return List<Map<String, dynamic>>.from(rows);
  }
  void runSearch() => setState(() => members = loadMembers());
  @override
  Widget build(BuildContext context) => flutter_ui.Column(children: [
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
            subtitle: Text('@${p['username'] ?? 'member'} · ${p['role'] ?? 'student'}', style: const TextStyle(color: muted)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicMemberProfileScreen(profile: p))));
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
),'');
    setState(()=>busy=true);
    try{await db.from('courses').update({'title':t,'slug':slug,'description':d,'category_slug':cat.isEmpty?null:cat,'level':level,'price_ngn':int.parse(p)}).eq('id',course['id']);await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update course: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> toggleCourse(Map<String,dynamic> course,String field) async {
    setState(()=>busy=true);
    try{await db.from('courses').update({field:!(course[field]==true)}).eq('id',course['id']);await refresh();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not update course: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
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
            trailing:const Icon(Icons.chevron_right,color:emerald),
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseModulesAdminScreen(course:course))).then((_)=>refresh())),
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
  Future<void> addModule() async {
    final title=TextEditingController(),description=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Add course module'),
      content:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Module title')),
        const SizedBox(height:8),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Module description')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Add module'))]));
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
        for(final module in rows)Card(color:panel,child:ListTile(title:Text((module['title']??'Module').toString()),
          subtitle:Text('${(module['lessons'] as List? ?? []).length} lessons · Stage ${module['stage_number']}',style:const TextStyle(color:muted)),
          trailing:const Icon(Icons.chevron_right,color:emerald),
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CourseLessonsAdminScreen(module:module))).then((_)=>refresh()))),
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
  Future<void> addLesson() async {
    final title=TextEditingController(),content=TextEditingController(),video=TextEditingController(),minutes=TextEditingController(text:'30');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('Add lesson'),
      content:SizedBox(width:440,child:SingleChildScrollView(child:flutter_ui.Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Lesson title')),
        const SizedBox(height:8),TextField(controller:content,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Lesson content / notes')),
        const SizedBox(height:8),TextField(controller:video,decoration:const InputDecoration(labelText:'Video URL (optional)')),
        const SizedBox(height:8),TextField(controller:minutes,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Estimated minutes (5–600)')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Add lesson'))]));
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
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Hide post'))]));
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
        for(final item in items)Card(color:panel,child:Padding(padding:const EdgeInsets.all(14),child:flutter_ui.Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
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
  @override
  State<AdminPaymentReviewScreen> createState() => _AdminPaymentReviewScreenState();
}

class _AdminPaymentReviewScreenState extends State<AdminPaymentReviewScreen> {
  final db = Supabase.instance.client;
  final Map<String, String> notes = {};
  late Future<List<Map<String, dynamic>>> orders;
  String filter = 'pending';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    orders = loadOrders();
  }

  Future<List<Map<String, dynamic>>> loadOrders() async {
    final user = db.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to continue.');
    }
    final profile = await db.from('profiles').select('role').eq('id', user.id).single();
    final role = (profile['role'] ?? '').toString();
    if (role != 'admin' && role != 'super_admin') {
      throw StateError('Administrator access is required.');
    }
    final rows = await db.from('payment_orders')
      .select('id,user_id,amount_ngn,status,reference,created_at,expires_at,transfer_reference,proof_url,admin_note,courses(title)')
      .order('created_at', ascending: false).limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> refresh() async {
    final next = loadOrders();
    setState(() => orders = next);
    await next;
  }

  Future<void> updateOrder(Map<String, dynamic> order, String status) async {
    final id = order['id'].toString();
    final message = notes[id]?.trim() ?? (order['admin_note'] ?? '').toString().trim();
    if (status == 'confirmed') {
      final verified = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        title: const Text('Confirm payment received?'),
        content: const Text('Only confirm after you have checked the actual bank or USSD transaction and verified that the full amount arrived. This will activate the course enrolment.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: emerald), child: const Text('I verified the payment')),
        ],
      ));
      if (verified != true) return;
    }
    setState(() => busy = true);
    try {
      await db.from('payment_orders').update({
        'status': status,
        'admin_note': message.isEmpty ? null : message,
      }).eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        status == 'confirmed' ? 'Payment confirmed. Course enrolment is activated by the database workflow.' : 'Payment request rejected.')));
      await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update payment request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: orders,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: emerald));
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(
          'Payment review is unavailable: ${snapshot.error}',
          textAlign: TextAlign.center, style: const TextStyle(color: muted))));
      }
      final all = snapshot.data ?? [];
      final visible = filter == 'all' ? all : all.where((o) => o['status'] == filter).toList();
      return flutter_ui.Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: filter,
            decoration: const InputDecoration(labelText: 'Payment status'),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'proof_submitted', child: Text('Proof submitted')),
              DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              DropdownMenuItem(value: 'expired', child: Text('Expired')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              DropdownMenuItem(value: 'all', child: Text('All statuses')),
            ],
            onChanged: busy ? null : (value) => setState(() => filter = value ?? 'pending'),
          )),
          const SizedBox(width: 8),
          IconButton(onPressed: busy ? null : refresh, icon: const Icon(Icons.refresh)),
        ])),
        Expanded(child: visible.isEmpty
          ? const Center(child: Text('No payment requests in this status.', style: TextStyle(color: muted)))
          : ListView.builder(padding: const EdgeInsets.all(14), itemCount: visible.length, itemBuilder: (context, index) {
              final order = visible[index];
              final id = order['id'].toString();
              final course = order['courses'] is Map ? order['courses']['title'] : 'Course payment';
              final active = order['status'] == 'pending' || order['status'] == 'proof_submitted';
              final expiry = DateTime.tryParse((order['expires_at'] ?? '').toString());
              return Card(color: panel, margin: const EdgeInsets.only(bottom: 12), child: Padding(
                padding: const EdgeInsets.all(14), child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((course ?? 'Course payment').toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text('₦${order['amount_ngn']} · ${order['status']}', style: const TextStyle(color: gold, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text('Reference: ${order['reference']}', style: const TextStyle(color: muted, fontSize: 12)),
                  if ((order['transfer_reference'] ?? '').toString().isNotEmpty)
                    Text('Transfer reference: ${order['transfer_reference']}', style: const TextStyle(color: muted, fontSize: 12)),
                  if (expiry != null) Text('Expires: ${expiry.toLocal()}', style: const TextStyle(color: muted, fontSize: 12)),
                  if ((order['proof_url'] ?? '').toString().startsWith('https://'))
                    TextButton.icon(onPressed: () => launchUrl(Uri.parse(order['proof_url'].toString()), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.receipt_long_outlined), label: const Text('View payment proof')),
                  if (active) ...[
                    const SizedBox(height: 8),
                    TextFormField(initialValue: (order['admin_note'] ?? '').toString(),
                      decoration: const InputDecoration(labelText: 'Optional note to student'),
                      onChanged: (value) => notes[id] = value),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: FilledButton(onPressed: busy ? null : () => updateOrder(order, 'confirmed'),
                        style: FilledButton.styleFrom(backgroundColor: emerald), child: const Text('Confirm received'))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: busy ? null : () => updateOrder(order, 'rejected'),
                        child: const Text('Reject'))),
                    ]),
                  ],
                ]),
              ));
            })),
      ]);
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

  @override
  void initState() {
    super.initState();
    notifications = loadNotifications();
  }

  Future<List<Map<String, dynamic>>> loadNotifications() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }
    final rows = await db.from('cv_notifications')
      .select('id,type,title,body,href,entity_type,entity_id,created_at,read_at,actor_id')
      .eq('user_id', userId).order('created_at', ascending: false).limit(60);
    return List<Map<String, dynamic>>.from(rows);
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
    try {
      await db.from('cv_notifications').update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', item['id']).eq('user_id', db.auth.currentUser!.id);
      if (mounted) {
        await refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update notification: $e')));
      }
    }
  }

  Future<void> openNotification(Map<String, dynamic> item) async {
    await markRead(item);
    if (!mounted) return;
    final href = (item['href'] ?? '').toString().trim();
    if (href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (uri.path.endsWith('/marketplace-enquiries.html') || uri.path == 'marketplace-enquiries.html') {
      final enquiryId = uri.queryParameters['id'];
      if (enquiryId != null && enquiryId.isNotEmpty) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceEnquiryThreadScreen(enquiryId: enquiryId)));
      } else {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceEnquiriesScreen()));
      }
      return;
    }
    var path = uri.path;
    if (!path.startsWith('/')) path = '/$path';
    if (path == '/messages.html' || path == '/messages') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const MessageInboxScreen()));
    } else {
      openFeature(context, path);
    }
  }

  Future<void> markAllRead(List<Map<String, dynamic>> items) async {
    final unread = items.where((item) => item['read_at'] == null).toList();
    if (unread.isEmpty) {
      return;
    }
    try {
      await db.from('cv_notifications').update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', db.auth.currentUser!.id).isFilter('read_at', null);
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
      return RefreshIndicator(color: emerald, onRefresh: refresh, child: flutter_ui.Column(children: [
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
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
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
  @override
  void initState() { super.initState(); profile = loadProfile(); }
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
          content: SizedBox(width: 440, child: SingleChildScrollView(child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10), TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 10), TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
            const SizedBox(height: 10), TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 10), TextField(controller: website, decoration: const InputDecoration(labelText: 'Website URL')),
            const SizedBox(height: 10), TextField(controller: skills, decoration: const InputDecoration(labelText: 'Skills')),
            const SizedBox(height: 10), TextField(controller: status, decoration: const InputDecoration(labelText: 'Status')),
          ]))),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
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
                Navigator.pop(dialogContext);
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
      if (snapshot.hasError) { return Center(child: Padding(padding: const EdgeInsets.all(24), child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
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
        Center(child: flutter_ui.Column(children: [
          CircleAvatar(radius: 42, backgroundColor: const Color(0x3320B887),
            backgroundImage: avatar.startsWith('https://') ? NetworkImage(avatar) : null,
            child: avatar.startsWith('https://') ? null : const Icon(Icons.person, size: 40, color: emerald)),
          const SizedBox(height: 13),
          Text(name.isEmpty ? 'CreatorVerse member' : name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          if ((p['username'] ?? '').toString().isNotEmpty) Text('@${p['username']}', style: const TextStyle(color: muted)),
          const SizedBox(height: 4), Text(user?.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Chip(label: Text(role.replaceAll('_', ' ').toUpperCase()), backgroundColor: emerald.withValues(alpha: .15), side: BorderSide(color: emerald.withValues(alpha: .35))),
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
        const SizedBox(width: 14), Expanded(child: flutter_ui.Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    await Navigator.push(context, MaterialPageRoute(builder: (_) =>
      MessageThreadScreen(conversationId: id, person: person)));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open this conversation: $e')));
    }
  }
}

void openFeature(BuildContext context, String path) {
  if (path == '/messages.html' || path == '/messages') {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MessageInboxScreen()));
    return;
  }
  if (path == '/notifications.html' || path == '/notifications') {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
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
      destination = const NativeSpaceScreen(title: 'Secondary School', description: 'Secondary school examination resources and organised subject learning are being prepared for the native app.', icon: Icons.school_outlined); title = 'Secondary School'; break;
    case '/academic-tertiary.html':
      destination = const NativeSpaceScreen(title: 'Tertiary Institutions', description: 'University and higher-institution academic resources are being prepared for the native app.', icon: Icons.account_balance_outlined); title = 'Tertiary Institutions'; break;
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
      destination = const AdminWorkspaceScreen(); title = 'Admin workspace'; break;
    default:
      destination = NativeSpaceScreen(title: path.contains('marketplace') ? 'Marketplace' : 'Academic',
        description: 'This section is part of CreatorVerse. Its native app experience is being built next; your website account and data remain shared.',
        icon: path.contains('marketplace') ? Icons.storefront_outlined : Icons.school_outlined);
      title = path.contains('marketplace') ? 'Marketplace' : 'Academic';
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
    appBar: AppBar(title: Text(title)), body: destination!)));
}

class NativeSpaceScreen extends StatelessWidget {
  final String title, description; final IconData icon;
  const NativeSpaceScreen({super.key, required this.title, required this.description, required this.icon});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: flutter_ui.Column(mainAxisSize: MainAxisSize.min, children: [
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
    var query = db.from('public_profiles').select('id,full_name,username,avatar_url,bio,location,verified_badge,role');
    final term = sanitizeSearchTerm(search.text);
    if (term.length >= 2) query = query.or('full_name.ilike.%$term%,username.ilike.%$term%');
    final rows = await query.neq('id', db.auth.currentUser!.id).limit(40);
    return List<Map<String, dynamic>>.from(rows);
  }
  void runSearch() => setState(() => members = loadMembers());
  @override
  Widget build(BuildContext context) => flutter_ui.Column(children: [
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
            subtitle: Text('@${p['username'] ?? 'member'} · ${p['role'] ?? 'student'}', style: const TextStyle(color: muted)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicMemberProfileScreen(profile: p))));
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
