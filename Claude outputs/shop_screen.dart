import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../game/game_feedback.dart';
import '../game/skins.dart';
import '../models/user_profile.dart';
import '../services/online_match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/free_coins_button.dart';

enum _ShopTab { pieces, boards }

const Color _gold1 = Color(0xFFFFE680);
const Color _gold2 = Color(0xFFFFB800);
const Color _gold3 = Color(0xFFC77700);
const Color _goldInk = Color(0xFF4A2E00);

/// Tienda de personalización: se compran skins de fichas y de tablero
/// con las monedas que se ganan jugando (modo IA y online). Las compras
/// y el skin equipado se guardan en el perfil (`users/{uid}`), así que
/// se mantienen en cualquier dispositivo donde se inicie sesión.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _service = OnlineMatchService();
  String? _uid;
  _ShopTab _tab = _ShopTab.pieces;
  String? _busySkinId;

  @override
  void initState() {
    super.initState();
    _service.ensureSignedIn().then((uid) {
      if (mounted) setState(() => _uid = uid);
    });
  }

  Future<void> _handlePiece(UserProfile profile, PieceSkin skin) async {
    final owned = profile.unlockedPieceSkins.contains(skin.id);
    if (owned) {
      if (profile.equippedPieceSkin == skin.id) return;
      GameFeedback.instance.tap();
      await _service.equipSkin(_uid!, type: 'piece', skinId: skin.id);
      return;
    }
    await _purchase(profile, type: 'piece', skinId: skin.id, price: skin.price);
  }

  Future<void> _handleBoard(UserProfile profile, BoardSkin skin) async {
    final owned = profile.unlockedBoardSkins.contains(skin.id);
    if (owned) {
      if (profile.equippedBoardSkin == skin.id) return;
      GameFeedback.instance.tap();
      await _service.equipSkin(_uid!, type: 'board', skinId: skin.id);
      return;
    }
    await _purchase(profile, type: 'board', skinId: skin.id, price: skin.price);
  }

  Future<void> _purchase(UserProfile profile, {required String type, required String skinId, required int price}) async {
    if (profile.coins < price) {
      _showMessage('Te faltan ${price - profile.coins} monedas para este skin.');
      return;
    }
    setState(() => _busySkinId = skinId);
    try {
      await _service.purchaseSkin(_uid!, type: type, skinId: skinId, price: price);
      GameFeedback.instance.win();
      if (mounted) {
        // Equipamos automáticamente lo que se acaba de comprar.
        await _service.equipSkin(_uid!, type: type, skinId: skinId);
      }
    } catch (e) {
      _showMessage(e is StateError ? e.message : 'No se pudo completar la compra.');
    } finally {
      if (mounted) setState(() => _busySkinId = null);
    }
  }

  void _showMessage(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vale'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1360),
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GlassIconButton(
                      icon: CupertinoIcons.chevron_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Tienda',
                        style: AppTheme.display(size: 26, weight: FontWeight.w800).copyWith(color: Colors.white),
                      ),
                    ),
                    if (_uid != null)
                      StreamBuilder<UserProfile?>(
                        stream: _service.watchProfile(_uid!),
                        builder: (context, snapshot) => _CoinPill(coins: snapshot.data?.coins ?? 0),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_uid != null) ...[
                  FreeCoinsRewardButton(uid: _uid!, service: _service),
                  const SizedBox(height: 14),
                ],
                _TabSelector(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
                const SizedBox(height: 14),
                if (_uid == null)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)))
                else
                  Expanded(
                    child: StreamBuilder<UserProfile?>(
                      stream: _service.watchProfile(_uid!),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        if (profile == null) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 6, bottom: 28),
                          child: _tab == _ShopTab.pieces ? _buildPieceGrid(profile) : _buildBoardGrid(profile),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieceGrid(UserProfile profile) {
    return _CardGrid(
      children: [
        for (final skin in Skins.pieceSkins)
          _SkinCard(
            name: skin.name,
            price: skin.price,
            missing: skin.price - profile.coins,
            premium: skin.price >= 500,
            owned: profile.unlockedPieceSkins.contains(skin.id),
            equipped: profile.equippedPieceSkin == skin.id,
            busy: _busySkinId == skin.id,
            glow: skin.redColors[1],
            preview: _PiecePreview(skin: skin),
            onTap: () => _handlePiece(profile, skin),
          ),
      ],
    );
  }

  Widget _buildBoardGrid(UserProfile profile) {
    return _CardGrid(
      children: [
        for (final skin in Skins.boardSkins)
          _SkinCard(
            name: skin.name,
            price: skin.price,
            missing: skin.price - profile.coins,
            premium: skin.price >= 480,
            owned: profile.unlockedBoardSkins.contains(skin.id),
            equipped: profile.equippedBoardSkin == skin.id,
            busy: _busySkinId == skin.id,
            glow: skin.top,
            preview: _BoardPreview(skin: skin),
            onTap: () => _handleBoard(profile, skin),
          ),
      ],
    );
  }
}

class _CardGrid extends StatelessWidget {
  final List<Widget> children;
  const _CardGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 40 - 14) / 2;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [for (final c in children) SizedBox(width: width, child: c)],
    );
  }
}

/// Moneda dorada brillante, usada en el saldo y en todos los precios.
class _Coin extends StatelessWidget {
  final double size;
  const _Coin({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [Color(0xFFFFF6C2), _gold2, _gold3],
          stops: [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: const Color(0xFFFFE27A), width: size * 0.06),
        boxShadow: [BoxShadow(color: _gold2.withValues(alpha: 0.55), blurRadius: size * 0.45)],
      ),
      child: Center(
        child: Container(
          width: size * 0.62,
          height: size * 0.62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold3.withValues(alpha: 0.55), width: size * 0.05),
          ),
          child: Center(
            child: Text(
              r'$',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF8A5200),
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final BorderRadius radius;
  final double blur;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;

  const _Glass({
    required this.child,
    required this.radius,
    this.blur = 14,
    this.tint,
    this.border,
    this.shadows,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: tint ?? Colors.white.withValues(alpha: 0.10),
              border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TabSelector extends StatelessWidget {
  final _ShopTab tab;
  final ValueChanged<_ShopTab> onChanged;
  const _TabSelector({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabButton('Fichas', Icons.circle, _ShopTab.pieces),
          _tabButton('Tableros', Icons.grid_view_rounded, _ShopTab.boards),
        ],
      ),
    );
  }

  Widget _tabButton(String label, IconData icon, _ShopTab value) {
    final selected = tab == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!selected) {
            GameFeedback.instance.tap();
            onChanged(value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4FA3FF), Color(0xFF8A4BFF)],
                  )
                : null,
            boxShadow: selected
                ? [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.55), blurRadius: 14, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: selected ? 1 : 0.55)),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: selected ? 1 : 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final String name;
  final int price;
  final int missing;
  final bool premium;
  final bool owned;
  final bool equipped;
  final bool busy;
  final Color glow;
  final Widget preview;
  final VoidCallback onTap;

  const _SkinCard({
    required this.name,
    required this.price,
    required this.missing,
    required this.premium,
    required this.owned,
    required this.equipped,
    required this.busy,
    required this.glow,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = missing <= 0;
    final Color borderColor = equipped
        ? const Color(0xFF3DF2A5)
        : premium && !owned
            ? _gold2.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.20);
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: _Glass(
        radius: BorderRadius.circular(22),
        tint: Colors.white.withValues(alpha: equipped ? 0.16 : 0.10),
        border: Border.all(color: borderColor, width: equipped || (premium && !owned) ? 1.6 : 1),
        shadows: [
          if (equipped) BoxShadow(color: const Color(0xFF3DF2A5).withValues(alpha: 0.35), blurRadius: 18),
          if (premium && !owned && !equipped) BoxShadow(color: _gold2.withValues(alpha: 0.28), blurRadius: 18),
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Escenario iluminado detrás de la vista previa.
                  Container(
                    height: 88,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 0.95,
                        colors: [glow.withValues(alpha: 0.45), const Color(0xFF0B1360).withValues(alpha: 0.55)],
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Center(child: preview),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(size: 14, weight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    price: price,
                    owned: owned,
                    equipped: equipped,
                    canAfford: canAfford,
                    busy: busy,
                  ),
                  SizedBox(
                    height: 16,
                    child: (!owned && !canAfford && price > 0)
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              'Te faltan $missing',
                              style: AppTheme.body(size: 10.5, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6)),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            if (premium && !owned)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gold1, _gold2]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('PREMIUM', style: AppTheme.body(size: 9, weight: FontWeight.w900, color: _goldInk).copyWith(letterSpacing: 0.6)),
                ),
              ),
            if (owned)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: equipped ? const Color(0xFF3DF2A5) : Colors.white.withValues(alpha: 0.22),
                  ),
                  child: Icon(Icons.check_rounded, size: 15, color: equipped ? const Color(0xFF063B27) : Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final int price;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final bool busy;

  const _ActionButton({
    required this.price,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    Gradient? gradient;
    Color? flat;
    Widget content;
    List<BoxShadow> shadows = const [];

    if (busy) {
      flat = Colors.white.withValues(alpha: 0.14);
      content = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else if (equipped) {
      flat = const Color(0xFF3DF2A5).withValues(alpha: 0.18);
      content = Text('EQUIPADO', style: AppTheme.body(size: 12, weight: FontWeight.w900, color: const Color(0xFF3DF2A5)).copyWith(letterSpacing: 0.6));
    } else if (owned) {
      gradient = const LinearGradient(colors: [Color(0xFF4FA3FF), Color(0xFF8A4BFF)]);
      shadows = [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4))];
      content = Text('EQUIPAR', style: AppTheme.body(size: 12, weight: FontWeight.w900, color: Colors.white).copyWith(letterSpacing: 0.6));
    } else if (price == 0) {
      gradient = const LinearGradient(colors: [Color(0xFF4FA3FF), Color(0xFF8A4BFF)]);
      content = Text('GRATIS', style: AppTheme.body(size: 12, weight: FontWeight.w900, color: Colors.white).copyWith(letterSpacing: 0.6));
    } else if (canAfford) {
      gradient = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_gold1, _gold2]);
      shadows = [BoxShadow(color: _gold2.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 4))];
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Coin(size: 18),
          const SizedBox(width: 6),
          Text('$price', style: AppTheme.body(size: 14, weight: FontWeight.w900, color: _goldInk)),
        ],
      );
    } else {
      flat = Colors.black.withValues(alpha: 0.28);
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: 0.55, child: const _Coin(size: 18)),
          const SizedBox(width: 6),
          Text('$price', style: AppTheme.body(size: 14, weight: FontWeight.w900, color: _gold1.withValues(alpha: 0.75))),
        ],
      );
    }

    return Container(
      height: 38,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient,
        color: flat,
        borderRadius: BorderRadius.circular(13),
        border: gradient == null ? Border.all(color: Colors.white.withValues(alpha: 0.14)) : null,
        boxShadow: shadows,
      ),
      child: content,
    );
  }
}

class _PiecePreview extends StatelessWidget {
  final PieceSkin skin;
  const _PiecePreview({required this.skin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(colors: skin.redColors, emoji: skin.redEmoji, image: skin.redImage),
        const SizedBox(width: 6),
        _Dot(colors: skin.yellowColors, emoji: skin.yellowEmoji, image: skin.yellowImage),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final List<Color> colors;
  final String? emoji;
  final String? image;
  const _Dot({required this.colors, this.emoji, this.image});

  static const double _size = 50;

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: AssetImage(image!), fit: BoxFit.cover),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 4))],
        ),
      );
    }
    // Ficha de color con relieve y reflejo, para que se parezca a las
    // bolas 3D mientras no haya una imagen propia.
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: colors,
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(color: colors[1].withValues(alpha: 0.6), blurRadius: 12),
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 6,
            left: 9,
            child: Container(
              width: 20,
              height: 11,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ),
          if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 26)),
        ],
      ),
    );
  }
}

/// Vista previa real del tablero: marco con su degradado, huecos vacíos
/// y unas fichas dentro, igual que se verá en partida.
class _BoardPreview extends StatelessWidget {
  final BoardSkin skin;
  const _BoardPreview({required this.skin});

  static const _layout = [
    [0, 0, 0, 0, 0],
    [0, 0, 2, 0, 0],
    [0, 1, 2, 0, 0],
    [1, 2, 1, 2, 0],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 78,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skin.top, skin.bottom],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: skin.shadow, offset: const Offset(0, 4)),
          BoxShadow(color: skin.top.withValues(alpha: 0.5), blurRadius: 14),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            if (skin.decorIcon != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.22,
                  child: FittedBox(child: Icon(skin.decorIcon, color: skin.decorColor ?? Colors.white)),
                ),
              ),
            Column(
              children: [
                for (final row in _layout)
                  Expanded(
                    child: Row(
                      children: [
                        for (final cell in row)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(1.6),
                              child: _cell(cell),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int v) {
    if (v == 0) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: skin.holeEmpty,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 1.5, offset: const Offset(0, 1))],
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(v == 1 ? 'assets/design/piece_red.png' : 'assets/design/piece_yellow.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  final int coins;
  const _CoinPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: [_gold2.withValues(alpha: 0.30), _gold2.withValues(alpha: 0.12)]),
        border: Border.all(color: _gold1.withValues(alpha: 0.75), width: 1.2),
        boxShadow: [BoxShadow(color: _gold2.withValues(alpha: 0.35), blurRadius: 14)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Coin(size: 26),
          const SizedBox(width: 8),
          Text('$coins', style: AppTheme.body(size: 17, weight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _Glass(
        radius: BorderRadius.circular(999),
        child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20, color: Colors.white)),
      ),
    );
  }
}
