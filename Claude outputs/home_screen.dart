import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../game/ai_player.dart';
import '../game/avatar.dart';
import '../game/escalada_progress.dart';
import '../game/game_feedback.dart';
import '../game/rating.dart';
import '../models/user_profile.dart';
import '../services/ads_service.dart';
import '../services/online_match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/free_coins_button.dart';
import '../widgets/insufficient_coins_dialog.dart';
import '../widgets/ui_kit.dart';
import 'avatar_screen.dart';
import 'game_screen.dart';
import 'online_lobby_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'team_lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AiDifficulty _selectedDifficulty = AiDifficulty.medium;
  final _service = OnlineMatchService();
  String? _uid;
  UserProfile? _profile;
  StreamSubscription<UserProfile?>? _profileSub;
  bool _lowBalanceBonusChecked = false;
  int _escaladaLevel = 1;
  int _aiStake = 0;

  static const _difficultyLabels = {
    AiDifficulty.easy: 'Fácil',
    AiDifficulty.medium: 'Normal',
    AiDifficulty.hard: 'Difícil',
    AiDifficulty.expert: 'Experto',
  };

  @override
  void initState() {
    super.initState();
    AvatarStore.load();
    _service.ensureSignedIn().then((uid) {
      if (!mounted) return;
      setState(() => _uid = uid);
      _profileSub = _service.watchProfile(uid).listen((profile) {
        if (!mounted) return;
        setState(() => _profile = profile);
        if (!_lowBalanceBonusChecked && profile != null) {
          _lowBalanceBonusChecked = true;
          _checkLowBalanceBonus(uid, profile.coins);
        }
      });
    });
    EscaladaProgress.loadLevel().then((level) {
      if (mounted) setState(() => _escaladaLevel = level);
    });
  }

  void _startAiGame() {
    GameFeedback.instance.tap();
    if (_aiStake > 0 && _uid != null && (_profile?.coins ?? 0) < _aiStake) {
      showInsufficientCoinsDialog(context, uid: _uid!, service: _service);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: GameMode.ai,
          aiDifficulty: _selectedDifficulty,
          stake: _aiStake,
        ),
      ),
    );
  }

  Future<void> _checkLowBalanceBonus(String uid, int coins) async {
    final granted = await AdsService.instance.maybeGrantLowBalanceBonus(
      currentCoins: coins,
      addCoins: (amount) => _service.addCoins(uid, amount),
    );
    if (granted != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡+$granted monedas de regalo por volver!')),
      );
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  void _startEscaladaGame() {
    GameFeedback.instance.tap();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen(mode: GameMode.escalada)),
    );
  }

  void _open(Widget screen) {
    GameFeedback.instance.tap();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiColors.navy,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    children: [
                      _TopBar(
                        profile: _profile,
                        onAvatar: () => _open(const AvatarScreen()),
                        onShop: () => _open(const ShopScreen()),
                        onProfile: () => _open(const ProfileScreen()),
                      ),
                      const SizedBox(height: 18),
                      const _Logo(),
                      const SizedBox(height: 20),
                      _buildHeroCard(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: MenuTile(
                              title: 'Online',
                              subtitle: 'Reta a jugadores',
                              iconAsset: 'assets/design/ic_globe.png',
                              fallbackIcon: CupertinoIcons.globe,
                              accent: UiColors.blue,
                              onTap: () => _open(const OnlineLobbyScreen()),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: MenuTile(
                              title: '2 contra 2',
                              subtitle: 'Juega en equipo',
                              iconAsset: 'assets/design/ic_team.png',
                              fallbackIcon: CupertinoIcons.person_3_fill,
                              accent: const Color(0xFFFF5A7A),
                              onTap: () => _open(const TeamLobbyScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: MenuTile(
                              title: 'Escalada',
                              subtitle: 'Nivel $_escaladaLevel',
                              iconAsset: 'assets/design/ic_flame.png',
                              fallbackIcon: CupertinoIcons.flame_fill,
                              accent: const Color(0xFFFF9A2E),
                              onTap: _startEscaladaGame,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: MenuTile(
                              title: 'Tienda',
                              subtitle: 'Fichas y tableros',
                              iconAsset: 'assets/design/ic_chest.png',
                              fallbackIcon: Icons.storefront_rounded,
                              accent: UiColors.gold2,
                              onTap: () => _open(const ShopScreen()),
                            ),
                          ),
                        ],
                      ),
                      if (_uid != null) ...[
                        const SizedBox(height: 14),
                        FreeCoinsRewardButton(uid: _uid!, service: _service),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: HomeBannerAd(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return GlassPanel(
      radius: BorderRadius.circular(26),
      tint: Colors.white.withValues(alpha: 0.10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'JUGAR CONTRA LA IA',
                style: AppTheme.body(size: 12, weight: FontWeight.w800, color: Colors.white70).copyWith(letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DifficultySelector(
            value: _selectedDifficulty,
            labels: _difficultyLabels,
            onChanged: (level) {
              GameFeedback.instance.tap();
              setState(() => _selectedDifficulty = level);
            },
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: 'JUGAR',
            height: 60,
            fontSize: 20,
            leading: const AssetIcon(asset: 'assets/design/ic_play.png', size: 34, fallback: Icons.play_arrow_rounded),
            onPressed: _startAiGame,
          ),
        ],
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  final AiDifficulty value;
  final Map<AiDifficulty, String> labels;
  final ValueChanged<AiDifficulty> onChanged;

  const _DifficultySelector({required this.value, required this.labels, required this.onChanged});

  static const _dots = {
    AiDifficulty.easy: 1,
    AiDifficulty.medium: 2,
    AiDifficulty.hard: 3,
    AiDifficulty.expert: 4,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          for (final level in AiDifficulty.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: value == level ? UiColors.primary : null,
                    boxShadow: value == level
                        ? [BoxShadow(color: UiColors.violet.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        labels[level]!,
                        style: AppTheme.body(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: value == level ? 1 : 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 4; i++)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < _dots[level]!
                                    ? (value == level ? Colors.white : Colors.white54)
                                    : Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onAvatar;
  final VoidCallback onShop;
  final VoidCallback onProfile;

  const _TopBar({required this.profile, required this.onAvatar, required this.onShop, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatar,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: UiColors.primary,
              boxShadow: [BoxShadow(color: UiColors.violet.withValues(alpha: 0.5), blurRadius: 12)],
            ),
            child: ValueListenableBuilder<AvatarConfig>(
              valueListenable: AvatarStore.mine,
              builder: (context, config, _) => AvatarCircle(config: config, size: 44),
            ),
          ),
        ),
        const Spacer(),
        CoinPill(coins: profile?.coins ?? 0, onTap: onShop),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onProfile,
          child: GlassPanel(
            radius: BorderRadius.circular(999),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, size: 17, color: UiColors.gold1),
                const SizedBox(width: 6),
                Text(
                  '${profile?.rating ?? kDefaultRating}',
                  style: AppTheme.body(size: 14, weight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Logo del juego: mini tablero con fichas 3D y el título con degradado.
class _Logo extends StatelessWidget {
  const _Logo();

  static const _cells = [
    [1, 2, 0, 0],
    [2, 1, 0, 0],
    [1, 2, 1, 0],
    [2, 1, 2, 1],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E7BFF), Color(0xFF1740B8)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
            boxShadow: [
              BoxShadow(color: UiColors.blue.withValues(alpha: 0.6), blurRadius: 24),
              const BoxShadow(color: Color(0xFF0A1F6B), offset: Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              for (final row in _cells)
                Expanded(
                  child: Row(
                    children: [
                      for (final v in row)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(1.8),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: v == 0 ? const Color(0xFF0A1F6B) : null,
                                image: v == 0
                                    ? null
                                    : DecorationImage(
                                        image: AssetImage(
                                          v == 1 ? 'assets/design/piece_red.png' : 'assets/design/piece_yellow.png',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '4 EN RAYA',
          style: AppTheme.display(size: 34, weight: FontWeight.w900).copyWith(
            color: Colors.white,
            letterSpacing: 2.0,
            shadows: [Shadow(color: UiColors.blue.withValues(alpha: 0.9), blurRadius: 18)],
          ),
        ),
        const SizedBox(height: 2),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [UiColors.gold1, UiColors.gold2, UiColors.gold1],
          ).createShader(rect),
          child: Text(
            'M A S T E R',
            style: AppTheme.display(size: 17, weight: FontWeight.w900).copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
