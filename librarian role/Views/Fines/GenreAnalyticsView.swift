import SwiftUI
import Charts

struct GenreAnalyticsView: View {
    let genres: [(String, Int)]
    let color: Color
    
    private var totalIssues: Int {
        genres.reduce(0) { $0 + $1.1 }
    }
    
    private var mostPopularGenre: (String, Int)? {
        genres.max(by: { $0.1 < $1.1 })
    }
    
    private var leastPopularGenre: (String, Int)? {
        genres.min(by: { $0.1 < $1.1 })
    }
    
    private var averageIssuesPerGenre: Double {
        guard !genres.isEmpty else { return 0 }
        return Double(totalIssues) / Double(genres.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Chart Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Genre Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(genres, id: \.0) { genre in
                            BarMark(
                                x: .value("Genre", genre.0),
                                y: .value("Count", genre.1)
                            )
                            .foregroundStyle(color)
                        }
                    }
                    .frame(height: 300)
                    .padding()
                }
                
                // Analysis Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Analysis")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Key Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        StatisticRow(
                            title: "Total Issues",
                            value: "\(totalIssues)",
                            icon: "book.fill",
                            color: .blue
                        )
                        
                        if let popular = mostPopularGenre {
                            StatisticRow(
                                title: "Most Popular Genre",
                                value: "\(popular.0) (\(popular.1) issues)",
                                icon: "star.fill",
                                color: .yellow
                            )
                        }
                        
                        if let least = leastPopularGenre {
                            StatisticRow(
                                title: "Least Popular Genre",
                                value: "\(least.0) (\(least.1) issues)",
                                icon: "star",
                                color: .gray
                            )
                        }
                        
                        StatisticRow(
                            title: "Average Issues per Genre",
                            value: String(format: "%.1f", averageIssuesPerGenre),
                            icon: "chart.bar.fill",
                            color: .green
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Insights
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Insights")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        InsightCard(
                            title: "Genre Distribution",
                            content: "There are \(genres.count) active genres in the library, with \(totalIssues) total issues across all genres.",
                            icon: "chart.pie.fill",
                            color: .blue
                        )
                        
                        if let popular = mostPopularGenre {
                            InsightCard(
                                title: "Popular Genre Analysis",
                                content: "\(popular.0) leads with \(popular.1) issues, representing \(String(format: "%.1f%%", Double(popular.1) / Double(totalIssues) * 100)) of total issues.",
                                icon: "arrow.up.circle.fill",
                                color: .green
                            )
                        }
                        
                        if let least = leastPopularGenre {
                            InsightCard(
                                title: "Improvement Opportunity",
                                content: "Consider promoting \(least.0) genre books to increase circulation, currently at \(least.1) issues.",
                                icon: "lightbulb.fill",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Genre Analytics")
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct InsightCard: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
} 
