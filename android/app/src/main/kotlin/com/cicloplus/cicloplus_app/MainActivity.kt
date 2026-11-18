package com.cicloplus.cicloplus_app

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (en vez de FlutterActivity) es requerido por el
// paquete `health` para el flujo de permisos de Health Connect en
// Android 14+ (usa registerForActivityResult, que necesita FragmentActivity).
//
// Icono discreto: DiscreetActivity es una copia de esta actividad con otro
// icono y nombre ("Diario"). Al activarlo se habilita DiscreetActivity y se
// deshabilita MainActivity (y al revés). MainActivity sigue siendo el
// lanzador por defecto, así que a quien no use la opción no le cambia nada.
open class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cicloplus/icon")
            .setMethodCallHandler { call, result ->
                val pm = packageManager
                val main = ComponentName(this, MainActivity::class.java)
                val discreet = ComponentName(this, DiscreetActivity::class.java)
                when (call.method) {
                    "isDiscreet" -> result.success(
                        pm.getComponentEnabledSetting(discreet) ==
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                    )
                    "setDiscreet" -> {
                        val on = call.arguments as? Boolean ?: false
                        try {
                            // Primero se habilita el nuevo, luego se deshabilita
                            // el viejo: así nunca queda la app sin lanzador.
                            pm.setComponentEnabledSetting(
                                if (on) discreet else main,
                                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                                PackageManager.DONT_KILL_APP
                            )
                            pm.setComponentEnabledSetting(
                                if (on) main else discreet,
                                if (on) PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                                else PackageManager.COMPONENT_ENABLED_STATE_DEFAULT,
                                PackageManager.DONT_KILL_APP
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("icon", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

class DiscreetActivity : MainActivity()
