//
//  MemberLoginView.swift
//  BookWize
//
//  Created by Aditya Singh on 20/03/25.
//

import SwiftUI

struct MemberLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingVerificationSheet = false
    @State private var verificationCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Member Login")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
            
            Button(action: attemptLogin) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isLoading)
            
            NavigationLink("Don't have an account? Sign up") {
                SignupView() // Change from SignUp to SignupView to match your actual view name
            }
            .foregroundColor(.blue)
        }
        .padding()
        .sheet(isPresented: $showingVerificationSheet) {
            verificationView
        }
    }
    
    private var verificationView: some View {
        VStack(spacing: 20) {
            Text("Verify Your Email")
                .font(.headline)
                .padding(.top)
            
            Text("A verification code has been sent to \(email)")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            
            TextField("Verification Code", text: $verificationCode)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .keyboardType(.numberPad)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
            
            Button("Verify") {
                verifyOTP()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Resend Code") {
                Task {
                    await sendVerificationEmail()
                }
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
    
    private func attemptLogin() {
        // In a real app, you would validate against database
        // For now, just simulate a successful login
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            
            // For demo, accept any non-empty credentials
            if !email.isEmpty && !password.isEmpty {
                Task {
                    await sendVerificationEmail()
                    showingVerificationSheet = true
                }
            } else {
                errorMessage = "Please enter both email and password"
            }
        }
    }
    
    private func sendVerificationEmail() async {
        let success = await OTPManager.shared.sendOTPEmail(to: email) // Use the correct method name
        if !success {
            DispatchQueue.main.async {
                errorMessage = "Failed to send verification email"
            }
        }
    }
    
    private func verifyOTP() {
        if OTPManager.shared.verifyOTP(email: email, code: verificationCode) {
            OTPManager.shared.clearOTP(for: email)
            isMemberLoggedIn = true
            showingVerificationSheet = false
        } else {
            errorMessage = "Invalid verification code"
        }
    }
}

#Preview {
    MemberLoginView()
}