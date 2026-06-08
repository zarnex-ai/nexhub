import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _displayNameController;
  late TextEditingController _avatarUrlController;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final user = authState.user;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _selectedImageBytes = file.bytes;
            _selectedImageName = file.name;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    String? avatarUrl = _avatarUrlController.text.trim().isEmpty
        ? null
        : _avatarUrlController.text.trim();

    if (_selectedImageBytes != null && _selectedImageName != null) {
      final uploadedUrl = await ref.read(authProvider.notifier).uploadAvatar(
            bytes: _selectedImageBytes!,
            fileName: _selectedImageName!,
            userId: user.id,
          );
      if (uploadedUrl != null) {
        avatarUrl = uploadedUrl;
        _avatarUrlController.text = uploadedUrl;
      } else {
        if (mounted) {
          final error = ref.read(authProvider).errorMessage ?? 'Failed to upload profile photo';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    final success = await ref.read(authProvider.notifier).updateProfile(
          username: _usernameController.text.trim(),
          displayName: _displayNameController.text.trim().isEmpty
              ? null
              : _displayNameController.text.trim(),
          avatarUrl: avatarUrl,
        );

    if (mounted) {
      if (success) {
        setState(() {
          _selectedImageBytes = null;
          _selectedImageName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(authProvider).errorMessage ?? 'An error occurred';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button / Header row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (user?.inviteCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR INVITE ID',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurpleAccent,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user!.inviteCode!,
                                  style: GoogleFonts.firaCode(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: Colors.deepPurpleAccent),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: user.inviteCode!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invite Code copied to clipboard!')),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Avatar Preview with Drag & Drop + Selection support
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MouseRegion(
                              onEnter: (_) => setState(() => _isHovering = true),
                              onExit: (_) => setState(() => _isHovering = false),
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 114,
                                      height: 114,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                              const Color(0xFF6C63FF),
                                              const Color(0xFF4A90E2),
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: isDark ? const Color(0xFF252538) : Colors.grey[100],
                                          backgroundImage: _selectedImageBytes == null && _avatarUrlController.text.trim().isNotEmpty
                                              ? NetworkImage(_avatarUrlController.text.trim())
                                              : null,
                                          child: _selectedImageBytes != null
                                              ? ClipOval(
                                                  child: Image.memory(
                                                    _selectedImageBytes!,
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : _avatarUrlController.text.trim().isEmpty
                                                  ? Text(
                                                      (user?.readableName ?? 'U').substring(0, 1).toUpperCase(),
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                        color: const Color(0xFF6C63FF),
                                                      ),
                                                    )
                                                  : null,
                                        ),
                                      ),
                                    ),
                                    // Hover / Drag-and-drop Overlay
                                    AnimatedOpacity(
                                      duration: const Duration(milliseconds: 200),
                                      opacity: _isHovering ? 1.0 : 0.0,
                                      child: Container(
                                        width: 102,
                                        height: 102,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withOpacity(0.55),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.cloud_upload_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Upload Photo',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Small camera indicator
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: AnimatedScale(
                                        duration: const Duration(milliseconds: 200),
                                        scale: _isHovering ? 1.1 : 1.0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6C63FF),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                              width: 2.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF6C63FF).withOpacity(0.4),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Click to change photo',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _selectedImageName != null
                                  ? const Color(0xFF6C63FF)
                                  : (isDark ? Colors.white54 : Colors.grey[600]),
                              fontWeight: _selectedImageName != null ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Username field
                    TextFormField(
                      controller: _usernameController,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                        hintText: 'e.g. johndoe',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // Display Name field
                    TextFormField(
                      controller: _displayNameController,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        hintText: 'e.g. John Doe',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Avatar URL field
                    TextFormField(
                      controller: _avatarUrlController,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Avatar Image URL',
                        prefixIcon: const Icon(Icons.image_aspect_ratio_rounded, size: 20),
                        hintText: 'https://example.com/avatar.png',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    if (authState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: Text(
                          'Save Changes',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await ref.read(authProvider.notifier).signOut();
                          if (mounted) {
                            nav.pop();
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          'Sign Out',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
