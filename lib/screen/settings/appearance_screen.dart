import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';

import '../../config/theme.dart';
import '../../providers/settings_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).appearance)),
      body: SafeArea(
        child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionHeader(title: 'TEMA'),
              const SizedBox(height: 8),
              _ThemeOption(
                icon: Icons.brightness_5_outlined,
                title: AppLocalizations.of(context).themeLight,
                subtitle: 'Fondo claro, texto oscuro',
                selected: settings.themeMode == ThemeMode.light,
                accentColor: settings.accentColor,
                onTap: () => settings.setThemeMode(ThemeMode.light),
              ),
              const SizedBox(height: 4),
              _ThemeOption(
                icon: Icons.nightlight_round,
                title: AppLocalizations.of(context).themeDark,
                subtitle: 'Fondo oscuro, texto claro',
                selected: settings.themeMode == ThemeMode.dark,
                accentColor: settings.accentColor,
                onTap: () => settings.setThemeMode(ThemeMode.dark),
              ),
              const SizedBox(height: 4),
              _ThemeOption(
                icon: Icons.settings_brightness_outlined,
                title: AppLocalizations.of(context).themeSystem,
                subtitle: 'Sigue la configuración del dispositivo',
                selected: settings.themeMode == ThemeMode.system,
                accentColor: settings.accentColor,
                onTap: () => settings.setThemeMode(ThemeMode.system),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'COLOR DE ACENTO'),
              const SizedBox(height: 12),
              _AccentColorPicker(
                selectedColor: settings.accentColor,
                onColorSelected: (color) => settings.setAccentColor(color),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'DISTRIBUCIÓN'),
              const SizedBox(height: 8),
              _CompactModeTile(
                value: settings.compactMode,
                onChanged: (v) => settings.setCompactMode(v),
              ),
              const SizedBox(height: 4),
              _ReduceMotionTile(
                value: settings.reduceMotion,
                onChanged: (v) => settings.setReduceMotion(v),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'VISTAS POR DEFECTO'),
              const SizedBox(height: 8),
              _DefaultViewSelector(
                icon: Icons.checklist_rounded,
                title: 'Vista de tareas',
                value: settings.defaultTaskView,
                accentColor: settings.accentColor,
                options: const ['board', 'list'],
                optionLabels: const ['Board', 'Lista'],
                onChanged: (v) => settings.setDefaultTaskView(v),
              ),
              const SizedBox(height: 4),
              _DefaultViewSelector(
                icon: Icons.sticky_note_2_rounded,
                title: 'Vista de notas',
                value: settings.defaultNoteView,
                accentColor: settings.accentColor,
                options: const ['grid', 'list'],
                optionLabels: const ['Cuadrícula', 'Lista'],
                onChanged: (v) => settings.setDefaultNoteView(v),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'VISTA PREVIA'),
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: settings.themeMode == ThemeMode.light
                      ? Colors.white
                      : BrainTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: settings.themeMode == ThemeMode.light
                        ? Colors.black.withValues(alpha: 0.08)
                        : BrainTheme.borderDark,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            settings.accentColor,
                            BrainTheme.accentBlue
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).appTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Los acentos se mantienen\nen ambos modos',
                          style: TextStyle(
                            fontSize: 13,
                            color: BrainTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _AccentColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _AccentColorPicker({
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const _colors = [
    Color(0xFF9D4EDD),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colors.map((color) {
        final isSelected = selectedColor == color;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 1)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _CompactModeTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactModeTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.density_medium_rounded,
                size: 24,
                color: BrainTheme.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo compacto',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BrainTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Reduce el espaciado para mostrar más contenido',
                      style: TextStyle(
                        fontSize: 12,
                        color: BrainTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReduceMotionTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReduceMotionTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.animation_rounded,
                size: 24,
                color: BrainTheme.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reducir animaciones',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BrainTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Minimiza las transiciones y efectos visuales',
                      style: TextStyle(
                        fontSize: 12,
                        color: BrainTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultViewSelector extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accentColor;
  final List<String> options;
  final List<String> optionLabels;
  final ValueChanged<String> onChanged;

  const _DefaultViewSelector({
    required this.icon,
    required this.title,
    required this.value,
    required this.accentColor,
    required this.options,
    required this.optionLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: BrainTheme.textSecondary),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BrainTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(options.length, (i) {
                  final isSelected = value == options[i];
                  return GestureDetector(
                    onTap: () => onChanged(options[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : Colors.transparent,
                        borderRadius: i == 0
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(9),
                                bottomLeft: Radius.circular(9),
                              )
                            : const BorderRadius.only(
                                topRight: Radius.circular(9),
                                bottomRight: Radius.circular(9),
                              ),
                      ),
                      child: Text(
                        optionLabels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : BrainTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: BrainTheme.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accentColor
                  : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? accentColor.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: selected
                    ? accentColor
                    : BrainTheme.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? accentColor
                            : BrainTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: BrainTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
