import 'package:flutter/material.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int index;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.index = 0,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 50).clamp(0, 300)),
    );
    _fadeAnim = CurvedAnimation(
        parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(
        Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Deterministic accent color per post
  Color get _accentColor {
    final colors = [
      AppTheme.indigo,
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return colors[widget.post.id % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Colored top accent bar ────────────────────────
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Post ID badge + menu ────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'POST #${widget.post.id}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _accentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // User badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.slateLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline_rounded,
                                    size: 11,
                                    color: AppTheme.slate),
                                const SizedBox(width: 3),
                                Text(
                                  'User ${widget.post.userId}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.slate,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Action menu
                          _ActionMenu(
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Title ──────────────────────────────────
                      Text(
                        _capitalize(widget.post.title),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // ── Body preview ───────────────────────────
                      Text(
                        widget.post.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.slate.withOpacity(0.85),
                          height: 1.55,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),

                      // ── Footer ────────────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.open_in_new_rounded,
                              size: 14, color: AppTheme.indigo),
                          const SizedBox(width: 5),
                          const Text(
                            'View details',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.indigo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          // Word count
                          Text(
                            '${widget.post.body.split(' ').length} words',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.slate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Action popup menu
// ─────────────────────────────────────────────────────────────────────────────
class _ActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          size: 18, color: AppTheme.slate),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      offset: const Offset(0, 8),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined,
                  size: 16, color: AppTheme.indigo),
              SizedBox(width: 10),
              Text('Edit Post',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppTheme.danger),
              SizedBox(width: 10),
              Text('Delete Post',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.danger)),
            ],
          ),
        ),
      ],
    );
  }
}
