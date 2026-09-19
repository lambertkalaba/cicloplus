import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/photo_service.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

/// Pantalla "Mi cuenta", abierta desde el botón "Gestionar" de la tarjeta
/// de sesión en la pestaña "Yo".
///
/// Tiene dos modos:
/// - Vista (por defecto): foto, nombre y apellido se muestran como texto
///   simple, sin campos editables. Un botón de lápiz en el AppBar entra
///   al modo edición.
/// - Edición: foto, nombre y apellido se vuelven editables (tocar la foto
///   la cambia; nombre/apellido pasan a TextField). El correo NUNCA es
///   editable, en ningún modo — es el único dato de la cuenta que no se
///   puede tocar desde aquí.
///
/// A diferencia del antiguo diálogo "Editar datos" de Configuración (ya
/// retirado), esta pantalla NO edita altura ni peso de referencia — esos
/// siguen viviendo únicamente en Registrar > Peso.
class AccountScreen extends StatefulWidget {
  final AppUser user;
  final String themeId;
  final SubscriptionService subscriptionService;

  const AccountScreen({
    super.key,
    required this.user,
    required this.themeId,
    required this.subscriptionService,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _settings = SettingsService();
  final _authService = AuthService();
  final _photoService = PhotoService();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String? _photoDataUrl;
  bool _loading = true;
  bool _saving = false;
  bool _pickingPhoto = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final name = await _settings.loadProfileName();
    final lastName = await _settings.loadProfileLastName();
    final photo = await _settings.loadProfilePhoto();
    if (!mounted) return;
    setState(() {
      _nameController.text = name ?? '';
      _lastNameController.text = lastName ?? '';
      _photoDataUrl = photo;
      _loading = false;
    });
  }

  void _enterEditMode() => setState(() => _isEditing = true);

  void _cancelEdit() {
    // Descarta cualquier cambio de texto sin guardar y vuelve al modo
    // vista con los valores que había antes de entrar a editar.
    _load();
    setState(() => _isEditing = false);
  }

  Future<void> _pickPhoto() async {
    setState(() => _pickingPhoto = true);
    try {
      final dataUrl = await _photoService.pickAndResizeFromGallery();
      if (dataUrl == null) return; // Canceló la selección, no es un error.
      await _settings.saveProfilePhoto(dataUrl);
      if (!mounted) return;
      setState(() => _photoDataUrl = dataUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).accountPhotoUpdateError)),
      );
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final name = _nameController.text.trim();
    final lastName = _lastNameController.text.trim();
    await _settings.saveProfileName(name);
    await _settings.saveProfileLastName(lastName);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).accountNameSaved)),
    );
  }

  String _signInMethodLabel(AppStrings s) {
    switch (_authService.currentSignInProvider()) {
      case SignInProvider.google:
        return s.accountSignInMethodGoogle;
      case SignInProvider.facebook:
        return s.accountSignInMethodFacebook;
      case SignInProvider.apple:
        return s.accountSignInMethodApple;
      case SignInProvider.email:
        return s.accountSignInMethodEmail;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(widget.themeId);
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(s.accountScreenTitle)),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final photoBytes = PhotoService.decodeDataUrl(_photoDataUrl);
    final subscriptionService = widget.subscriptionService;
    final hasActiveSubscription = subscriptionService.hasActiveSubscription(widget.user);
    final displayName = [_nameController.text.trim(), _lastNameController.text.trim()]
        .where((p) => p.isNotEmpty)
        .join(' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: primaryDark,
        title: Text(s.accountScreenTitle),
        // En modo edición se cambia la flecha de volver por defecto por una
        // X bien visible que hace exactamente lo mismo que "Cancelar" antes
        // (_cancelEdit: descarta cambios y vuelve al modo vista) — pedido
        // de la usuaria para poder salir sin dudas mientras cambia la foto
        // o el nombre, sin sentirse "atrapada" ahí. Fuera de edición se deja
        // la flecha normal (automaticallyImplyLeading).
        leading: _isEditing
            ? IconButton(
                onPressed: _saving ? null : _cancelEdit,
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: s.cancel,
              )
            : null,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: _enterEditMode,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: s.edit,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
        children: [
          // ---- Foto de perfil ----
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Color(theme.primaryLight),
                      backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
                      child: photoBytes == null ? Icon(Icons.person, size: 52, color: primary) : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _pickingPhoto ? null : _pickPhoto,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _pickingPhoto
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_isEditing)
                  TextButton(
                    onPressed: _pickingPhoto ? null : _pickPhoto,
                    child: Text(s.accountChangePhoto, style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                  )
                else if (displayName.isNotEmpty)
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ---- Nombre / apellido ----
          if (_isEditing) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.accountFirstNameLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(),
                  ),
                  const SizedBox(height: 16),
                  Text(s.accountLastNameLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(s.save, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ---- Detalles de la cuenta (correo siempre solo lectura) ----
          _sectionTitle(s.accountDetailsSection),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                _detailRow(label: s.accountEmailLabel, value: widget.user.email),
                const Divider(height: 22, color: AppColors.border),
                _detailRow(label: s.accountSignInMethodLabel, value: _signInMethodLabel(s)),
                const Divider(height: 22, color: AppColors.border),
                _detailRow(label: s.accountMemberSinceLabel, value: _formatDate(widget.user.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Suscripción ----
          _sectionTitle(s.accountSubscriptionSection),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.fertileLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  hasActiveSubscription ? Icons.workspace_premium : Icons.info_outline,
                  color: AppColors.ovulation,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasActiveSubscription
                        ? s.accountSubscriptionPremiumActive
                        : s.accountSubscriptionInactive,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3),
      );

  /// Tarjeta blanca con sombra suave — contenedor base para las secciones
  /// de la pantalla (diseño "tipo tarjetas" pedido por el usuario, en vez
  /// del fondo pastel plano que usaba la versión anterior).
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }

  /// Fila de detalle dentro de una tarjeta — usada tanto para el correo
  /// (siempre de solo lectura) como para método de inicio de sesión y
  /// fecha de registro.
  Widget _detailRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
