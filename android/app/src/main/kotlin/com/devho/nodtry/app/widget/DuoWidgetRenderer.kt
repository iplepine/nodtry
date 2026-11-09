package com.devho.nodtry.app.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.devho.nodtry.app.MainActivity
import com.devho.nodtry.app.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/** Builds the RemoteViews of both widget sizes from the app's snapshot. */
object DuoWidgetRenderer {

    /** The small widget is drawn as 2x2 from this height (dp) on. A 2x1 cell is
     *  80-120dp tall depending on the launcher, too short for the tall layout. */
    private const val TALL_MIN_HEIGHT_DP = 150

    fun renderSmall(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        snapshot: DuoWidgetSnapshot?,
    ): RemoteViews {
        val compact = build(context, R.layout.duo_widget_small, snapshot)
        val tall = build(context, R.layout.duo_widget_small_tall, snapshot)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // The launcher picks the layout for the current size itself.
            return RemoteViews(
                mapOf(
                    SizeF(100f, 40f) to compact,
                    SizeF(100f, TALL_MIN_HEIGHT_DP.toFloat()) to tall,
                ),
            )
        }
        val options: Bundle = manager.getAppWidgetOptions(widgetId)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return if (minHeight >= TALL_MIN_HEIGHT_DP) tall else compact
    }

    /** Hidden in the placeholder; ids missing from a layout are skipped. */
    private val PERSON_VIEWS = intArrayOf(
        R.id.duo_widget_brand,
        R.id.duo_widget_people,
        R.id.duo_widget_me_row,
        R.id.duo_widget_partner_row,
    )

    fun renderMedium(context: Context, snapshot: DuoWidgetSnapshot?): RemoteViews =
        build(context, R.layout.duo_widget_medium, snapshot)

    private fun build(context: Context, layout: Int, snapshot: DuoWidgetSnapshot?): RemoteViews {
        val views = RemoteViews(context.packageName, layout)
        // Tap anywhere: open the app (HomeScreen switches to the Now tab on the
        // home_widget click event; a cold start opens there anyway). No URI, so
        // Flutter's deep linking doesn't route past the splash screen.
        views.setOnClickPendingIntent(
            R.id.duo_widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        // The person rows and the brand line only make sense with data; the
        // placeholder is the app name and one line of copy.
        val dataVisibility = if (snapshot == null) View.GONE else View.VISIBLE
        for (id in PERSON_VIEWS) views.setViewVisibility(id, dataVisibility)

        if (snapshot == null) {
            views.setTextViewText(
                R.id.duo_widget_headline,
                context.getString(R.string.duo_widget_placeholder_title),
            )
            val body = context.getString(R.string.duo_widget_placeholder_body)
            views.setTextViewText(R.id.duo_widget_summary, body)
            views.setTextViewText(R.id.duo_widget_placeholder_body, body)
            views.setViewVisibility(R.id.duo_widget_placeholder_body, View.VISIBLE)
            showBadge(views, null)
            views.setTextViewText(R.id.duo_widget_me_name, "")
            views.setTextViewText(R.id.duo_widget_me_status, "")
            views.setTextViewText(R.id.duo_widget_partner_name, "")
            views.setTextViewText(R.id.duo_widget_partner_status, "")
            return views
        }

        views.setViewVisibility(R.id.duo_widget_placeholder_body, View.GONE)
        val stale = snapshot.isStale()
        val dash = context.getString(R.string.duo_widget_no_status)
        val meText = if (stale) dash else snapshot.meText
        val partnerText = if (stale) dash else snapshot.partnerText

        views.setTextViewText(R.id.duo_widget_headline, snapshot.headline)
        views.setTextViewText(
            R.id.duo_widget_summary,
            if (stale) {
                snapshot.staleText
            } else {
                "${snapshot.meName} ${snapshot.meText} · ${snapshot.partnerName} ${snapshot.partnerText}"
            },
        )
        showBadge(views, if (stale) snapshot.staleText else snapshot.badge)

        views.setTextViewText(R.id.duo_widget_me_name, snapshot.meName)
        views.setTextViewText(R.id.duo_widget_me_status, meText)
        views.setTextViewText(R.id.duo_widget_partner_name, snapshot.partnerName)
        views.setTextViewText(R.id.duo_widget_partner_status, partnerText)
        setStatusColor(context, views, R.id.duo_widget_me_status, if (stale) "" else snapshot.meStatus)
        setStatusColor(
            context,
            views,
            R.id.duo_widget_partner_status,
            if (stale) "" else snapshot.partnerStatus,
        )
        return views
    }

    private fun showBadge(views: RemoteViews, text: String?) {
        if (text.isNullOrEmpty()) {
            views.setViewVisibility(R.id.duo_widget_badge, View.GONE)
        } else {
            views.setTextViewText(R.id.duo_widget_badge, text)
            views.setViewVisibility(R.id.duo_widget_badge, View.VISIBLE)
        }
    }

    private fun statusColorRes(status: String): Int =
        when (status) {
            "done", "done_proof" -> R.color.duo_widget_primary
            "pending" -> R.color.duo_widget_text
            else -> R.color.duo_widget_text_secondary
        }

    /**
     * Android 12+: pass the color *resource* so the launcher resolves it in its
     * own configuration and the text follows light/dark mode (values-night)
     * without a redraw from the app. A resolved int would keep the colors of
     * the mode the widget was last drawn in (dark text on the dark card).
     */
    private fun setStatusColor(context: Context, views: RemoteViews, viewId: Int, status: String) {
        val res = statusColorRes(status)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setColorStateList(viewId, "setTextColor", res)
        } else {
            views.setTextColor(viewId, context.getColor(res))
        }
    }
}
