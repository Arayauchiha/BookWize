import SwiftUI

struct FineManagementView: View {
    @StateObject private var fineManager = FineManager()
    @StateObject private var userManager = UserManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // First Row
                    HStack(spacing: 16) {
                        DashboardCard(
                            title: "Total Books",
                            value: "\(userManager.totalBooks)",
                            icon: "book.fill",
                            color: .blue
                        )
                        
                        DashboardCard(
                            title: "Issued Books",
                            value: "\(userManager.totalIssuedCount)",
                            icon: "book.circle.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Second Row
                    HStack(spacing: 16) {
                        DashboardCard(
                            title: "Fine Overdue",
                            value: String(format: "$%.2f", calculateTotalFine()),
                            icon: "dollarsign.circle.fill",
                            color: .red
                        )
                        
                        DashboardCard(
                            title: "Total Members",
                            value: "\(userManager.members.count)",
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
                            GenreStatsCard(
                                title: "Popular Genres",
                                genres: userManager.getPopularGenres(),
                                color: .orange
                            )
                            
                            GenreStatsCard(
                                title: "Genre-wise Issued",
                                genres: userManager.getGenreWiseIssues(),
                                color: .teal
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Overdue Books Section
                    Group {
                        Text("Overdue Books")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: OverdueBooksListView()) {
                            OverdueSummaryCard(
                                overdueCount: fineManager.overdueBooks.count,
                                totalFine: calculateTotalFine()
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }
    
    private func calculateTotalFine() -> Double {
        return fineManager.overdueBooks.reduce(0) { total, record in
            total + record.fineAmount
        }
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

struct GenreStatsCard: View {
    let title: String
    let genres: [(String, Int)]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                Text("\(genres.count)")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if genres.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(genres.prefix(3), id: \.0) { genre, count in
                    HStack {
                        Text(genre)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(color)
                    }
                }
            }
            
            if genres.count > 3 {
                Text("+ \(genres.count - 3) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
