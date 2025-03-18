//
//  ContentView.swift
//  BookWize
//
//  Created by Aryan Singh on 17/03/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Welcome message with adjusted alignment
                    Text("Select your role")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 50)
                    
                    // Role selection cards with colorful icons
                    VStack(spacing: 16) {
                        RoleCard(title: "Member", 
                               icon: "person.fill", 
                               iconColor: Color(hex: "007AFF"),  // iOS blue
                               cardColor: Color(hex: "F8F1E9"))
                        
                        RoleCard(title: "Librarian", 
                               icon: "books.vertical.fill", 
                               iconColor: Color(hex: "34C759"),  // iOS green
                               cardColor: Color(hex: "F8F1E9"))
                        
                        RoleCard(title: "Admin", 
                               icon: "gear", 
                               iconColor: Color(hex: "AF52DE"),  // iOS purple
                               cardColor: Color(hex: "F8F1E9"))
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationBarHidden(true)
            .background(Color(hex: "F5EBE0")) // Lighter beige background
        }
    }
}

struct RoleCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let cardColor: Color
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 48, height: 48)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "463F3A"))  // Dark brown text
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(hex: "463F3A").opacity(0.6))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardColor)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) Role")
        .accessibilityHint("Tap to continue as \(title)")
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
    
    @ViewBuilder
    private var destination: some View {
        switch title {
        case "Admin":
            AdminLoginView()
        default:
            Text("\(title) View")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
