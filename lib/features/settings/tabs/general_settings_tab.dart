import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/settings_repository.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class GeneralSettingsTab extends StatefulWidget {
  const GeneralSettingsTab({super.key});

  @override
  State<GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  final SettingsRepository _settingsRepo = SettingsRepository();
  late TextEditingController _nameController;
  File? _profileImageFile;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
    _nameController = TextEditingController(text: provider.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 400);
    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Name cannot be empty.', isError: true);
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      final provider = context.read<SettingsProvider>();
      final prefs = await provider.getPrefs();
      await prefs.setString('user_name', _nameController.text.trim());

      if (_profileImageFile != null) {
        final bytes = await _profileImageFile!.readAsBytes();
        await _settingsRepo.saveProfileImage(base64Encode(bytes));
      }

      await provider.loadUserNameAndProfile();
      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      _showSnackBar('Failed to save profile: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  void _showSalaryCycleDialog() {
    final settingsProvider = context.read<SettingsProvider>();
    final appProvider = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salary Cycle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Start of Month'),
                subtitle: const Text('New month starts on the 1st.'),
                value: 'start_of_month',
                groupValue: settingsProvider.salaryCycle,
                onChanged: (value) async {
                  if (value != null) {
                    await settingsProvider.setSalaryCycle(value);
                    appProvider.onSettingsChanged();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('End of Month'),
                subtitle:
                    const Text('Allows planning for next month after the 25th.'),
                value: 'end_of_month',
                groupValue: settingsProvider.salaryCycle,
                onChanged: (value) async {
                  if (value != null) {
                    await settingsProvider.setSalaryCycle(value);
                    appProvider.onSettingsChanged();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      children: [
        _buildProfileCard(provider),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'App Preferences',
          children: [
            ListTile(
              title: const Text('Manage Friends'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.manageFriendsPage),
            ),
            ListTile(
              title: const Text('Manage Categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRouter.adminPage),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Planning',
          children: [
            ListTile(
              title: const Text('Salary Cycle'),
              subtitle: Text(
                provider.salaryCycle == 'start_of_month'
                    ? 'Start of the month'
                    : 'End of the month',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showSalaryCycleDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard(SettingsProvider provider) {
    final theme = Theme.of(context);

    final imageProvider = _profileImageFile != null
        ? FileImage(_profileImageFile!)
        : (provider.profileImageBase64 != null
            ? MemoryImage(base64Decode(provider.profileImageBase64!))
            : null) as ImageProvider?;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? (_nameController.text.isNotEmpty
                        ? Text(
                            _nameController.text[0].toUpperCase(),
                            style: theme.textTheme.headlineLarge
                                ?.copyWith(color: theme.colorScheme.primary),
                          )
                        : Icon(Icons.add_a_photo_outlined,
                            size: 40, color: theme.colorScheme.secondary))
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Your Name'),
            ),
            const SizedBox(height: 8),
            _isSavingProfile
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        )))
                : ActionChip(
                    avatar: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save Changes'),
                    onPressed: _saveProfileChanges,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
