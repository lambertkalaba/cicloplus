import 'package:flutter/material.dart';

import '../game/avatar.dart';
import '../game/game_feedback.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/ui_kit.dart';

/// Pantalla para elegir el personaje del jugador: pestaña "Rápido"
/// (los 24 retratos listos o uno al azar) y pestaña "Personalizado"
/// (tono de piel, modelo y color del marco).
class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  late AvatarConfig _draft;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _draft = AvatarStore.mine.value;
  }

  Future<void> _save() async {
    GameFeedback.instance.tap();
    await AvatarStore.save(_draft);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _set(AvatarConfig config) {
    GameFeedback.instance.tap();
    setState(() => _draft = config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiColors.navy,
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    GlassCircleButton(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Tu personaje',
                        textAlign: TextAlign.center,
                        style: AppTheme.display(size: 24, weight: FontWeight.w800).copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 16),
                AvatarCircle(config: _draft, size: 132, selected: true),
                const SizedBox(height: 18),
                GlassPanel(
                  radius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _tabButton('Rápido', Icons.bolt_rounded, 0),
                      _tabButton('Personalizado', Icons.tune_rounded, 1),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: _tab == 0 ? _quickTab() : _customTab(),
                  ),
                ),
                const SizedBox(height: 12),
                NeonButton(label: 'GUARDAR', height: 54, fontSize: 17, pulse: false, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, IconData icon, int value) {
    final selected = _tab == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          GameFeedback.instance.tap();
          setState(() => _tab = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected ? UiColors.primary : null,
            boxShadow: selected
                ? [BoxShadow(color: UiColors.violet.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white.withValues(alpha: selected ? 1 : 0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.body(size: 14, weight: FontWeight.w800, color: Colors.white.withValues(alpha: selected ? 1 : 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickTab() {
    final presets = AvatarConfig.presets;
    return Column(
      children: [
        NeonButton(
          label: 'AL AZAR',
          height: 48,
          fontSize: 14,
          pulse: false,
          colors: const [UiColors.gold1, UiColors.gold2],
          glow: UiColors.gold2,
          textColor: UiColors.goldInk,
          leading: const Icon(Icons.casino_rounded, size: 20, color: UiColors.goldInk),
          onPressed: () => _set(AvatarConfig.random()),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (final p in presets)
              GestureDetector(
                onTap: () => _set(p),
                child: AvatarCircle(config: p, size: 70, selected: p.tone == _draft.tone && p.index == _draft.index),
              ),
          ],
        ),
      ],
    );
  }

  Widget _customTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('TONO DE PIEL'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var t = 0; t < AvatarConfig.tones; t++)
              GestureDetector(
                onTap: () => _set(_draft.copyWith(tone: t)),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AvatarPalette.toneColors[t],
                        border: Border.all(color: Colors.white.withValues(alpha: _draft.tone == t ? 1 : 0.25), width: _draft.tone == t ? 3 : 1.5),
                        boxShadow: _draft.tone == t ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 12)] : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(AvatarPalette.toneNames[t], style: AppTheme.body(size: 11, weight: FontWeight.w600, color: Colors.white70)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _label('PERSONAJE'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (var i = 0; i < AvatarConfig.perTone; i++)
              GestureDetector(
                onTap: () => _set(_draft.copyWith(index: i)),
                child: AvatarCircle(
                  config: _draft.copyWith(index: i),
                  size: 90,
                  selected: _draft.index == i,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _label('FONDO'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var b = 0; b < AvatarPalette.backgrounds.length; b++)
              GestureDetector(
                onTap: () => _set(_draft.copyWith(bg: b)),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AvatarPalette.backgrounds[b],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: _draft.bg == b ? 1 : 0.25), width: _draft.bg == b ? 3 : 1.5),
                    boxShadow: _draft.bg == b ? [BoxShadow(color: AvatarPalette.backgrounds[b][0].withValues(alpha: 0.8), blurRadius: 12)] : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _label('INSIGNIA'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var g = 0; g < AvatarPalette.badges.length; g++)
              GestureDetector(
                onTap: () => _set(_draft.copyWith(badge: g)),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: _draft.badge == g ? 0.22 : 0.08),
                    border: Border.all(color: Colors.white.withValues(alpha: _draft.badge == g ? 1 : 0.25), width: _draft.badge == g ? 2.5 : 1.2),
                  ),
                  child: g == 0
                      ? const Icon(Icons.block_rounded, size: 20, color: Colors.white54)
                      : Text(AvatarPalette.badges[g], style: const TextStyle(fontSize: 22)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _label('COLOR DEL MARCO'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var f = 0; f < AvatarPalette.frames.length; f++)
              GestureDetector(
                onTap: () => _set(_draft.copyWith(frame: f)),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AvatarPalette.frames[f],
                    border: Border.all(color: Colors.white.withValues(alpha: _draft.frame == f ? 1 : 0.25), width: _draft.frame == f ? 3 : 1.5),
                    boxShadow: _draft.frame == f ? [BoxShadow(color: AvatarPalette.frames[f].withValues(alpha: 0.8), blurRadius: 12)] : null,
                  ),
                  child: _draft.frame == f ? Icon(Icons.check_rounded, size: 20, color: f == 7 ? Colors.black87 : Colors.white) : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppTheme.body(size: 12, weight: FontWeight.w800, color: Colors.white70).copyWith(letterSpacing: 1.0)),
      );
}
