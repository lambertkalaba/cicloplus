import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Cámara para escanear el código QR de invitación de otra persona (ver
/// "Invitar a un socio" > "¿Te compartieron un código?"). Al detectar un
/// código, esta pantalla se cierra sola devolviendo el texto leído; quien
/// la abre decide qué hacer con él (en este caso, rellenar el campo y
/// vincularse automáticamente — ver InvitePartnerScreen._scanCode).
///
/// Nota: la protección real de "solo lectura" no depende de este código
/// QR en absoluto — el texto codificado es exactamente el mismo código
/// alfanumérico que ya se comparte a mano o con "Compartir" (ver
/// PartnerService), así que escanear un QR no abre ningún permiso nuevo
/// que compartir el texto no abriera ya.
class QrScanScreen extends StatefulWidget {
  final Color primaryColor;

  const QrScanScreen({super.key, required this.primaryColor});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Se queda con el primer código legible del frame y cierra la pantalla
  // devolviéndolo; una bandera evita procesar más de un frame a la vez
  // mientras la navegación de vuelta todavía está en curso.
  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.trim().isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Marco de guía puramente visual — MobileScanner ya analiza todo
          // el fotograma de la cámara, esto no recorta ni limita nada.
          Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Escanear código QR',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await _controller.toggleTorch();
                      if (mounted) setState(() => _torchOn = !_torchOn);
                    },
                    icon: Icon(
                      _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Linterna',
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              'Apunta la cámara al código QR que te compartieron',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
