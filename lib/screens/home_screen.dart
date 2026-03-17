import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/common_widgets.dart';
import 'detail_screen.dart';
import 'create_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Post> _posts = [];
  List<Post> _filtered = [];
  bool _loading = true;
  bool _deleting = false;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _loadPosts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────
  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await ApiService.getPosts();
      setState(() {
        _posts = posts;
        _filtered = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _search(String query) {
    setState(() {
      _searchQuery = query;
      _filtered = query.isEmpty
          ? _posts
          : _posts
              .where((p) =>
                  p.title.toLowerCase().contains(query.toLowerCase()) ||
                  p.body.toLowerCase().contains(query.toLowerCase()) ||
                  p.id.toString().contains(query))
              .toList();
    });
  }

  // ── Navigation ───────────────────────────────────────────────────
  void _openDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          post: post,
          onEdit: () => _openEdit(post),
          onDelete: () => _deletePost(post),
        ),
      ),
    );
  }

  void _openCreate() async {
    final created = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (_) => const CreateEditScreen()),
    );
    if (created != null && mounted) {
      setState(() {
        _posts.insert(0, created);
        _search(_searchQuery);
      });
      AppSnackbar.show(context,
          message: 'Post created successfully!', isSuccess: true);
    }
  }

  void _openEdit(Post post) async {
    final updated = await Navigator.push<Post>(
      context,
      MaterialPageRoute(
          builder: (_) => CreateEditScreen(existingPost: post)),
    );
    if (updated != null && mounted) {
      setState(() {
        final idx = _posts.indexWhere((p) => p.id == updated.id);
        if (idx != -1) _posts[idx] = updated;
        _search(_searchQuery);
      });
      AppSnackbar.show(context,
          message: 'Post updated successfully!', isSuccess: true);
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirmed =
        await ConfirmDeleteDialog.show(context, post.title);
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ApiService.deletePost(post.id);
      setState(() {
        _posts.removeWhere((p) => p.id == post.id);
        _search(_searchQuery);
        _deleting = false;
      });
      if (mounted) {
        AppSnackbar.show(context,
            message: 'Post deleted.', isError: false);
      }
    } catch (e) {
      setState(() => _deleting = false);
      if (mounted) {
        AppSnackbar.show(context,
            message: 'Failed to delete: $e', isError: true);
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      body: LoadingOverlay(
        isLoading: _deleting,
        message: 'Deleting post...',
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            if (!_loading && _error == null && _posts.isNotEmpty)
              SliverToBoxAdapter(child: _buildStats()),
            _buildBody(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.navyGradient),
          child: FadeTransition(
            opacity: _headerFade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Dot decoration
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.indigo,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'POSTS MANAGER',
                        style: TextStyle(
                          color: AppTheme.indigo,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'All Posts',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppTheme.white),
          tooltip: 'Refresh',
          onPressed: _loadPosts,
        ),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _search,
          decoration: InputDecoration(
            hintText: 'Search posts by title, content or ID...',
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppTheme.slate, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        size: 18, color: AppTheme.slate),
                    onPressed: () {
                      _searchCtrl.clear();
                      _search('');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          StatsBadge(
            label: 'Total Posts',
            value: '${_posts.length}',
            icon: Icons.article_outlined,
            color: AppTheme.indigo,
          ),
          const SizedBox(width: 10),
          StatsBadge(
            label: 'Showing',
            value: '${_filtered.length}',
            icon: Icons.filter_list_rounded,
            color: AppTheme.success,
          ),
          const Spacer(),
          if (_searchQuery.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.indigoLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$_searchQuery"',
                style: const TextStyle(
                  color: AppTheme.indigo,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: ShimmerCard(),
            ),
            childCount: 6,
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: ErrorView(message: _error!, onRetry: _loadPosts),
      );
    }

    if (_filtered.isEmpty) {
      return SliverFillRemaining(
        child: EmptyView(
          title: _searchQuery.isNotEmpty
              ? 'No results found'
              : 'No posts yet',
          subtitle: _searchQuery.isNotEmpty
              ? 'Try different keywords'
              : 'Tap the + button to create your first post',
          onAction: _searchQuery.isEmpty ? _openCreate : null,
          actionLabel: 'Create Post',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PostCard(
              post: _filtered[i],
              index: i,
              onTap: () => _openDetail(_filtered[i]),
              onEdit: () => _openEdit(_filtered[i]),
              onDelete: () => _deletePost(_filtered[i]),
            ),
          ),
          childCount: _filtered.length,
        ),
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.buttonShadow,
      ),
      child: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: AppTheme.white),
        label: const Text(
          'New Post',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
