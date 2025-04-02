import SwiftUI

struct LibrarianManagementView: View {
    @State private var showAddLibrarian = false
    @State private var librarians: [LibrarianData] = []
    @State private var selectedSegment = 0
    @State private var isloading = false
    @State private var showProfile = false
    private let segments = ["Librarians", "Fines & Fees"]
    
    var onProfileTap: (() -> Void)? = nil
    
    func  fetchLibrarians(){
        isloading = true
        Task{
            if let data = await fetchLibrarian(){
                await MainActor.run{
                    librarians = data
                    isloading = false
                }
            }else{
                    await MainActor.run{
                        librarians = []
                        isloading = false
                    }
                }
            }
        }
    
    
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
                                        LibrarianCardView(librarian: librarian, onDelete: {
                                            fetchLibrarians()
                                        })
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
            .navigationTitle("Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        if let onProfileTap = onProfileTap {
                            onProfileTap()
                        } else {
                            showProfile = true
                        }
                    }) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showAddLibrarian) {
                AddLibrarianView { newLibrarian in
                    librarians.append(newLibrarian)
                }
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    AdminProfileView()
                        .navigationTitle("Profile")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDragIndicator(.visible)
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
