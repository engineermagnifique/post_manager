import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class DetailScreen extends StatefulWidget {
  final Post post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DetailScreen({
    super.key,
    required this.post,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Post get post => widget.post;

  Color get _accentColor {
    final colors = [
      AppTheme.indigo,
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return colors[post.id % colors.length];
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.show(context, message: '$label copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: _buildContent(context),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── Collapsing AppBar ─────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.navy,
                _accentColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ID + User badge row
                Row(
                  children: [
                    _Pill(
                        label: 'POST #${post.id}',
                        color: _accentColor),
                    const SizedBox(width: 8),
                    _Pill(
                      label: 'User ${post.userId}',
                      color: Colors.white.withOpacity(0.2),
                      textColor: Colors.white70,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _capitalize(post.title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined,
              color: Colors.white, size: 22),
          tooltip: 'Edit',
          onPressed: () {
            Navigator.pop(context);
            widget.onEdit();
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: Colors.white, size: 22),
          tooltip: 'Delete',
          onPressed: () {
            Navigator.pop(context);
            widget.onDelete();
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Main Content ─────────────────────────────────────────────────
  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Metadata card ────────────────────────────────────────
          _buildMetaCard(),
          const SizedBox(height: 16),

          // ── Content card ─────────────────────────────────────────
          _buildBodyCard(),
          const SizedBox(height: 16),

          // ── Action buttons ────────────────────────────────────────
          _buildActions(context),
        ],
      ),
    );
  }

  // ── Metadata Card ─────────────────────────────────────────────────
  Widget _buildMetaCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.info_outline_rounded,
                    size: 20, color: _accentColor),
              ),
              const SizedBox(width: 12),
              const Text(
                'Post Metadata',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 16),
          _MetaRow(
            icon: Icons.tag_rounded,
            label: 'Post ID',
            value: post.id.toString(),
            onCopy: () => _copyToClipboard(post.id.toString(), 'Post ID'),
          ),
          const SizedBox(height: 12),
          _MetaRow(
            icon: Icons.person_outline_rounded,
            label: 'User ID',
            value: post.userId.toString(),
            onCopy: () =>
                _copyToClipboard(post.userId.toString(), 'User ID'),
          ),
          const SizedBox(height: 12),
          _MetaRow(
            icon: Icons.format_list_numbered_rounded,
            label: 'Word Count',
            value: '${post.body.split(' ').length} words',
          ),
          const SizedBox(height: 12),
          _MetaRow(
            icon: Icons.text_fields_rounded,
            label: 'Characters',
            value: '${post.body.length} chars',
          ),
        ],
      ),
    );
  }

  // ── Body Card ────────────────────────────────────────────────────
  Widget _buildBodyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.indigoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.article_outlined,
                    size: 20, color: AppTheme.indigo),
              ),
              const SizedBox(width: 12),
              const Text(
                'Post Content',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _copyToClipboard(post.body, 'Content'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.slateLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded,
                          size: 12, color: AppTheme.slate),
                      SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 16),

          // Title section
          const Text(
            'TITLE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _capitalize(post.title),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Body section
          const Text(
            'BODY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.slateLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Text(
              post.body,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.slate,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppTheme.danger),
            label: const Text(
              'Delete',
              style: TextStyle(
                  color: AppTheme.danger, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.danger),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onEdit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.edit_rounded,
                  size: 18, color: Colors.white),
              label: const Text('Edit Post',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const _Pill(
      {required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.slate),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.slate,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.navy,
          ),
        ),
        if (onCopy != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCopy,
            child: const Icon(Icons.copy_rounded,
                size: 14, color: AppTheme.slate),
          ),
        ],
      ],
    );
  }
}
