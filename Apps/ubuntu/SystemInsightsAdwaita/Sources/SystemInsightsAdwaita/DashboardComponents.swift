import Adwaita
import Foundation
import SystemInsightCore

struct HealthHeroCard: View {
    let snapshot: InsightSnapshot

    var view: Body {
        VStack {
            HStack {
                VStack {
                    Text("System health")
                        .captionHeading()
                        .dimLabel()
                    Text("\(snapshot.score)")
                        .title1()
                        .numeric()
                    Text("/ 100")
                        .caption()
                        .dimLabel()
                }
                .halign(.start)

                VStack {
                    Text(DashboardFormatting.ratingLabel(snapshot.rating))
                        .heading()
                        .success(snapshot.rating == .good)
                        .warning(snapshot.rating == .warning)
                        .error(snapshot.rating == .critical)
                    Text(snapshot.host.hostName)
                        .caption()
                        .dimLabel()
                }
                .halign(.end)
            }
            .padding()

            ProgressBar(value: Double(snapshot.score), total: 100)
                .padding()

            Text("Updated \(DashboardFormatting.relativeTime(since: snapshot.generatedAt))")
                .caption()
                .dimLabel()
                .padding()
        }
        .card()
        .padding()
    }
}

struct ResourceMetricsRow: View {
    let snapshot: InsightSnapshot

    var view: Body {
        HStack {
            ResourceMetricCard(
                title: "CPU",
                value: snapshot.metrics.cpuLoadPercent,
                icon: .default(icon: .applicationsSystem)
            )
            ResourceMetricCard(
                title: "Memory",
                value: snapshot.metrics.memoryPressurePercent,
                icon: .default(icon: .applicationsUtilities)
            )
            ResourceMetricCard(
                title: "Disk",
                value: snapshot.metrics.diskUsagePercent,
                icon: .default(icon: .driveHarddisk)
            )
        }
        .padding()
    }
}

struct ResourceMetricCard: View {
    let title: String
    let value: Double
    let icon: Icon

    var view: Body {
        VStack {
            Image()
                .iconName(icon.string)
                .pixelSize(22)
            Text(title)
                .captionHeading()
                .dimLabel()
            Text(DashboardFormatting.percent(value))
                .title2()
                .numeric()
            LevelBar()
                .value(value)
                .minValue(0)
                .maxValue(100)
                .padding()
        }
        .padding()
        .frame(minWidth: 140)
        .card()
    }
}

struct InsightHighlightCard: View {
    let title: String
    let detail: String
    let recommendation: String?

    var view: Body {
        FormSection(title) {
            Form {
                ActionRow(detail)
                if let recommendation {
                    ActionRow("Recommended action")
                        .subtitle(recommendation)
                        .property()
                }
            }
        }
        .padding()
    }
}

struct DashboardFormSection: View {
    let title: String
    let rows: [DashboardRow]

    var view: Body {
        FormSection(title) {
            Form {
                ForEach(rows) { row in
                    ActionRow(row.title)
                        .subtitle(row.subtitle)
                }
            }
        }
        .padding()
    }
}

struct DashboardRow: Identifiable, Sendable {
    let title: String
    let subtitle: String

    var id: String { "\(title)|\(subtitle)" }
}

struct DashboardStatusBanner: View {
    let message: String
    let visible: Bool
    let onDismiss: () -> Void

    var view: Body {
        Banner(message, visible: visible)
            .button("Dismiss", handler: onDismiss)
            .padding()
    }
}
