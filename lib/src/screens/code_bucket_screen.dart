import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models.dart';

class CodeBucketScreen extends ConsumerStatefulWidget {
  const CodeBucketScreen({super.key});

  @override
  ConsumerState<CodeBucketScreen> createState() => _CodeBucketScreenState();
}

class _CodeBucketScreenState extends ConsumerState<CodeBucketScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterLanguage = 'All';
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  static const List<String> _languages = [
    'All',
    'Dart',
    'Python',
    'JavaScript',
    'TypeScript',
    'SQL',
    'Go',
    'Rust',
    'Java',
    'C++',
    'Shell',
    'YAML',
    'Other',
  ];

  static const Map<String, Color> _languageColors = {
    'Dart': Color(0xFF0175C2),
    'Python': Color(0xFF3572A5),
    'JavaScript': Color(0xFFF7DF1E),
    'TypeScript': Color(0xFF3178C6),
    'SQL': Color(0xFFE38C00),
    'Go': Color(0xFF00ADD8),
    'Rust': Color(0xFFDEA584),
    'Java': Color(0xFFB07219),
    'C++': Color(0xFFF34B7D),
    'Shell': Color(0xFF89E051),
    'YAML': Color(0xFFCB171E),
    'Other': Color(0xFF9E9E9E),
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getLanguageColor(String lang) {
    return _languageColors[lang] ?? const Color(0xFF9E9E9E);
  }

  void _showAddSnippetDialog() {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String selectedLang = 'Dart';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 560,
                constraints: const BoxConstraints(maxHeight: 620),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E2E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey[200]!,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_circle_outline,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'New Code Snippet',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: isDark ? Colors.white54 : Colors.grey),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // Form body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: titleCtrl,
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Snippet Title',
                                labelStyle: GoogleFonts.inter(
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                                hintText: 'e.g. Flutter Hero Animation',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white24 : Colors.grey[400],
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6C63FF),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Language dropdown
                            DropdownButtonFormField<String>(
                              value: selectedLang,
                              dropdownColor: isDark
                                  ? const Color(0xFF2A2A3E)
                                  : Colors.white,
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Language',
                                labelStyle: GoogleFonts.inter(
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                              ),
                              items: _languages
                                  .where((l) => l != 'All')
                                  .map((lang) => DropdownMenuItem(
                                        value: lang,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: _getLanguageColor(lang),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(lang),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => selectedLang = v);
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Code input
                            TextField(
                              controller: codeCtrl,
                              maxLines: 10,
                              style: GoogleFonts.firaCode(
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Code',
                                labelStyle: GoogleFonts.inter(
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                                hintText: 'Paste your code here…',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white24 : Colors.grey[400],
                                ),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF0D0E15)
                                    : const Color(0xFFF8F9FC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6C63FF),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer actions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey[200]!,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white54 : Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              final title = titleCtrl.text.trim();
                              final code = codeCtrl.text.trim();
                              if (title.isEmpty || code.isEmpty) return;

                              ref.read(codeBucketProvider.notifier).addSnippet(
                                    title: title,
                                    code: code,
                                    language: selectedLang,
                                  );
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: Text(
                              'Save Snippet',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final snippets = ref.watch(codeBucketProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Apply search + language filter
    final filtered = snippets.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesLang =
          _filterLanguage == 'All' || s.language == _filterLanguage;
      return matchesSearch && matchesLang;
    }).toList();

    return FadeTransition(
      opacity: _fadeIn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[900]!.withOpacity(0.5)
                  : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.code_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code Bucket',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${snippets.length} snippets saved',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddSnippetDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'New Snippet',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // Search + Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            color: isDark
                ? const Color(0xFF1E1E2A).withOpacity(0.6)
                : const Color(0xFFF8F9FC),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search snippets…',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white30 : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.white30 : Colors.grey[400],
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Language filter chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: _languages.length > 6 ? 6 : _languages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final lang = _languages[index];
                      final isActive = _filterLanguage == lang;
                      return ChoiceChip(
                        label: Text(
                          lang,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isActive
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.grey[700]),
                          ),
                        ),
                        selected: isActive,
                        selectedColor: const Color(0xFF6C63FF),
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey[100],
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (_) {
                          setState(() => _filterLanguage = lang);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Snippet cards grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.data_object_rounded,
                          size: 56,
                          color: isDark ? Colors.white12 : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _filterLanguage != 'All'
                              ? 'No snippets match your filter'
                              : 'No snippets yet — create your first!',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 480,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _SnippetCard(
                        snippet: filtered[index],
                        languageColor: _getLanguageColor(filtered[index].language),
                        onDelete: () {
                          ref
                              .read(codeBucketProvider.notifier)
                              .removeSnippet(filtered[index].id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -------------- Snippet Card Widget ---------------

class _SnippetCard extends StatefulWidget {
  final CodeSnippet snippet;
  final Color languageColor;
  final VoidCallback onDelete;

  const _SnippetCard({
    required this.snippet,
    required this.languageColor,
    required this.onDelete,
  });

  @override
  State<_SnippetCard> createState() => _SnippetCardState();
}

class _SnippetCardState extends State<_SnippetCard> {
  bool _isHovered = false;
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.snippet.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMM d, h:mm a').format(widget.snippet.createdAt);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: isDark
              ? (_isHovered
                  ? const Color(0xFF252538)
                  : const Color(0xFF1C1C2E))
              : (_isHovered ? Colors.white : const Color(0xFFFCFCFE)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.languageColor.withOpacity(0.4)
                : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey[200]!),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.languageColor.withOpacity(0.1)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: _isHovered ? 20 : 8,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
              child: Row(
                children: [
                  // Language badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.languageColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.languageColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: widget.languageColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.snippet.language,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.languageColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Action buttons — visible on hover
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionBtn(
                          icon: _copied
                              ? Icons.check_rounded
                              : Icons.copy_rounded,
                          tooltip: _copied ? 'Copied!' : 'Copy code',
                          color: _copied
                              ? Colors.green
                              : (isDark ? Colors.white54 : Colors.grey[600]!),
                          onTap: _copyToClipboard,
                        ),
                        const SizedBox(width: 4),
                        _ActionBtn(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Delete',
                          color: Colors.redAccent.withOpacity(0.7),
                          onTap: widget.onDelete,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.snippet.title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // Code preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0D0E15)
                      : const Color(0xFFF4F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.grey[200]!,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.snippet.code,
                    style: GoogleFonts.firaCode(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF383A42),
                    ),
                  ),
                ),
              ),
            ),

            // Footer timestamp
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: isDark ? Colors.white24 : Colors.grey[400],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small icon-button used in card header
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
