import WidgetKit
import SwiftUI
import home_widget

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SGIWidgetEntry {
        SGIWidgetEntry(
            date: Date(),
            totalTasks: 0,
            completedTasks: 0,
            overdueTasks: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SGIWidgetEntry) -> Void) {
        let entry = SGIWidgetEntry(
            date: Date(),
            totalTasks: HomeWidgetService.getInt(from: "totalTasks") ?? 0,
            completedTasks: HomeWidgetService.getInt(from: "completedTasks") ?? 0,
            overdueTasks: HomeWidgetService.getInt(from: "overdueTasks") ?? 0
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SGIWidgetEntry>) -> Void) {
        let entry = SGIWidgetEntry(
            date: Date(),
            totalTasks: HomeWidgetService.getInt(from: "totalTasks") ?? 0,
            completedTasks: HomeWidgetService.getInt(from: "completedTasks") ?? 0,
            overdueTasks: HomeWidgetService.getInt(from: "overdueTasks") ?? 0
        )
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SGIWidgetEntry: TimelineEntry {
    let date: Date
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
}

struct SGIWidgetEntryView: View {
    var entry: Provider.Entry

    var progress: Double {
        guard entry.totalTasks > 0 else { return 0 }
        return Double(entry.completedTasks) / Double(entry.totalTasks)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("SGI - Hoy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
                Spacer()
            }

            HStack(spacing: 0) {
                StatView(value: entry.totalTasks, label: "Tareas", color: .blue)
                StatView(value: entry.completedTasks, label: "Completadas", color: .green)
                StatView(value: entry.overdueTasks, label: "Vencidas", color: .red)
            }

            ProgressView(value: progress)
                .tint(.green)
                .padding(.top, 4)

            Text("\(Int(progress * 100))% completado")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(.background, for: .widget)
    }
}

struct StatView: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SGIWidget: Widget {
    let kind: String = "SGITodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SGIWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tareas de Hoy")
        .description("Muestra el resumen de tus tareas del día")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
