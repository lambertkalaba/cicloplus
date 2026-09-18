package com.cicloplus.cicloplus_app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (en vez de FlutterActivity) es requerido por el
// paquete `health` para el flujo de permisos de Health Connect en
// Android 14+ (usa registerForActivityResult, que necesita FragmentActivity).
class MainActivity : FlutterFragmentActivity()
