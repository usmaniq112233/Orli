//
//  SignupView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 23/06/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore



struct SignupView: View {
    
    @Environment(\.dismiss) var dismiss

    
    @State private var fullName = ""
    @State private var email = ""
    @State private var backupEmail = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoggedIn = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var currentAlert: AlertType?


    var body: some View {
        ZStack(alignment: .top) {
            
            ScrollView {
            
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Create your account")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color("Text"))
                        
                        Text("Start sending messages to the future")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 1)
                    
                    // Form Fields
                    Group {
                        formField(title: "Full Name", text: $fullName, placeholder: "John Doe")
                        formField(title: "Email", text: $email, placeholder: "your.email@example.com", keyboardType: .emailAddress)
                        formField(title: "Backup Email (Optional)", text: $backupEmail, placeholder: "backup.email@example.com", keyboardType: .emailAddress)
                        
                        Text("This email will be used if your account becomes inactive for 12 months.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, -12)
                    }
                    
                    Group {
                        SecureInputField(title: "Password", text: $password)
                        SecureInputField(title: "Confirm Password", text: $confirmPassword)
                    }
                    
                    // Submit Button
                    Button(action: {
                        // Sign up action
                        signUp()
                    }) {
                        Text("Create account")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Button"))
                            .cornerRadius(8)
                    }
                    .padding(.top)
                    
                    // Footer
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        Button("Log in") {
                            // Navigate to login
                            dismiss()
                        }
                        .foregroundColor(Color("Button"))
                    }
                    
                    Spacer()
                }
                .padding()
                
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        LottieView(animationName: "loader")
                            .frame(width: 150, height: 150)
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            
                
            }
            
            if showAlert, let alert = currentAlert {
                  AlertBanner(alert: alert)
                      .padding(.top, 60)
                      .transition(.move(edge: .top).combined(with: .opacity))
                      .animation(.easeInOut, value: showAlert)
                      .onAppear {
                          DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                              showAlert = false
                          }
                      }
              }
            
            if isLoading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        LottieView(animationName: "loader")
                            .frame(width: 150, height: 150)
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }
            
        }
        
        .background(Color("Primary"))
        .navigationBarHidden(true)
    .navigationDestination(isPresented: $isLoggedIn) {
        OnboardingView()
    }
}

    // MARK: - Components

    func formField(title: String, text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color("Text"))

            TextField(placeholder, text: text)
                .padding()
                .keyboardType(keyboardType)
                .background(Color(UIColor.secondarySystemBackground))
                .foregroundColor(Color("Text"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    struct SecureInputField: View {
        var title: String
        @Binding var text: String

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color("Text"))

                SecureField("●●●●●●●●", text: $text)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(Color("Text"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
    
    func signUp() {
        UIApplication.shared.endEditing()
        isLoading = true

        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty else {
            currentAlert = .warning(message: "Please fill all required fields.")
            showAlert = true
            isLoading = false
            return
        }

        guard password == confirmPassword else {
            currentAlert = .error(message: "Passwords do not match.")
            showAlert = true
            isLoading = false
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                currentAlert = .error(message: error.localizedDescription)
                showAlert = true
                isLoading = false
            } else if let user = authResult?.user {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                changeRequest.commitChanges { profileError in
                    if let profileError = profileError {
                        print("Profile update error: \(profileError.localizedDescription)")
                    }
                }

                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "fullName": fullName,
                    "email": email,
                    "backupEmail": backupEmail,
                    "createdAt": Timestamp(date: Date())
                ]

                db.collection("users").document(user.uid).setData(userData) { error in
                    isLoading = false
                    if let error = error {
                        currentAlert = .error(message: "Failed to save user data: \(error.localizedDescription)")
                        showAlert = true
                    } else {
                        currentAlert = .info(message: "Account created successfully!")
                        showAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoggedIn = true
                        }
                    }
                }
            }
        }
    }



}
