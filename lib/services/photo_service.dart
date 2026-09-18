import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

/// Selecciona una foto de la galería y la convierte al mismo formato que
/// usa el prototipo web: redimensionada a un ancho máximo de 480px y
/// comprimida como JPEG de calidad 0.7, codificada como data URL en
/// base64 (`data:image/jpeg;base64,...`). Así el campo `DayEntry.photo`
/// es un simple String que se guarda igual que el resto de los datos.
///
/// Usa `file_picker` (en vez de `image_picker`) porque `image_picker`
/// arrastra una dependencia de iOS (`objective_c`, para "native assets")
/// que falla al compilar en Windows cuando la ruta de la carpeta de
/// usuario contiene un espacio (por ejemplo "C:\Users\Nombre 2\..."),
/// aunque solo se compile para Android. `file_picker` no tiene ese
/// problema y ya se usa en esta app para exportar/importar el backup.
///
/// NOTA DE CONFIGURACIÓN NATIVA (Android):
/// En versiones recientes de Android (13+) el selector de archivos del
/// sistema no requiere permisos adicionales en tiempo de ejecución. En
/// versiones más viejas de Android puede hacer falta declarar en
/// `android/app/src/main/AndroidManifest.xml`, dentro de <manifest> y
/// antes de <application>:
///
/// <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
/// <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
///     android:maxSdkVersion="32" />
class PhotoService {
  static const int _maxWidth = 480;
  static const int _jpegQuality = 70; // ~0.7 de calidad, escala 0-100 en el paquete `image`

  /// Abre el selector de archivos filtrado a imágenes, redimensiona y
  /// comprime la elegida. Devuelve `null` si el usuario cancela la
  /// selección.
  Future<String?> pickAndResizeFromGallery() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final picked = result?.files.single;
    final bytes = picked?.bytes;
    if (bytes == null) return null;
    return resizeToDataUrl(bytes);
  }

  /// Redimensiona los bytes de una imagen a un ancho máximo de 480px
  /// (manteniendo proporción, sin agrandar imágenes ya más pequeñas),
  /// la comprime como JPEG y la devuelve como data URL base64 — equivalente
  /// exacto de `resizeImageFile` en el prototipo JS.
  String? resizeToDataUrl(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final scale = _maxWidth / decoded.width;
    final img.Image resized = scale < 1
        ? img.copyResize(decoded, width: _maxWidth)
        : decoded;

    final jpegBytes = img.encodeJpg(resized, quality: _jpegQuality);
    final base64Str = base64Encode(jpegBytes);
    return 'data:image/jpeg;base64,$base64Str';
  }

  /// Decodifica un data URL (`data:image/jpeg;base64,...`) a bytes crudos,
  /// útil para mostrarlo con `Image.memory`.
  static Uint8List? decodeDataUrl(String? dataUrl) {
    if (dataUrl == null) return null;
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex == -1) return null;
    try {
      return base64Decode(dataUrl.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}
