// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://xgdngnekihhnkzurhvpe.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_RS7zMUhSXPJGooi8lQmMIQ_NyS4pS-h');
const ink = Color(0xFF07151A), panel = Color(0xFF102329), emerald = Color(0xFF18A878), gold = Color(0xFFE6BC55), muted = Color(0xFF9BAEAA);

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
    home: const AuthGate());
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 82, height: 82, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22)),
          child: SvgPicture.asset('assets/creatorverse-mark.svg'))),
        const SizedBox(height: 24),
        const Text('CREATORVERSE', textAlign: TextAlign.center, style: TextStyle(color: gold, letterSpacing: 3, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(create ? 'Create your account' : 'Welcome back', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Learning, creativity and campus life in one place.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
        const SizedBox(height: 28),
        Form(key: form, child: Column(children: [
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
      appBar: AppBar(title: Row(children: [SvgPicture.asset('assets/creatorverse-mark.svg', width: 30, height: 30),
        const SizedBox(width: 10), Text(labels[index], style: const TextStyle(fontWeight: FontWeight.w700))]),
        actions: [
          IconButton(tooltip: 'Messages', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessageInboxScreen())), icon: const Icon(Icons.chat_bubble_outline)),
          IconButton(tooltip: 'Notifications', onPressed: () => openLink('/notifications.html'), icon: const Icon(Icons.notifications_none))]),
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
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    final n = Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] as String?;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF123D35), panel]),
        border: Border.all(color: emerald.withValues(alpha: .3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('YOUR NEXT CHAPTER STARTS HERE', style: TextStyle(color: gold, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12), Text('Hello${n == null || n.isEmpty ? '' : ', $n'}.', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8), const Text('Learn new skills, explore opportunities and find your community.', style: TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 16), FilledButton(onPressed: () => openLink('/divisions.html'), style: FilledButton.styleFrom(backgroundColor: emerald), child: const Text('Explore CreatorVerse'))])),
      const SizedBox(height: 24), const Text('Explore your spaces', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      const FeatureTile(icon: Icons.auto_awesome_outlined, title: 'Digital Skills', detail: 'Build practical and creative skills.', path: '/digital-skills.html'),
      const FeatureTile(icon: Icons.school_outlined, title: 'Academic', detail: 'Find learning pathways and study resources.', path: '/academic.html'),
      const FeatureTile(icon: Icons.apartment_outlined, title: 'Campus Life', detail: 'Discover accommodation and campus services.', path: '/campus.html'),
      const FeatureTile(icon: Icons.storefront_outlined, title: 'Marketplace', detail: 'Explore the CreatorVerse marketplace.', path: '/marketplace.html'),
      const FeatureTile(icon: Icons.groups_outlined, title: 'Community', detail: 'Connect with other learners and creators.', path: '/community.html')]);
  }
}
class LearnTab extends StatefulWidget {
  const LearnTab({super.key});
  @override
  State<LearnTab> createState() => _LearnTabState();
}
class _LearnTabState extends State<LearnTab> {
  late Future<List<Map<String, dynamic>>> courses;
  @override
  void initState() { super.initState(); courses = loadCourses(); }
  Future<List<Map<String, dynamic>>> loadCourses() async {
    final rows = await Supabase.instance.client.from('courses')
      .select('id,slug,title,description,category_slug,level,duration_text,thumbnail_url,price_ngn,featured')
      .eq('published', true).order('featured', ascending: false).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
  void reload() => setState(() => courses = loadCourses());
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: courses,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: emerald));
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 42, color: muted),
          const SizedBox(height: 12), const Text('Courses could not be loaded', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8), const Text('Check your connection and try again.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
          const SizedBox(height: 16), OutlinedButton.icon(onPressed: reload, icon: const Icon(Icons.refresh), label: const Text('Try again')),
        ])));
      }
      final items = snapshot.data ?? [];
      return RefreshIndicator(color: emerald, onRefresh: () async => reload(),
        child: ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Learn and grow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Explore programmes published by CreatorVerse.', style: TextStyle(color: muted)),
          const SizedBox(height: 18),
          if (items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No published courses are available yet.', textAlign: TextAlign.center, style: TextStyle(color: muted))),
          for (final course in items) CourseCard(course: course),
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
        ), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (image != null && image.startsWith('https://'))
            Image.network(image, height: 150, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 90, color: const Color(0xFF17352F), child: const Icon(Icons.menu_book, color: emerald, size: 34))),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
  late Future<List<Map<String, dynamic>>> curriculum;
  @override
  void initState() { super.initState(); curriculum = loadCurriculum(); }
  Future<List<Map<String, dynamic>>> loadCurriculum() async {
    final db = Supabase.instance.client;
    final modulesRaw = await db.from('modules').select('id,title,description,position,duration_text,stage_number')
      .eq('course_id', widget.course['id']).order('position');
    final modules = List<Map<String, dynamic>>.from(modulesRaw);
    if (modules.isEmpty) return [];
    final ids = modules.map((m) => m['id']).toList();
    final lessonsRaw = await db.from('lessons')
      .select('id,module_id,title,video_url,content,position,estimated_minutes,chapter_number,topic_outline')
      .inFilter('module_id', ids).order('position');
    final lessons = List<Map<String, dynamic>>.from(lessonsRaw);
    for (final module in modules) {
      module['lessons'] = lessons.where((l) => l['module_id'] == module['id']).toList();
    }
    return modules;
  }
  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final price = (c['price_ngn'] as num?)?.toInt() ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Course overview')),
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
        const SizedBox(height: 22),
        const Text('Course curriculum', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(future: curriculum, builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(22), child: Center(child: CircularProgressIndicator(color: emerald)));
          if (snapshot.hasError) return const Text('The course outline is temporarily unavailable.', style: TextStyle(color: muted));
          final modules = snapshot.data ?? [];
          if (modules.isEmpty) return const Text('Course lessons are being prepared.', style: TextStyle(color: muted));
          return Column(children: [
            for (final module in modules) Card(color: panel, child: ExpansionTile(
              initiallyExpanded: false,
              title: Text((module['title'] ?? 'Module').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${(module['lessons'] as List).length} lessons', style: const TextStyle(color: muted, fontSize: 12)),
              children: [
                if ((module['description'] ?? '').toString().isNotEmpty)
                  Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Text(module['description'].toString(), style: const TextStyle(color: muted))),
                for (final lesson in module['lessons'] as List<Map<String, dynamic>>)
                  ListTile(
                    dense: true, leading: const Icon(Icons.play_circle_outline, color: emerald),
                    title: Text((lesson['title'] ?? 'Lesson').toString()),
                    subtitle: Text('${lesson['estimated_minutes'] ?? 0} min', style: const TextStyle(color: muted, fontSize: 11)),
                    trailing: lesson['video_url'] == null || lesson['video_url'].toString().isEmpty
                      ? null : const Icon(Icons.open_in_new, size: 16, color: muted),
                    onTap: () async {
                      final raw = lesson['video_url']?.toString() ?? '';
                      final uri = Uri.tryParse(raw);
                      if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else if ((lesson['content'] ?? '').toString().isNotEmpty && context.mounted) {
                        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: panel,
                          builder: (_) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Text(
                            '${lesson['title']}\n\n${lesson['content']}', style: const TextStyle(height: 1.55)))));
                      }
                    },
                  ),
              ],
            )),
          ]);
        }),
      ]),
    );
  }
}

class CampusTab extends StatelessWidget {
  const CampusTab({super.key});
  @override
  Widget build(BuildContext context) => const LinkPage(icon: Icons.location_city_outlined, title: 'Campus Life',
    description: 'Explore student accommodation, campus services and opportunities.', button: 'Explore Campus Life', path: '/campus.html');
}
class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});
  @override
  State<CommunityTab> createState() => _CommunityTabState();
}
class _CommunityTabState extends State<CommunityTab> {
  late Future<List<Map<String, dynamic>>> feed;
  final db = Supabase.instance.client;
  @override
  void initState() { super.initState(); feed = loadFeed(); }
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
    for (final post in posts) {
      final id = post['id'].toString();
      post['author'] = profiles[post['user_id'].toString()] ?? {};
      final postLikes = likes.where((l) => l['post_id'].toString() == id).toList();
      post['like_count'] = postLikes.length;
      post['liked'] = postLikes.any((l) => l['user_id'] == me);
      post['comment_count'] = comments.where((c) => c['post_id'].toString() == id).length;
    }
    return posts;
  }
  Future<void> refresh() async { final next = loadFeed(); setState(() => feed = next); await next; }
  Future<void> createPost() async {
    final title = TextEditingController(), body = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      backgroundColor: panel, title: const Text('Share with the community'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 120, decoration: const InputDecoration(labelText: 'Post title')),
        const SizedBox(height: 10), TextField(controller: body, minLines: 3, maxLines: 6, maxLength: 3000,
          decoration: const InputDecoration(labelText: 'What would you like to share?')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Publish'))]));
    if (ok != true) { title.dispose(); body.dispose(); return; }
    if (title.text.trim().length < 3 || body.text.trim().isEmpty) {
      title.dispose(); body.dispose();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title and some post content.')));
      return;
    }
    try {
      await db.from('community_posts').insert({'user_id': db.auth.currentUser!.id,
        'title': title.text.trim(), 'description': body.text.trim(), 'category': 'General', 'tags': <String>[], 'status': 'published'});
      title.dispose(); body.dispose(); await refresh();
    } catch (e) {
      title.dispose(); body.dispose();
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
  Future<void> showComments(Map<String, dynamic> post) async {
    await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: panel,
      builder: (_) => CommentsSheet(post: post));
    if (mounted) await refresh();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: feed, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, color: muted, size: 42), const SizedBox(height: 12),
        const Text('Community is unavailable right now.'), const SizedBox(height: 12),
        OutlinedButton(onPressed: () => setState(() => feed = loadFeed()), child: const Text('Try again'))])));
      final posts = snapshot.data ?? [];
      return RefreshIndicator(color: emerald, onRefresh: refresh, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        Row(children: [const Expanded(child: Text('Community', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
          FilledButton.icon(onPressed: createPost, icon: const Icon(Icons.add, size: 18), label: const Text('Post'),
            style: FilledButton.styleFrom(backgroundColor: emerald))]),
        const SizedBox(height: 6), const Text('Ideas, updates and conversations from CreatorVerse members.', style: TextStyle(color: muted)),
        const SizedBox(height: 16),
        if (posts.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Column(children: [
          Icon(Icons.forum_outlined, color: emerald, size: 44), SizedBox(height: 12),
          Text('Your community starts here', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          SizedBox(height: 6), Text('Be the first to share an update.', style: TextStyle(color: muted))])),
        for (final post in posts) CommunityPostCard(post: post, onLike: () => toggleLike(post), onComments: () => showComments(post)),
      ]));
    });
}
class CommunityPostCard extends StatelessWidget {
  final Map<String, dynamic> post; final VoidCallback onLike, onComments;
  const CommunityPostCard({super.key, required this.post, required this.onLike, required this.onComments});
  @override
  Widget build(BuildContext context) {
    final author = Map<String, dynamic>.from(post['author'] as Map? ?? {});
    final name = (author['full_name'] ?? author['username'] ?? 'CreatorVerse member').toString();
    final avatar = author['avatar_url']?.toString() ?? '';
    final image = post['image_url']?.toString() ?? '';
    return Container(margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          CircleAvatar(radius: 19, backgroundColor: emerald.withValues(alpha: .18),
            backgroundImage: avatar.startsWith('https://') ? NetworkImage(avatar) : null,
            child: avatar.startsWith('https://') ? null : const Icon(Icons.person, color: emerald, size: 20)),
          const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
              if (author['verified_badge']?.toString() != null && author['verified_badge'] != 'none') const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified, color: gold, size: 15))]),
            Text((post['category'] ?? 'Community').toString(), style: const TextStyle(color: muted, fontSize: 11))])),
          Text(_timeAgo(post['created_at']?.toString()), style: const TextStyle(color: muted, fontSize: 10)),
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
    child: SizedBox(height: MediaQuery.of(context).size.height * .72, child: Column(children: [
      const Text('Comments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12), Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: comments, builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: emerald));
        if (snap.hasError) return const Center(child: Text('Could not load comments.', style: TextStyle(color: muted)));
        final rows = snap.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('No comments yet. Start the conversation.', style: TextStyle(color: muted)));
        return ListView(children: [for (final row in rows) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(radius: 15, backgroundColor: Color(0x3320B887), child: Icon(Icons.person, size: 16, color: emerald)),
          const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          final q = query.text.trim(); if (q.length < 2) return;
          try {
            final found = await db.from('public_profiles').select('id,full_name,username,avatar_url')
              .or('full_name.ilike.%$q%,username.ilike.%$q%').neq('id', db.auth.currentUser!.id).limit(12);
            if (!mounted) return;
            Navigator.pop(ctx);
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
                        if (!mounted) return;
                        Navigator.pop(pickCtx);
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
      if (rows.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.chat_bubble_outline, color: emerald, size: 44), const SizedBox(height: 12),
        const Text('No conversations yet'), const SizedBox(height: 8),
        FilledButton.icon(onPressed: startChat, icon: const Icon(Icons.add), label: const Text('Start a conversation'))]));
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
    body: Column(children: [
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
}
class LinkPage extends StatelessWidget {
  final IconData icon; final String title, description, button, path;
  const LinkPage({super.key, required this.icon, required this.title, required this.description, required this.button, required this.path});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 54, color: emerald), const SizedBox(height: 18), Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
    const SizedBox(height: 10), Text(description, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.5)),
    const SizedBox(height: 22), FilledButton(onPressed: () => openLink(path), child: Text(button))])));
}
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser; final name = user?.userMetadata?['full_name'] as String?;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const CircleAvatar(radius: 34, backgroundColor: Color(0x3320B887), child: Icon(Icons.person, size: 34, color: emerald)),
      const SizedBox(height: 14), Text(name?.isNotEmpty == true ? name! : 'CreatorVerse member', textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4), Text(user?.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
      const SizedBox(height: 24), const FeatureTile(icon: Icons.account_circle_outlined, title: 'My profile', detail: 'Manage your profile.', path: '/profile.html'),
      const FeatureTile(icon: Icons.settings_outlined, title: 'Settings', detail: 'Account and platform preferences.', path: '/profile.html'),
      const SizedBox(height: 18), OutlinedButton.icon(onPressed: () => Supabase.instance.client.auth.signOut(),
        icon: const Icon(Icons.logout), label: const Text('Sign out'), style: OutlinedButton.styleFrom(foregroundColor: gold, minimumSize: const Size.fromHeight(50)))]);
  }
}
class FeatureTile extends StatelessWidget {
  final IconData icon; final String title, detail, path;
  const FeatureTile({super.key, required this.icon, required this.title, required this.detail, required this.path});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(color: panel,
    borderRadius: BorderRadius.circular(16), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => openLink(path),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: emerald.withValues(alpha: .13), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: emerald)),
        const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 4),
          Text(detail, style: const TextStyle(color: muted, fontSize: 12, height: 1.4))])),
        const Icon(Icons.chevron_right, color: muted)])))));
}
Future<void> openLink(String path) async {
  await launchUrl(Uri.parse('https://creatorverse-ai.vercel.app$path'), mode: LaunchMode.externalApplication);
}
