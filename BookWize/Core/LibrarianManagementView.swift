import SwiftUI

struct LibrarianManagementView: View {
    @State private var showAddLibrarian = false
    @State private var librarians: [LibrarianData] = []
    @State private var selectedSegment = 0
    
    private let segments = ["Librarians", "Fines & Fees"]
    
    func fetchLibrarian() async -> [LibrarianData]? {
        let data: [LibrarianData]? = try? await SupabaseManager.shared.client
            .from("Users")
            .select("*")
            .eq("roleFetched", value: "librarian")
            .execute()
            .value
        return data
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedSegment == 0 {
                    ScrollView {
                        VStack(spacing: 20) {
                            if librarians.isEmpty {
                                ContentUnavailableView("No Librarians",
                                    systemImage: "person.2.slash",
                                    description: Text("Add your first librarian to get started")
                                )
                                .foregroundStyle(Color.customText)
                                .padding(.top, 40)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(librarians, id: \.email) { librarian in
                                        LibrarianCardView(librarian: librarian)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            Button(action: { showAddLibrarian = true }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add Librarian")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.librarianColor)
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }
                    }
                } else {
                    FineAndMembershipManagement()
                }
            }
            .background(Color.customBackground)
            .navigationTitle(segments[selectedSegment])
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddLibrarian) {
                AddLibrarianView { newLibrarian in
                    librarians.append(newLibrarian)
                }
            }
            .task {
                librarians = (await fetchLibrarian()) ?? []
            }
        }
    }
}

#Preview {
    LibrarianManagementView()
}
