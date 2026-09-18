import 'package:flutter/material.dart';

import '../services/settings_service.dart' show themeById;
import '../services/wish_service.dart';
import '../theme/app_theme.dart';

/// Pestaña "Deseos": una lista compartida entre la dueña del embarazo y su
/// pareja/socia vinculada — antojos de comida, cosas que necesita, o
/// cualquier otra cosa que quiera pedir (ver WishService). Un mismo
/// widget sirve para las dos vistas, según [isOwner]:
///
/// - Dueña (isOwner: true): puede escribir deseos nuevos y borrarlos.
/// - Pareja/socia (isOwner: false): solo ve la lista y puede marcar cada
///   deseo como cumplido/pendiente (para avisar "ya se lo conseguí") — no
///   puede escribir texto nuevo ni borrar. Esa restricción también está
///   reforzada en firestore.rules, no es solo de la interfaz.
class PartnerWishesScreen extends StatefulWidget {
  final String ownerUid;
  final String myUid;
  final String themeId;
  final bool isOwner;

  /// true cuando esta pantalla se abre por su cuenta (tocando el icono de
  /// deseos en "Invitar a un socio") y necesita su propio Scaffold+AppBar
  /// — igual que showAppBar en PartnerChatScreen. false (por defecto)
  /// cuando se usa embebida como pestaña de PartnerHubScreen, que ya pone
  /// su propio AppBar.
  final bool showAppBar;
  final String title;

  const PartnerWishesScreen({
    super.key,
    required this.ownerUid,
    required this.myUid,
    required this.themeId,
    required this.isOwner,
    this.showAppBar = false,
    this.title = 'Tus deseos',
  });

  @override
  State<PartnerWishesScreen> createState() => _PartnerWishesScreenState();
}

class _PartnerWishesScreenState extends State<PartnerWishesScreen> {
  final _service = WishService();
  final _textController = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _addWish() async {
    final text = _textController.text;
    if (text.trim().isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      await _service.addWish(ownerUid: widget.ownerUid, text: text);
      _textController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Revisa tu conexión.')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _toggle(Wish wish) async {
    try {
      await _service.setDone(
        ownerUid: widget.ownerUid,
        wishId: wish.id,
        done: !wish.done,
        byUid: widget.myUid,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar. Revisa tu conexión.')),
        );
      }
    }
  }

  Future<void> _delete(Wish wish) async {
    try {
      await _service.deleteWish(ownerUid: widget.ownerUid, wishId: wish.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo borrar. Revisa tu conexión.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeById(widget.themeId);
    final primary = Color(theme.primary);

    final content = Column(
      children: [
        if (widget.isOwner)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ej. Fresas con crema, que me hagan un masaje...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                    onSubmitted: (_) => _addWish(),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _adding ? null : _addWish,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                    child: _adding
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Wish>>(
            stream: _service.watchWishes(widget.ownerUid),
            builder: (context, snapshot) {
              final wishes = snapshot.data ?? const [];
              if (wishes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.isOwner
                          ? 'Todavía no has anotado ningún deseo. Escribe uno arriba — tu pareja lo verá aquí.'
                          : 'Todavía no hay deseos anotados.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.4),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: wishes.length,
                itemBuilder: (context, i) => _wishRow(wishes[i], primary),
              );
            },
          ),
        ),
      ],
    );

    if (!widget.showAppBar) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Color(theme.primaryDark),
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  Widget _wishRow(Wish wish, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: wish.done,
            activeColor: primary,
            onChanged: (_) => _toggle(wish),
          ),
          Expanded(
            child: Text(
              wish.text,
              style: TextStyle(
                fontSize: 14,
                color: wish.done ? AppColors.textMuted : AppColors.textPrimary,
                decoration: wish.done ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.isOwner)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
              onPressed: () => _delete(wish),
              tooltip: 'Borrar',
            ),
        ],
      ),
    );
  }
}
