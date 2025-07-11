import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/database_helper.dart';
import 'package:flynse/core/data/repositories/settings_repository.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:flynse/features/security/pin_lock_page.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSecuritySettingsTab extends StatefulWidget {
  const DataSecuritySettingsTab({super.key});

  @override
  State<DataSecuritySettingsTab> createState() =>
      _DataSecuritySettingsTabState();
}

class _DataSecuritySettingsTabState extends State<DataSecuritySettingsTab> {
  final SettingsRepository _settingsRepo = SettingsRepository();
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isDeletingData = false;

  String? _backupPath;
  bool _pinExists = false;
  bool _useBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = await _settingsRepo.getPin();
    if (mounted) {
      setState(() {
        _backupPath = prefs.getString('backup_location');
        _pinExists = pin != null;
        _useBiometric = prefs.getBool('use_biometric') ?? false;
      });
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

  Future<bool> _selectAndSetBackupLocation() async {
    if (kIsWeb) {
      _showSnackBar('Backup/Restore is not supported on Web.', isError: true);
      return false;
    }

    var status = await Permission.manageExternalStorage.request();

    if (!mounted) return false;

    if (status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
              'Flynse needs storage access to create backups. Please grant this permission in your phone settings.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
                child: const Text('Open Settings')),
          ],
        ),
      );
      return false;
    }

    if (status.isGranted) {
      final String? directoryPath =
          await FilePicker.platform.getDirectoryPath();
      if (directoryPath != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('backup_location', directoryPath);
        if (mounted) {
          setState(() {
            _backupPath = directoryPath;
          });
          _showSnackBar('Backup location set successfully.');
        }
        return true;
      } else {
        _showSnackBar('No location selected.', isError: true);
        return false;
      }
    } else {
      _showSnackBar('Storage permission denied.', isError: true);
      return false;
    }
  }

  Future<void> _backupDatabase() async {
    if (kIsWeb) {
      _showSnackBar('Backup/Restore is not supported on Web.', isError: true);
      return;
    }

    setState(() => _isBackingUp = true);

    if (_backupPath == null) {
      _showSnackBar('Please set a backup location first.', isError: true);
      final locationSet = await _selectAndSetBackupLocation();
      if (!locationSet) {
        if (mounted) setState(() => _isBackingUp = false);
        return;
      }
    }

    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (status.isGranted) {
      try {
        final dbHelper = DatabaseHelper();
        final dbPath = await dbHelper.getDbPath();
        final dbFile = File(dbPath);

        final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final backupFileName = 'flynse_backup_$formattedDate.db';
        final newPath = '$_backupPath/$backupFileName';
        await dbFile.copy(newPath);
        _showSnackBar('Backup successful! Saved to $newPath');
      } catch (e) {
        _showSnackBar('Backup failed: $e', isError: true);
      }
    } else {
      _showSnackBar('Storage permission denied. Cannot create backup.',
          isError: true);
    }
    if (mounted) setState(() => _isBackingUp = false);
  }

  Future<void> _restoreDatabase() async {
    if (kIsWeb) {
      _showSnackBar('Backup/Restore is not supported on Web.', isError: true);
      return;
    }

    final currentContext = context;
    final navigator = Navigator.of(currentContext);

    final confirmed = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content:
            const Text('This will overwrite all current data. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restore')),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isRestoring = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);
        final dbHelper = DatabaseHelper();
        final dbPath = await dbHelper.getDbPath();
        await dbHelper.closeDatabase();
        await backupFile.copy(dbPath);

        if (currentContext.mounted) {
          await currentContext.read<AppProvider>().refreshAllData();
          _showSnackBar('Restore successful!');
          navigator.pop();
        }
      } else {
        _showSnackBar('Restore cancelled: No file selected.');
      }
    } catch (e) {
      _showSnackBar('Restore failed: $e', isError: true);
    }
    if (mounted) setState(() => _isRestoring = false);
  }

  Future<void> _showDeleteMonthlyDataDialog() async {
    final appProvider = context.read<AppProvider>();
    int selectedYear = appProvider.selectedYear;
    int selectedMonth = appProvider.selectedMonth;
    final List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];

    final period = await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Monthly Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Select the month and year for which you want to clear all transaction data. This action cannot be undone.'),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    items: appProvider.availableYears
                        .map((year) => DropdownMenuItem(
                            value: year, child: Text(year.toString())))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedYear = value;
                          if (!appProvider
                              .getAvailableMonthsForYear(value)
                              .contains(selectedMonth)) {
                            selectedMonth =
                                appProvider.getAvailableMonthsForYear(value).first;
                          }
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Year'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedMonth,
                    items: appProvider
                        .getAvailableMonthsForYear(selectedYear)
                        .map((month) => DropdownMenuItem(
                            value: month, child: Text(monthNames[month - 1])))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedMonth = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Month'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext)
                        .pop({'year': selectedYear, 'month': selectedMonth});
                  },
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    if (period == null) return;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Are you absolutely sure?'),
                  content: Text(
                      'This will permanently delete all transactions for ${monthNames[period['month']! - 1]} ${period['year']!}. This includes income, expenses, and savings entries.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error),
                      child: const Text('I Understand, Delete'),
                    ),
                  ],
                )) ??
        false;

    if (confirmed) {
      if (mounted) setState(() => _isDeletingData = true);
      try {
        if (!mounted) return;
        await context
            .read<SettingsProvider>()
            .deleteMonthlyData(period['year']!, period['month']!);
        if (!mounted) return;
        await context.read<AppProvider>().refreshAllData();
        _showSnackBar(
            'Data for ${monthNames[period['month']! - 1]} ${period['year']!} has been deleted.');
      } catch (e) {
        _showSnackBar('An error occurred: $e', isError: true);
      } finally {
        if (mounted) {
          setState(() => _isDeletingData = false);
        }
      }
    }
  }

  Future<void> _showClearAllDataDialog() async {
    final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Clear All Application Data?'),
                  content: const Text(
                      'WARNING: This will permanently delete ALL data, including transactions, debts, savings, friends, and settings. The app will be reset to its initial state. This action cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error),
                      child: const Text('Delete Everything'),
                    ),
                  ],
                )) ??
        false;

    if (confirmed) {
      if (mounted) setState(() => _isDeletingData = true);
      try {
        if (!mounted) return;
        await context.read<SettingsProvider>().clearAllData(context);
      } catch (e) {
        _showSnackBar('An error occurred: $e', isError: true);
        if (mounted) {
          setState(() => _isDeletingData = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      children: [
        _buildSectionCard(
          title: 'Security',
          children: _buildSecuritySection(),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Data Management',
          children: _buildDataManagementSection(),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Danger Zone',
          children: _buildDangerZoneSection(),
        ),
      ],
    );
  }

  List<Widget> _buildDangerZoneSection() {
    final theme = Theme.of(context);
    return [
      ListTile(
        title: Text('Delete Monthly Data',
            style: TextStyle(color: theme.colorScheme.error)),
        leading:
            Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
        onTap: _isDeletingData ? null : _showDeleteMonthlyDataDialog,
      ),
      ListTile(
        title: Text('Clear All App Data',
            style: TextStyle(color: theme.colorScheme.error)),
        leading: Icon(Icons.delete_forever_outlined,
            color: theme.colorScheme.error),
        onTap: _isDeletingData ? null : _showClearAllDataDialog,
      ),
      if (_isDeletingData)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: LinearProgressIndicator()),
        )
    ];
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

  List<Widget> _buildSecuritySection() {
    return [
      ListTile(
        title: const Text('Change PIN'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.pinLockPage,
            arguments: PinLockPageArgs(
              mode: PinLockMode.enter,
              title: 'Enter Current PIN',
              onPinCorrect: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  context,
                  AppRouter.pinLockPage,
                  arguments: PinLockPageArgs(
                    mode: PinLockMode.create,
                    onPinCreated: () {
                      _showSnackBar('PIN changed successfully!');
                      Navigator.of(context).pop();
                      _loadSettings();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      SwitchListTile(
        title: const Text('App Lock'),
        value: _pinExists,
        onChanged: (bool value) {
          if (value) {
            Navigator.pushNamed(
              context,
              AppRouter.pinLockPage,
              arguments: PinLockPageArgs(
                mode: PinLockMode.create,
                onPinCreated: () {
                  _showSnackBar('App lock enabled.');
                  Navigator.of(context).pop();
                  _loadSettings();
                },
              ),
            );
          } else {
            _settingsRepo.deletePin();
            _showSnackBar('App lock disabled.');
            _loadSettings();
          }
        },
      ),
      if (_pinExists)
        SwitchListTile(
          title: const Text('Unlock with Biometrics'),
          subtitle: const Text('Use fingerprint or face ID'),
          value: _useBiometric,
          onChanged: (bool value) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('use_biometric', value);
            setState(() {
              _useBiometric = value;
            });
            _showSnackBar(
                'Biometric unlock ${value ? "enabled" : "disabled"}.');
          },
        ),
    ];
  }

  void _showAutoBackupDialog() {
    final provider = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Automatic Backup Frequency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <String>['Off', 'Daily', 'Weekly', 'Monthly']
                .map((String value) {
              return RadioListTile<String>(
                title: Text(value),
                value: value,
                groupValue: provider.autoBackupFrequency,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    provider.setAutoBackupFrequency(newValue);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
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

  List<Widget> _buildDataManagementSection() {
    return [
      ListTile(
        title: const Text('Backup Location'),
        subtitle: Text(
          _backupPath ?? 'Not Set',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _selectAndSetBackupLocation,
      ),
      ListTile(
        title: const Text('Automatic Backup'),
        subtitle: Text(context.watch<SettingsProvider>().autoBackupFrequency),
        trailing: const Icon(Icons.chevron_right),
        onTap: _showAutoBackupDialog,
      ),
      ListTile(
        title: Text(_isBackingUp ? 'Backing up...' : 'Backup Now'),
        leading: _isBackingUp
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.cloud_upload_outlined),
        onTap: _isBackingUp || _isRestoring ? null : _backupDatabase,
      ),
      ListTile(
        title: Text(_isRestoring ? 'Restoring...' : 'Restore Data'),
        leading: _isRestoring
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.cloud_download_outlined),
        onTap: _isRestoring || _isBackingUp ? null : _restoreDatabase,
      ),
    ];
  }
}
