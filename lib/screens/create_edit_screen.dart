import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CreateEditScreen extends StatefulWidget {
  final Post? existingPost;

  const CreateEditScreen({super.key, this.existingPost});

  bool get isEditing => existingPost != null;

  @override
  State<CreateEditScreen> createState() => _CreateEditScreenState();
}

class _CreateEditScreenState extends State<CreateEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController();

  bool _saving = false;
  bool _hasChanges = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    if (widget.isEditing) {
      _titleCtrl.text = widget.existingPost!.title;
      _bodyCtrl.text = widget.existingPost!.body;
      _userIdCtrl.text = widget.existingPost!.userId.toString();
    } else {
      _userIdCtrl.text = '1';
    }

    _titleCtrl.addListener(_onChanged);
    _bodyCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _userIdCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() => _hasChanges = true);

  // ── Save ─────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      Post result;
      if (widget.isEditing) {
        result = await ApiService.updatePost(
          widget.existingPost!.copyWith(
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            userId: int.tryParse(_userIdCtrl.text.trim()) ?? 1,
          ),
        );
      } else {
        result = await ApiService.createPost(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          userId: int.tryParse(_userIdCtrl.text.trim()) ?? 1,
        );
      }

      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Error: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }

  // ── Discard Confirmation ──────────────────────────────────────────
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard changes?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
          style: TextStyle(color: AppTheme.slate, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing',
                style: TextStyle(color: AppTheme.indigo)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.slateLight,
        body: LoadingOverlay(
          isLoading: _saving,
          message:
              widget.isEditing ? 'Updating post...' : 'Creating post...',
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildForm(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.navyGradient),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.isEditing
                            ? AppTheme.warning
                            : AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isEditing ? 'EDITING POST' : 'NEW POST',
                      style: TextStyle(
                        color: widget.isEditing
                            ? AppTheme.warning
                            : AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isEditing
                      ? 'Edit Post #${widget.existingPost!.id}'
                      : 'Create New Post',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      leading: GestureDetector(
        onTap: () async {
          final shouldPop = _hasChanges ? await _onWillPop() : true;
          if (shouldPop && context.mounted) Navigator.pop(context);
        },
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
        if (_hasChanges)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Unsaved',
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Form ─────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tips card ────────────────────────────────────────────
            _buildTipsCard(),
            const SizedBox(height: 16),

            // ── Form fields card ─────────────────────────────────────
            _buildFieldsCard(),
            const SizedBox(height: 16),

            // ── Character count card ─────────────────────────────────
            _buildCounters(),
            const SizedBox(height: 24),

            // ── Submit ───────────────────────────────────────────────
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ── Tips Card ────────────────────────────────────────────────────
  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.indigoLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.indigo.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 18, color: AppTheme.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isEditing
                  ? 'Changes are sent to JSONPlaceholder (simulated — not persisted on the server).'
                  : 'Posts are created on JSONPlaceholder (simulated). The new ID will be 101.',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.indigo,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fields Card ──────────────────────────────────────────────────
  Widget _buildFieldsCard() {
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.indigoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    size: 20, color: AppTheme.indigo),
              ),
              const SizedBox(width: 12),
              const Text(
                'Post Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 18),

          // User ID
          _FieldLabel(label: 'User ID', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _userIdCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 1',
              prefixIcon: Icon(Icons.person_outline_rounded,
                  size: 20, color: AppTheme.slate),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'User ID is required';
              }
              if (int.tryParse(v.trim()) == null) {
                return 'Must be a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Title
          _FieldLabel(label: 'Post Title', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Enter an engaging title...',
              prefixIcon: Icon(Icons.title_rounded,
                  size: 20, color: AppTheme.slate),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Title is required';
              }
              if (v.trim().length < 4) {
                return 'Title must be at least 4 characters';
              }
              if (v.trim().length > 150) {
                return 'Title must be under 150 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Body
          _FieldLabel(label: 'Post Body', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bodyCtrl,
            maxLines: 7,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Write your post content here...',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 100),
                child: Icon(Icons.article_outlined,
                    size: 20, color: AppTheme.slate),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Body is required';
              }
              if (v.trim().length < 10) {
                return 'Body must be at least 10 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Counters ─────────────────────────────────────────────────────
  Widget _buildCounters() {
    final titleLen = _titleCtrl.text.length;
    final bodyLen = _bodyCtrl.text.length;
    final wordCount = _bodyCtrl.text.trim().isEmpty
        ? 0
        : _bodyCtrl.text.trim().split(RegExp(r'\s+')).length;

    return Row(
      children: [
        Expanded(
          child: _CounterBadge(
            label: 'Title chars',
            value: titleLen,
            max: 150,
            icon: Icons.title_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CounterBadge(
            label: 'Body chars',
            value: bodyLen,
            icon: Icons.text_fields_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CounterBadge(
            label: 'Words',
            value: wordCount,
            icon: Icons.sort_rounded,
          ),
        ),
      ],
    );
  }

  // ── Submit Button ────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(
                widget.isEditing
                    ? Icons.save_rounded
                    : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                widget.isEditing ? 'Save Changes' : 'Publish Post',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              final shouldPop =
                  _hasChanges ? await _onWillPop() : true;
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.navy,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppTheme.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _CounterBadge extends StatelessWidget {
  final String label;
  final int value;
  final int? max;
  final IconData icon;

  const _CounterBadge({
    required this.label,
    required this.value,
    required this.icon,
    this.max,
  });

  Color get _color {
    if (max == null) return AppTheme.indigo;
    final ratio = value / max!;
    if (ratio > 0.9) return AppTheme.danger;
    if (ratio > 0.7) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: _color),
          const SizedBox(height: 4),
          Text(
            max != null ? '$value/$max' : '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.slate,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
