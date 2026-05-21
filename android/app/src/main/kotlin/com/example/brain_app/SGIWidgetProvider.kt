package com.example.brain_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class SGIWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val totalTasks = widgetData.getInt("totalTasks", 0)
        val completedTasks = widgetData.getInt("completedTasks", 0)
        val overdueTasks = widgetData.getInt("overdueTasks", 0)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.sgi_widget_layout)

            views.setTextViewText(R.id.total_tasks, totalTasks.toString())
            views.setTextViewText(R.id.completed_tasks, completedTasks.toString())
            views.setTextViewText(R.id.overdue_tasks, overdueTasks.toString())

            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
