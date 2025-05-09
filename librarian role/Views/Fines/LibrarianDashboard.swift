import SwiftUI
import Charts

struct LibrarianDashboard: View {
    @StateObject private var dashboardManager = DashboardManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Stats Grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
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
                    
                    DashboardCard(
                        title: "Members with Overdue Fines",
                        value: "\(dashboardManager.overdueMembersCount)",
                        icon: "exclamationmark.triangle.fill",
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
                        .dynamicTypeSize(.small ... .accessibility3)
                    
                    HStack(spacing: 16) {
                        if let mostPopularGenre = getPopularGenres().first {
                            PopularGenreCard(
                                title: "Popular Genres",
                                genre: mostPopularGenre.0,
                                color: .orange,
                                count: mostPopularGenre.1
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
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Overdues")
                            .font(.title2)
                            .fontWeight(.bold)
                            .dynamicTypeSize(.small ... .accessibility3)
                        
                        Spacer()
                        
                        NavigationLink(destination: OverdueBooksListView()) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .dynamicTypeSize(.small ... .accessibility2)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(dashboardManager.overdueFines > 0 ? "₹\(String(format: "%.2f", dashboardManager.overdueFines))" : "₹0.00")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .dynamicTypeSize(.small ... .accessibility3)
                        
                        Text("Total Overdue Fines")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .dynamicTypeSize(.small ... .accessibility2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.customCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .padding(.vertical)
        }
        .background(Color.customBackground)
        .refreshable {
            await dashboardManager.fetchDashboardData()
        }
        .onAppear {
            Task {
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

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.secondaryTextColor)
                .padding(.leading, 8)
            
            TextField(placeholder, text: $text)
                .dynamicTypeSize(.small ... .accessibility2)
                .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    LibrarianDashboard()
        .environment(\.colorScheme, .light)
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
                    Text("Overdue ")
                        .font(.headline)
                        .dynamicTypeSize(.small ... .accessibility2)
                }
                
                Text("\(overdueCount) books • $\(String(format: "%.2f", totalFine)) in fines")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .dynamicTypeSize(.small ... .accessibility2)
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
                .dynamicTypeSize(.small ... .accessibility3)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryTextColor)
                .dynamicTypeSize(.small ... .accessibility2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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
                .dynamicTypeSize(.small ... .accessibility3)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(.small ... .accessibility2)
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
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                    .dynamicTypeSize(.small ... .accessibility3)
            }
            .frame(height: 30)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .dynamicTypeSize(.small ... .accessibility2)
        }
        .padding()
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color.customCardBackground)
        .cornerRadius(12)
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

struct GenreStatsCard: View {
    let title: String
    let genres: [(String, Int)]
    let color: Color
    
    var body: some View {
        NavigationLink(destination: GenreAnalyticsView(genres: genres, color: color)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 24, height: 24)
                    
                    if let genre = genres.first {
                        Text(genre.0)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                .frame(height: 30)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
                .padding()
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(Color.customCardBackground)
                .cornerRadius(12)
            }
        }
    }


struct PopularGenreCard: View {
    let title: String
    let genre: String
    let color: Color
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(genre)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(height: 30)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color.customCardBackground)
        .cornerRadius(12)
    }
}
