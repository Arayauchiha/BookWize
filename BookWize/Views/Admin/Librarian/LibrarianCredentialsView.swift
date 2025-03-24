import SwiftUI

struct LibrarianCredentials: Identifiable {
    var id = UUID()
    let name: String
    let email: String
    let tempPassword: String
}

struct LibrarianCredentialsView: View {
    let credentials: LibrarianCredentials
    @State private var isSending = false
    @State private var isSent = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Librarian Credentials")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Name: \(credentials.name)")
                Text("Email: \(credentials.email)")
                Text("Temporary Password: \(credentials.tempPassword)")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                sendCredentialsEmail()
            }) {
                if isSending {
                    ProgressView()
                } else if isSent {
                    Label("Email Sent", systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                } else {
                    Text("Send Credentials via Email")
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSent ? Color.green.opacity(0.2) : Color.blue)
            .foregroundColor(isSent ? .green : .white)
            .cornerRadius(10)
            .disabled(isSending || isSent)
        }
        .padding()
    }
    
    func sendCredentialsEmail() {
        isSending = true
        
        Task {
            let emailService = EmailService()
            let subject = "Your BookWize Librarian Credentials"
            let body = """
                Hello \(credentials.name),
                
                Your librarian account has been created for BookWize.
                
                Email: \(credentials.email)
                Temporary Password: \(credentials.tempPassword)
                
                Please note that you will need to change your password on first login.
                
                Regards,
                BookWize Admin Team
                """
            
            let success = await emailService.sendEmail(
                to: credentials.email,
                subject: subject, 
                body: body
            )
            
            DispatchQueue.main.async {
                isSending = false
                if success {
                    isSent = true
                    errorMessage = ""
                } else {
                    errorMessage = "Failed to send email"
                }
            }
        }
    }
}

struct LibrarianCredentialsView_Previews: PreviewProvider {
    static var previews: some View {
        LibrarianCredentialsView(
            credentials: LibrarianCredentials(
                name: "John Smith",
                email: "john@example.com",
                tempPassword: "temp123"
            )
        )
    }
}
