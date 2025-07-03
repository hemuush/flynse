import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/database_helper.dart';
import 'package:flynse/core/data/repositories/settings_repository.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/ui/home_page.dart';
import 'package:flynse/features/security/pin_lock_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Enum to represent the user's primary goal
enum UserGoal { trackSpending, saveForGoal, manageDebts }

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _profileImageFile;
  UserGoal? _selectedGoal;

  late AnimationController _animationController;
  bool _isButtonEnabled = false;

  final SettingsRepository _settingsRepo = SettingsRepository();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
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
    _pageController.dispose();
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  void _continueToNextPage() {
    if (!_formKey.currentState!.validate()) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a goal to continue.')),
      );
      return;
    }

    final appProvider = context.read<AppProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final navigator = Navigator.of(context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_main_goal', _selectedGoal!.name);
    await prefs.setBool('has_opened_before', true); // Mark onboarding as complete

    if (_profileImageFile != null) {
      final bytes = await _profileImageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);
      await _settingsRepo.saveProfileImage(base64Image);
    }
    
    await settingsProvider.loadUserNameAndProfile();
    await appProvider.refreshAllData();

    if (!navigator.mounted) return;

    // Directly navigate to PIN creation for new users
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => PinLockPage(
          mode: PinLockMode.create,
          onPinCreated: () {
            // After PIN is set, go to the home page.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MyHomePage(isFirstLaunch: true)), // MODIFIED: Pass the parameter here
              (route) => false,
            );
          },
        ),
      ),
      (route) => false,
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
      await prefs.setString('user_name', _nameController.text);

      if (_profileImageFile != null) {
        final bytes = await _profileImageFile!.readAsBytes();
        await _settingsRepo.saveProfileImage(base64Encode(bytes));
      }

      await settingsProvider.loadUserNameAndProfile();
      await appProvider.refreshAllData();
      final pin = await _settingsRepo.getPin();

      if (!navigator.mounted) return;

      if (pin != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const PinLockPage(mode: PinLockMode.enter)),
          (route) => false,
        );
      } else {
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
          messenger
              .showSnackBar(const SnackBar(content: Text('Restore successful!')));
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
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swiping
                  children: [
                    _buildNamePage(theme),
                    _buildGoalPage(theme),
                  ],
                ),
              ),
              // Page indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: 2,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    activeDotColor: theme.colorScheme.primary,
                    dotColor: theme.dividerColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedWidget(
      {required Widget child, required Interval interval}) {
    return FadeTransition(
      opacity: _animationController.drive(CurveTween(curve: interval)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: _animationController, curve: interval)),
        child: child,
      ),
    );
  }

  // The first page of the onboarding flow
  Widget _buildNamePage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          _buildAnimatedWidget(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage:
                      _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                  child: _profileImageFile == null
                      ? Icon(Icons.add_a_photo_outlined,
                          size: 50, color: theme.colorScheme.secondary)
                      : null,
                ),
              ),
              interval: const Interval(0.0, 0.6)),
          const SizedBox(height: 24),
          _buildAnimatedWidget(
            child: Text(
              'Welcome to Flynse',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            interval: const Interval(0.2, 0.8),
          ),
          const SizedBox(height: 16),
          _buildAnimatedWidget(
            child: Text(
              'Your personal finance companion. Let\'s get you set up.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
            interval: const Interval(0.4, 0.9),
          ),
          const SizedBox(height: 48),
          _buildAnimatedWidget(
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
            interval: const Interval(0.6, 1.0),
          ),
          const SizedBox(height: 32),
          _buildAnimatedWidget(
            child: ElevatedButton(
              onPressed: _isButtonEnabled ? _continueToNextPage : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continue'),
            ),
            interval: const Interval(0.8, 1.0),
          ),
          const SizedBox(height: 16),
          _buildAnimatedWidget(
            child: OutlinedButton.icon(
              onPressed: _isButtonEnabled ? _restoreFromBackup : null,
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Backup'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            interval: const Interval(0.8, 1.0),
          )
        ],
      ),
    );
  }

  // The second page of the onboarding flow
  Widget _buildGoalPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Text(
            'What\'s your main goal?',
            textAlign: TextAlign.center,
            style:
                theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'This will help us personalize your experience.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 48),
          _buildGoalOption(
            theme: theme,
            icon: Icons.track_changes_outlined,
            title: 'Track Spending',
            subtitle: 'Get a clear view of where your money goes.',
            value: UserGoal.trackSpending,
          ),
          const SizedBox(height: 16),
          _buildGoalOption(
            theme: theme,
            icon: Icons.savings_outlined,
            title: 'Save for a Goal',
            subtitle: 'Set and reach your financial targets.',
            value: UserGoal.saveForGoal,
          ),
          const SizedBox(height: 16),
          _buildGoalOption(
            theme: theme,
            icon: Icons.receipt_long_outlined,
            title: 'Manage Debts',
            subtitle: 'Take control of your loans and payments.',
            value: UserGoal.manageDebts,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _completeOnboarding,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Finish Setup'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalOption({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required UserGoal value,
  }) {
    final bool isSelected = _selectedGoal == value;
    return Card(
      color: isSelected
          ? theme.colorScheme.primary.withAlpha(25)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedGoal = value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
