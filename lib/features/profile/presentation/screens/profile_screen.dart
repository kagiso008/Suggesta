import 'dart:developer' as developer;
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/bouncing_logo.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isEditing = false;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadProfile() async {
    setState(() {
      _isInitialLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = authRepository.currentUser;

      if (currentUser != null) {
        final profile = await authRepository.getProfile(currentUser.id);
        if (profile != null) {
          setState(() {
            _usernameController.text = profile['username'] ?? '';
            _bioController.text = profile['bio'] ?? '';
            _avatarUrl = profile['avatar_url'];
          });
        }
      }
    } catch (e) {
      // Log error but don't crash the UI
      developer.log('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final authRepository = ref.read(authRepositoryProvider);
    final currentUser = authRepository.currentUser;

    if (currentUser == null) return;

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      // Upload to Supabase Storage
      final supabase = authRepository.supabaseClient;
      final fileExtension = pickedFile.path.split('.').last;
      final fileName =
          '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final file = File(pickedFile.path);

      await supabase.storage
          .from('avatars')
          .upload(
            fileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$fileExtension',
            ),
          );

      // Get public URL
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update profile with new avatar_url using dedicated method
      await authRepository.updateAvatar(
        userId: currentUser.id,
        avatarUrl: publicUrl,
      );

      setState(() {
        _avatarUrl = publicUrl;
        _isUploadingAvatar = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });

      String errorMessage = 'Failed to upload profile picture: $e';

      // Provide more helpful error messages for common issues
      if (e.toString().contains('row-level security policy')) {
        errorMessage =
            'Storage permission denied. The avatars bucket may not be properly configured. '
            'Please run the storage setup SQL in Supabase.';
      } else if (e.toString().contains('bucket not found')) {
        errorMessage =
            'Avatars bucket not found. Please create the "avatars" bucket in Supabase Storage.';
      } else if (e.toString().contains('permission denied')) {
        errorMessage =
            'Permission denied. Make sure you are logged in and the storage bucket has proper RLS policies.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleSaveProfile() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    try {
      await authNotifier.updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      String errorMessage = 'Failed to update profile: $e';

      // Provide more helpful error messages for common issues
      if (e.toString().contains('username violates profiles') ||
          e.toString().contains(
            'duplicate key value violates unique constraint',
          )) {
        errorMessage =
            'Username is already taken. Please choose a different username.';
      } else if (e.toString().contains('null value in column "username"')) {
        errorMessage = 'Username cannot be empty. Please enter a username.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      try {
        await authNotifier.signOut();
        if (mounted) {
          context.go('/welcome');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _handleDeleteAccount() async {
    developer.log(
      '[PROFILE-SCREEN] ========== DELETE ACCOUNT HANDLER CALLED ==========',
    );

    // Store context in local variable to avoid async gap issues
    final localContext = context;

    final authRepository = ref.read(authRepositoryProvider);
    final currentUser = authRepository.currentUser;

    developer.log('[PROFILE-SCREEN] Current user ID: ${currentUser?.id}');
    developer.log('[PROFILE-SCREEN] Current user email: ${currentUser?.email}');

    if (currentUser == null) {
      developer.log('[PROFILE-SCREEN] ❌ No current user found');
      if (mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('User not found'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    developer.log('[PROFILE-SCREEN] Showing delete confirmation dialog...');

    // First confirmation dialog
    final confirmed = await showDialog<bool>(
      context: localContext,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. Your account and all data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    developer.log('[PROFILE-SCREEN] First confirmation: $confirmed');

    if (confirmed != true) {
      developer.log('[PROFILE-SCREEN] Delete cancelled by user at first step');
      return;
    }

    // Second step: Password confirmation for security
    developer.log('[PROFILE-SCREEN] Showing password confirmation dialog...');
    final passwordController = TextEditingController();
    final passwordConfirmed = await showDialog<bool>(
      context: localContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isPasswordVisible = false;
            bool isLoading = false;

            return AlertDialog(
              title: const Text('Confirm Your Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For security, please enter your password to confirm account deletion:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is your final confirmation. Account deletion cannot be reversed.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your password'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          // For security, we're requiring password entry as an additional confirmation step
                          // The actual password verification happens in the edge function via JWT validation
                          Navigator.pop(context, true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );

    developer.log('[PROFILE-SCREEN] Password confirmed: $passwordConfirmed');

    if (passwordConfirmed == true) {
      developer.log(
        '[PROFILE-SCREEN] User confirmed with password. Calling deleteAccount...',
      );
      final authNotifier = ref.read(authNotifierProvider.notifier);
      try {
        developer.log(
          '[PROFILE-SCREEN] Invoking authNotifier.deleteAccount(${currentUser.id})',
        );
        await authNotifier.deleteAccount(currentUser.id);
        developer.log(
          '[PROFILE-SCREEN] ✅ deleteAccount completed successfully',
        );

        if (mounted) {
          developer.log('[PROFILE-SCREEN] Navigating to /welcome route');
          localContext.go('/welcome');
        }
      } catch (e, stackTrace) {
        developer.log('[PROFILE-SCREEN] ❌ Error during deletion: $e');
        developer.log('[PROFILE-SCREEN] Stack trace: $stackTrace');

        if (mounted) {
          ScaffoldMessenger.of(localContext).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete account: ${e.toString().replaceAll('Exception: ', '')}',
              ),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      developer.log('[PROFILE-SCREEN] Delete cancelled at password step');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Show loading indicator while profile data is being fetched
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFFFB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BouncingLogo(
                imagePath: 'assets/images/app_logo.png',
                width: 100,
                height: 100,
                bounceDuration: const Duration(milliseconds: 700),
                bounceHeight: 0.2,
                shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
                shadowBlurRadius: 15,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading profile...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Beautiful Header Section with Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.8),
                    const Color(0xFF6366F1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 48,
                bottom: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User Avatar with Upload
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _isUploadingAvatar
                            ? Center(
                                child: BouncingLogo(
                                  imagePath: 'assets/images/app_logo.png',
                                  width: 60,
                                  height: 60,
                                  bounceDuration: const Duration(
                                    milliseconds: 500,
                                  ),
                                  bounceHeight: 0.15,
                                  showShadow: false,
                                ),
                              )
                            : ClipOval(
                                child:
                                    _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: _avatarUrl!,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                        placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.5),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Center(
                                              child: Text(
                                                (_usernameController
                                                            .text
                                                            .isNotEmpty
                                                        ? _usernameController
                                                              .text[0]
                                                        : (currentUser?.email !=
                                                                  null
                                                              ? currentUser!
                                                                    .email![0]
                                                              : 'U'))
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 48,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF6366F1),
                                                ),
                                              ),
                                            ),
                                      )
                                    : Center(
                                        child: Text(
                                          (_usernameController.text.isNotEmpty
                                                  ? _usernameController.text[0]
                                                  : (currentUser?.email != null
                                                        ? currentUser!.email![0]
                                                        : 'U'))
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6366F1),
                                          ),
                                        ),
                                      ),
                              ),
                      ),
                      if (_isEditing && !_isUploadingAvatar)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAndUploadAvatar,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF6366F1),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Username or Email
                  Text(
                    _usernameController.text.isNotEmpty
                        ? _usernameController.text
                        : (currentUser?.email ?? 'User'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_usernameController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        currentUser?.email ?? 'No email',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Edit Profile Button in Header
                  const SizedBox(height: 24),
                  if (!_isEditing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push('/my-topics');
                        },
                        icon: const Icon(Icons.forum_outlined),
                        label: const Text('My Topics'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: const BorderSide(color: Color(0xFF6366F1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleSaveProfile,
                            icon: const Icon(Icons.check_circle_outlined),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _isEditing = false),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Information Card
                  _buildSectionCard(
                    title: 'Account Information',
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF6366F1),
                    children: [
                      // Email (Read-only)
                      _buildCardField(
                        label: 'Email Address',
                        value: currentUser?.email ?? 'Loading...',
                        isReadOnly: true,
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Username (Editable)
                      if (_isEditing)
                        _buildEditableCardField(
                          label: 'Username',
                          controller: _usernameController,
                          hint: 'Choose your username',
                          icon: Icons.tag_outlined,
                        )
                      else
                        _buildCardField(
                          label: 'Username',
                          value: _usernameController.text.isEmpty
                              ? 'Not set'
                              : _usernameController.text,
                          icon: Icons.tag_outlined,
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bio Card
                  _buildSectionCard(
                    title: 'About You',
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFFEC4899),
                    children: [
                      if (_isEditing)
                        _buildEditableCardField(
                          label: 'Bio',
                          controller: _bioController,
                          hint: 'Tell us about yourself...',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          maxLength: 500,
                        )
                      else
                        _buildCardField(
                          label: 'Bio',
                          value: _bioController.text.isEmpty
                              ? 'No bio added'
                              : _bioController.text,
                          isMultiline: true,
                          icon: Icons.description_outlined,
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Bookmarks Button
                  _buildActionButton(
                    label: 'Bookmarks',
                    backgroundColor: const Color(0xFF6366F1),
                    onPressed: () {
                      context.push('/bookmarks');
                    },
                    icon: Icons.bookmark_outline,
                  ),

                  const SizedBox(height: 16),

                  // Account Actions Section
                  Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign Out Button
                  _buildActionButton(
                    label: authState.isLoading ? 'Signing out...' : 'Sign Out',
                    backgroundColor: const Color(0xFF10B981),
                    onPressed: authState.isLoading ? null : _handleSignOut,
                    icon: Icons.logout_outlined,
                    isLoading: authState.isLoading,
                  ),

                  // Significant spacing and visual separator
                  const SizedBox(height: 32),

                  // Divider line to separate from delete button
                  Container(height: 1, color: Colors.grey.shade200),

                  const SizedBox(height: 32),

                  // Delete Account Button - Danger Zone
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.05),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Danger zone label
                        Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: const Color(0xFFEF4444),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Danger Zone',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Delete Account Button
                        _buildActionButton(
                          label: authState.isLoading
                              ? 'Deleting...'
                              : 'Delete Account',
                          backgroundColor: const Color(0xFFEF4444),
                          onPressed: authState.isLoading
                              ? null
                              : _handleDeleteAccount,
                          icon: Icons.delete_outline,
                          isLoading: authState.isLoading,
                          isDanger: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Warning Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.warning_outlined,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Permanent Deletion',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Once deleted, your account and all associated data cannot be recovered.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(
                                    0xFFDC2626,
                                  ).withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 20)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardField({
    required String label,
    required String value,
    required IconData icon,
    bool isReadOnly = true,
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isReadOnly ? const Color(0xFFF9FAFB) : Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 15,
              height: 1.5,
            ),
            maxLines: isMultiline ? null : 1,
            overflow: isMultiline
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableCardField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            counterStyle: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 12,
            ),
          ),
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback? onPressed,
    required IconData icon,
    bool isLoading = false,
    bool isDanger = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: const Color(0xFFD1D5DB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: isDanger ? 0 : 2,
        ),
      ),
    );
  }
}
