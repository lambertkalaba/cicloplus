import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/chat_service.dart';
import '../services/settings_service.dart' show themeById;
import '../theme/app_theme.dart';

/// Chat privado 1 a 1 entre la dueña de un embarazo y una socia/pareja ya
/// vinculada — se abre desde el ícono de chat en "Invitar a un socio"
/// (tanto desde "Personas que pueden ver tu embarazo" como desde
/// "Embarazos que sigues"). Usa el color de tema elegido en Configuración
/// (mismo patrón que el resto de pantallas, ver themeById), nunca colores
/// fijos.
///
/// La protección real de "solo estas dos personas pueden ver esta
/// conversación" vive en firestore.rules/storage.rules (ver ChatService),
/// no aquí.
class PartnerChatScreen extends StatefulWidget {
  final String myUid;
  final String otherUid;
  final String otherLabel;
  final String themeId;

  /// false cuando esta pantalla se usa como pestaña "Chat" dentro de
  /// PartnerHubScreen: el Hub ya tiene su propio AppBar (con el nombre y
  /// el botón de salir/atrás), así que aquí no hace falta otro — solo se
  /// muestran los mensajes y la barra de escribir. En el uso normal
  /// (abierta desde el ícono de chat en "Invitar a un socio") se deja tal
  /// cual, por eso el valor por defecto es true.
  final bool showAppBar;

  const PartnerChatScreen({
    super.key,
    required this.myUid,
    required this.otherUid,
    required this.otherLabel,
    this.themeId = 'pink',
    this.showAppBar = true,
  });

  @override
  State<PartnerChatScreen> createState() => _PartnerChatScreenState();
}

class _PartnerChatScreenState extends State<PartnerChatScreen> {
  final _service = ChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _textController.text;
    if (text.trim().isEmpty || _sending) return;
    _textController.clear();
    setState(() => _sending = true);
    try {
      await _service.sendText(myUid: widget.myUid, otherUid: widget.otherUid, text: text);
    } catch (_) {
      if (mounted) _showSnack('No se pudo enviar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1600);
      if (picked == null) return;
      setState(() => _sending = true);
      final bytes = await picked.readAsBytes();
      await _service.sendPhoto(myUid: widget.myUid, otherUid: widget.otherUid, bytes: bytes);
    } catch (_) {
      if (mounted) _showSnack('No se pudo enviar la foto. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeById(widget.themeId);
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);
    final primaryLight = Color(theme.primaryLight);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(widget.otherLabel),
              backgroundColor: primaryDark,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _service.watchMessages(myUid: widget.myUid, otherUid: widget.otherUid),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Todavía no hay mensajes. Escribe algo o manda una foto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final mine = m.senderUid == widget.myUid;
                    return _messageBubble(m, mine, primary, primaryLight);
                  },
                );
              },
            ),
          ),
          _inputBar(primary, primaryDark),
        ],
      ),
    );
  }

  Widget _messageBubble(ChatMessage m, bool mine, Color primary, Color primaryLight) {
    final bubbleColor = mine ? primary : Colors.white;
    final textColor = mine ? Colors.white : AppColors.textPrimary;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(mine ? 14 : 4),
      bottomRight: Radius.circular(mine ? 4 : 14),
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: m.photoUrl != null ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: m.photoUrl != null ? primaryLight : bubbleColor,
          borderRadius: radius,
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: m.photoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  m.photoUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      width: 160,
                      height: 160,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (context, error, stack) => const SizedBox(
                    width: 160,
                    height: 160,
                    child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted)),
                  ),
                ),
              )
            : Text(m.text ?? '', style: TextStyle(fontSize: 13.5, color: textColor)),
      ),
    );
  }

  Widget _inputBar(Color primary, Color primaryDark) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _sending ? null : _showAttachSheet,
              icon: Icon(Icons.camera_alt_outlined, color: primaryDark),
              tooltip: 'Adjuntar foto',
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje',
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: _sending ? null : _sendText,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
