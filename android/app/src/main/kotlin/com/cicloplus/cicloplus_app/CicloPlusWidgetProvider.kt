package com.cicloplus.cicloplus_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget real de pantalla de inicio para CicloPlus (fase 8): pinta dos
 * líneas de texto (día de ciclo + cuenta atrás al próximo periodo) que
 * ya llegan traducidas desde Dart vía HomeWidgetService.update() — este
 * lado nativo no traduce nada, solo lee las dos claves guardadas por
 * HomeWidget.saveWidgetData() y las coloca en el layout.
 *
 * Tocar el widget abre la app directamente (mismo comportamiento que
 * cualquier icono de la pantalla de inicio).
 */
class CicloPlusWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.cicloplus_widget).apply {
                val cycleDayLine = widgetData.getString("cicloplus_widget_cycle_day_line", null)
                val periodLine = widgetData.getString("cicloplus_widget_period_line", null)
                setTextViewText(R.id.widget_cycle_day_line, cycleDayLine ?: "")
                if (periodLine.isNullOrEmpty()) {
                    setViewVisibility(R.id.widget_period_line, android.view.View.GONE)
                } else {
                    setViewVisibility(R.id.widget_period_line, android.view.View.VISIBLE)
                    setTextViewText(R.id.widget_period_line, periodLine)
                }

                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.cicloplus_widget_root, pendingIntent)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
