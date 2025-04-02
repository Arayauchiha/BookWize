import SwiftUI
import Charts

struct LibrarianDashboard: View {
    @StateObject private var dashboardManager = DashboardManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // First Row
                    HStack(spacing: 16) {
                        DashboardCard(
                            title: "Total Books",
                            value: "\(dashboardManager.totalBooksCount)",
                            icon: "book.fill",
                            color: .blue
                        )
                        
                        DashboardCard(
                            title: "Issued Books",
                            value: "\(dashboardManager.issuedBooksCount)",
                            icon: "book.circle.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Second Row
                    HStack(spacing: 16) {
                        DashboardCard(
                            title: "Fine Overdue",
                            value: String(format: "$%.2f", dashboardManager.overdueFines),
                            icon: "dollarsign.circle.fill",
                            color: .red
                        )
                        
                        DashboardCard(
                            title: "Total Members",
                            value: "\(dashboardManager.totalMembersCount)",
                            icon: "person.3.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Analytics Section
                    Group {
                        Text("Analytics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            if let mostPopularGenre = getPopularGenres().first {
                                PopularGenreCard(
                                    title: "Popular Genres",
                                    genre: mostPopularGenre.0,
                                    color: .orange
                                )
                            }
                            
                            GenreStatsCard(
                                title: "Genre-wise Issued",
                                genres: getGenreWiseIssues(),
                                color: .teal
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Overdue Books Section
//                    Group {
//                        Text("Overdue Books")
//                            .font(.title2)
//                            .fontWeight(.bold)
//                            .padding(.top)
//                            .padding(.horizontal)
//                        
//                        NavigationLink(destination: OverdueBooksListView()) {
//                            OverdueSummaryCard(
//                                //overdueCount: fineManager.overdueBooks.count,
//                                totalFine: calculateTotalFine()
//                            )
//                            .padding(.horizontal)
//                        }
//                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await dashboardManager.fetchDashboardData()
            }
        }
    }
    
    private func getPopularGenres() -> [(String, Int)] {
        return dashboardManager.getPopularGenres()
    }
    
    private func getGenreWiseIssues() -> [(String, Int)] {
        return dashboardManager.getGenreWiseIssues()
    }
    
    private func calculateTotalFine() -> Double {
        return dashboardManager.overdueFines
    }
}

struct OverdueSummaryCard: View {
    let overdueCount: Int
    let totalFine: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Overdue Books")
                        .font(.headline)
                }
                
                Text("\(overdueCount) books • $\(String(format: "%.2f", totalFine)) in fines")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SummaryItem: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.secondaryTextColor)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.secondaryTextColor)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondaryTextColor)
            
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


struct SimpleMiniBarGraph: View {
    let data: [(String, Int)]
    let color: Color
    
    // Compute the maximum value for scaling
    private var maxValue: Int {
        let max = data.map { $0.1 }.max() ?? 1
        return max > 0 ? max : 1 // Ensure we don't divide by zero
    }
    
    var body: some View {
        // Center the graph with explicit frame and alignment
        VStack {
            HStack(alignment: .bottom, spacing: 4) {
                // Create a fixed number of bars for testing visibility
                ForEach(0..<min(data.count, 7), id: \.self) { index in
                    let item = data[index]
                    let height = max(4, CGFloat(item.1) * 40 / CGFloat(maxValue))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: 4, height: height)
                        .cornerRadius(2)
                }
            }
            .frame(height: 40, alignment: .bottom)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .background(Color.clear) // Add this to see the bounds
    }
}

// Updated GenreStatsCard with debugging info
struct GenreStatsCard: View {
    let title: String
    let genres: [(String, Int)]
    let color: Color
    
    var body: some View {
        NavigationLink(destination: GenreAnalyticsView(genres: genres, color: color)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                    if let genre = genres.first {
                        Text(genre.0)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primary)
                    }
                }
                
                // Add debug text to check if genres data exists
//                Text("Debug: \(genres.count) genres")
//                    .font(.caption)
//                    .foregroundColor(.gray)
                
                // Simplified graph
                SimpleMiniBarGraph(data: genres, color: color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct PopularGenreCard: View {
    let title: String
    let genre: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                Text(genre)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
