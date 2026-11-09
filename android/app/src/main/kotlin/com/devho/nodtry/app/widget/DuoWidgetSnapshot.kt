package com.devho.nodtry.app.widget

import android.content.SharedPreferences
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The snapshot the app writes for the widgets (lib/features/widget_sync/domain/
 * duo_widget_snapshot.dart). Every string is already localized by the app;
 * this side only lays it out.
 */
data class DuoWidgetSnapshot(
    val date: String,
    val streak: Int,
    val headline: String,
    val badge: String?,
    val meName: String,
    val meStatus: String,
    val meText: String,
    val partnerName: String,
    val partnerStatus: String,
    val partnerText: String,
    val staleText: String,
) {
    /** The snapshot describes an earlier day: its statuses are no longer today's. */
    fun isStale(now: Date = Date()): Boolean = date != dateKey(now)

    companion object {
        /** Same key as `kDuoWidgetSnapshotKey` in Dart. */
        const val KEY = "duo_widget_snapshot_v1"

        fun dateKey(now: Date): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now)

        fun read(prefs: SharedPreferences): DuoWidgetSnapshot? {
            val raw = prefs.getString(KEY, null) ?: return null
            return parse(raw)
        }

        fun parse(raw: String): DuoWidgetSnapshot? =
            try {
                val json = JSONObject(raw)
                val me = json.getJSONObject("me")
                val partner = json.getJSONObject("partner")
                DuoWidgetSnapshot(
                    date = json.optString("date"),
                    streak = json.optInt("streak", 0),
                    headline = json.optString("headline"),
                    badge = if (json.isNull("badge")) null else json.optString("badge").ifEmpty { null },
                    meName = me.optString("name"),
                    meStatus = me.optString("status"),
                    meText = me.optString("text"),
                    partnerName = partner.optString("name"),
                    partnerStatus = partner.optString("status"),
                    partnerText = partner.optString("text"),
                    staleText = json.optString("stale"),
                )
            } catch (e: Exception) {
                null
            }
    }
}
