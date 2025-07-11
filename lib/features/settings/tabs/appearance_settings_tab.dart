import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/shared/theme/theme_manager.dart';
import 'package:provider/provider.dart';

class AppearanceSettingsTab extends StatefulWidget {
  const AppearanceSettingsTab({super.key});

  @override
  State<AppearanceSettingsTab> createState() => _AppearanceSettingsTabState();
}

class _AppearanceSettingsTabState extends State<AppearanceSettingsTab> {
  void _showColorPicker({
    required String title,
    required Color currentColor,
    required Function(Color) onColorSaved,
  }) {
    Color pickerColor = currentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              onColorSaved(pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Widget colorTile(String title, Color? currentColor, Color defaultColor,
        Function(Color) onSave) {
      return ListTile(
        title: Text(title),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: currentColor ?? defaultColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor),
          ),
        ),
        onTap: () => _showColorPicker(
          title: title,
          currentColor: currentColor ?? defaultColor,
          onColorSaved: onSave,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      children: [
        _buildSectionCard(
          title: 'Theme',
          children: [
            Consumer<ThemeNotifier>(
              builder: (context, themeNotifier, child) => SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeNotifier.isDarkMode,
                onChanged: (value) {
                  themeNotifier.toggleTheme();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Theme Color',
          children: [
            colorTile(
                'Primary Color',
                isDarkMode ? provider.seedColorDark : provider.seedColorLight,
                isDarkMode ? const Color(0xFF4A90E2) : const Color(0xFF007AFF),
                (c) => provider.setThemeSeedColor(c, isDarkMode)),
          ],
        ),
      ],
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
