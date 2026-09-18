// Generado a mano a partir del archivo google-services.json que descargaste
// de la Configuración del proyecto en Firebase (proyecto "CicloPlus",
// ID cicloplus-9a957). Normalmente esto lo genera automáticamente el
// comando `flutterfire configure`, pero como no tengo Flutter instalado en
// mi entorno de trabajo para ejecutarlo, lo construí manualmente con los
// mismos valores exactos de tu archivo.
//
// Solo tiene la configuración de Android por ahora (es la única plataforma
// que registraste en Firebase). Si más adelante agregas iOS o la app web,
// hay que volver a este archivo y sumar esa configuración — dímelo cuando
// llegue ese momento.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions no tiene configuración para la plataforma web '
        'todavía. Esto se agrega en la fase de construir la página web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions no tiene configuración para iOS todavía. '
          'Se agrega cuando registremos la app iOS en Firebase.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no soporta esta plataforma todavía: '
          '$defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBHXCw0EIuJoPDvBAEh828fQBs9R9_0IBo',
    appId: '1:455122663711:android:6cecf656dace0b1a02182a',
    messagingSenderId: '455122663711',
    projectId: 'cicloplus-9a957',
    storageBucket: 'cicloplus-9a957.firebasestorage.app',
  );
}
