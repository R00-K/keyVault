import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../infra/api/models/user_model.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../../infra/api/services/user_service.dart';
import '../../routes/route_names.dart';
import '../../widgets/kv_button.dart';
import '../../widgets/kv_page.dart';
import '../../widgets/kv_section_card.dart';
import '../../widgets/kv_textfield.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _phoneController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _errorText;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    final displayName = AuthService.currentUser?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      _displayNameController.text = displayName.trim();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _displayNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    final phoneNumber = _phoneController.text.trim();
    final displayName = _displayNameController.text.trim();
    final dateOfBirth = _dateOfBirth;

    if (phoneNumber.isEmpty || displayName.isEmpty || dateOfBirth == null) {
      setState(() {
        _errorText =
            'Enter your phone number, display name, and date of birth.';
      });
      return;
    }

    final firebaseUser = AuthService.currentUser;
    if (firebaseUser == null) {
      debugPrint('[CompleteProfileScreen] No Firebase user found.');
      setState(() {
        _errorText = 'Your session expired. Please sign in again.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _loading = true;
    });

    try {
      debugPrint(
        '[CompleteProfileScreen] Completing profile for uid=${firebaseUser.uid}',
      );
      final keyVaultId = UserService.generateKeyVaultId();
      debugPrint('[CompleteProfileScreen] Generated KeyVault ID: $keyVaultId');

      final user = UserModel.create(
        uid: firebaseUser.uid,
        keyVaultId: keyVaultId,
        displayName: displayName,
        email: firebaseUser.email ?? '',
        phoneNumber: phoneNumber,
        photoUrl: firebaseUser.photoURL,
        dateOfBirth: Timestamp.fromDate(dateOfBirth),
      );

      await UserService.createUser(user);
      debugPrint('[CompleteProfileScreen] Firestore user document created.');

      await firebaseUser.updateDisplayName(displayName);
      debugPrint('[CompleteProfileScreen] Firebase display name updated.');

      if (mounted) {
        debugPrint('[CompleteProfileScreen] Profile complete. Opening home.');
        context.go(RouteNames.home);
      }
    } catch (error) {
      debugPrint('[CompleteProfileScreen] Profile completion failed: $error');
      if (mounted) {
        setState(() {
          _errorText = 'Could not complete your profile. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate =
        _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate == null) return;

    setState(() {
      _dateOfBirth = pickedDate;
      _dobController.text = _formatDate(pickedDate);
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return KvPage(
      appBar: AppBar(title: const Text('Complete profile')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Finish your KeyVault profile', style: AppTextTheme.title),
          const SizedBox(height: 8),
          const Text(
            'Choose how trusted contacts will recognize you before key exchange.',
            style: AppTextTheme.bodyMuted,
          ),
          const SizedBox(height: 24),
          KvSectionCard(
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(48),
                  onTap: () {
                    debugPrint(
                      '[CompleteProfileScreen] Profile picture placeholder tapped.',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Profile picture upload is coming later.',
                        ),
                      ),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.primaryMuted,
                    foregroundColor: AppColors.primary,
                    child: Icon(Icons.add_a_photo_outlined, size: 38),
                  ),
                ),
                const SizedBox(height: 20),
                KvTextField(
                  controller: _phoneController,
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                KvTextField(
                  controller: _displayNameController,
                  label: 'Display name',
                  icon: Icons.badge_outlined,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                KvTextField(
                  controller: _dobController,
                  label: 'Date of birth',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: _pickDateOfBirth,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorText!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                KvButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward,
                  loading: _loading,
                  onPressed: _completeProfile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
