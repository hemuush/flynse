import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/database_helper.dart';
import 'package:flynse/core/data/repositories/settings_repository.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/features/security/pin_lock_page.dart';
import 'package:flynse/ui/home_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _profileImageFile;

  late AnimationController _animationController;
  bool _isButtonEnabled = false;

  final SettingsRepository _settingsRepo = SettingsRepository();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _nameController.addListener(() {
      final isEnabled = _nameController.text.trim().isNotEmpty;
      if (isEnabled != _isButtonEnabled) {
        setState(() {
          _isButtonEnabled = isEnabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 400);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _getStarted() async {
    if (!_formKey.currentState!.validate()) return;

    final appProvider = context.read<AppProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final navigator = Navigator.of(context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setBool('has_opened_before', true);

    if (_profileImageFile != null) {
      final bytes = await _profileImageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);
      await _settingsRepo.saveProfileImage(base64Image);
    }

    await settingsProvider.loadUserNameAndProfile();
    await appProvider.refreshAllData();

    if (!navigator.mounted) return;

    // FIX: Navigate to the PIN creation page, and from its callback, navigate
    // to the home page, replacing the entire stack.
    navigator.push(
      MaterialPageRoute(
        builder: (context) => PinLockPage(
          mode: PinLockMode.create,
          onPinCreated: () {
            // This callback ensures that after the PIN is created, we go to the
            // home page and remove all previous routes (onboarding, pin lock).
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const MyHomePage(isFirstLaunch: true)),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  Future<void> _restoreFromBackup() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final appProvider = context.read<AppProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final navigator = Navigator.of(context);

    final bool didRestore = await _selectAndRestoreDatabase();

    if (!mounted) return;

    if (didRestore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_opened_before', true);
      await prefs.setString('user_name', _nameController.text.trim());

      if (_profileImageFile != null) {
        final bytes = await _profileImageFile!.readAsBytes();
        await _settingsRepo.saveProfileImage(base64Encode(bytes));
      }

      await settingsProvider.loadUserNameAndProfile();
      await appProvider.refreshAllData();
      final pin = await _settingsRepo.getPin();

      if (!navigator.mounted) return;

      // FIX: The logic here is now more robust. After restoring, it checks if a PIN
      // existed in the backup. If so, it prompts the user to enter it.
      if (pin != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const PinLockPage(mode: PinLockMode.enter)),
          (route) => false,
        );
      } else {
        // If no PIN was in the backup, go straight to the home page.
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage()),
          (route) => false,
        );
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Restore cancelled or failed.')),
      );
    }
  }

  Future<bool> _selectAndRestoreDatabase() async {
    if (kIsWeb) return false;

    final messenger = ScaffoldMessenger.of(context);
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (!mounted) return false;
    if (!status.isGranted) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Storage permission is required to restore a backup.')));
      return false;
    }

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);
        final dbHelper = DatabaseHelper();
        final dbPath = await dbHelper.getDbPath();
        await dbHelper.closeDatabase();
        await backupFile.copy(dbPath);
        if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('Restore successful!')));
        }
        return true;
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildAnimatedWidget(
                  interval: const Interval(0.0, 0.6, curve: Curves.easeOut),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wallet_outlined,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildAnimatedWidget(
                  interval: const Interval(0.2, 0.8, curve: Curves.easeOut),
                  child: Text(
                    'Your finances, simplified.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnimatedWidget(
                  interval: const Interval(0.4, 0.9, curve: Curves.easeOut),
                  child: Text(
                    'Welcome to Flynse. Let\'s get you set up.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 40),
                _buildAnimatedWidget(
                  interval: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  child: _buildProfileSection(theme),
                ),
                const SizedBox(height: 32),
                _buildAnimatedWidget(
                  interval: const Interval(0.6, 1.0, curve: Curves.easeOut),
                  child: ElevatedButton(
                    onPressed: _isButtonEnabled ? _getStarted : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Get Started'),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnimatedWidget(
                  interval: const Interval(0.7, 1.0, curve: Curves.easeOut),
                  child: OutlinedButton(
                    onPressed: _isButtonEnabled ? _restoreFromBackup : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Restore from Backup'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage:
                _profileImageFile != null ? FileImage(_profileImageFile!) : null,
            child: _profileImageFile == null
                ? Icon(Icons.add_a_photo_outlined,
                    size: 28, color: theme.colorScheme.secondary)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'What should we call you?',
              hintText: 'Enter your name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedWidget(
      {required Widget child, required Interval interval}) {
    return FadeTransition(
      opacity: _animationController.drive(CurveTween(curve: interval)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: _animationController, curve: interval)),
        child: child,
      ),
    );
  }
}
