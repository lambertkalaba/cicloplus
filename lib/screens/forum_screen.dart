import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart' show themeById;
import '../theme/app_theme.dart';

/// Pantalla informativa "próximamente" para el foro de la comunidad, con
/// diseño propio (header con degradado del tema + icono grande + texto
/// explicativo) — mismo patrón visual que
/// `InvitePartnerScreen`/`AppleWatchScreen`. Puramente informativa: no
/// tiene persistencia ni estado propio.
class ForumScreen extends StatelessWidget {
  final String themeId;

  const ForumScreen({super.key, this.themeId = 'pink'});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(themeId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: Color(theme.primary),
            foregroundColor: Colors.white,
            title: Text(s.settingsForum),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(theme.primaryDark), Color(theme.primary)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.forum_outlined, size: 84, color: Colors.white),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  s.comingSoonFeature,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  s.forumScreenSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.45),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(theme.primary),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(s.comingSoonGotIt, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
