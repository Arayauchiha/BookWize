import SwiftUI
import Charts

struct GenreAnalyticsView: View {
    let genres: [(String, Int)]
    let color: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
            .padding(.vertical)
        }
        .navigationTitle("Genre Analytics")
    }
} 
