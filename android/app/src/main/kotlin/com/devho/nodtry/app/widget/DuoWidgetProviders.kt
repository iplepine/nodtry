package com.devho.nodtry.app.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 2x1 (resizable to 2x2) home-screen widget: duo streak + today. Registered in
 * AndroidManifest.xml; redrawn by the app through home_widget's
 * `updateWidget(qualifiedAndroidName: …)` (lib/features/widget_sync).
 */
class DuoWidgetSmallProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val snapshot = DuoWidgetSnapshot.read(widgetData)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(
                id,
                DuoWidgetRenderer.renderSmall(context, appWidgetManager, id, snapshot),
            )
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val snapshot = DuoWidgetSnapshot.read(HomeWidgetPlugin.getData(context))
        appWidgetManager.updateAppWidget(
            appWidgetId,
            DuoWidgetRenderer.renderSmall(context, appWidgetManager, appWidgetId, snapshot),
        )
    }
}

/** 4x2 home-screen widget: streak, badge and a card per person. */
class DuoWidgetMediumProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val snapshot = DuoWidgetSnapshot.read(widgetData)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, DuoWidgetRenderer.renderMedium(context, snapshot))
        }
    }
}
