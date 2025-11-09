import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage


struct ProfileView: View {
    
    @StateObject var userManager = UserManager()

    @Binding var selectedTab: Tab
    @State private var backupEmail: String = ""
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var lastActive: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var currentAlert: AlertType?
    @State private var profileImage: UIImage? = nil


    var body: some View {
        ZStack(alignment: .top) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                                Image("top") // Replace with your actual logo asset name
                                    .resizable()
                                    .scaledToFit()
                                    .padding(.bottom, 10)
                            
                        Text("User Profile")
                            .font(.title)
                            .bold()
                        
                        // MARK: - User Info Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                if let image = profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: 60, height: 60)
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading) {
                                    if let user = userManager.currentUser {
                                        Text(user.fullName)
                                            .fontWeight(.semibold)
                                        Text(user.email.isEmpty ? "*****@icloud.com" : user.email)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                   
                                }
                            }
                            
                            if let lastActive = userManager.currentUser?.lastActive {
                                Text("Last Active: \(lastActive.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    selectedTab = .manageMessages
                                }) {
                                    Label("Manage Messages", systemImage: "bubble.left.and.bubble.right")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PurpleFilledButton())
                                
                                Button(action: {
                                    selectedTab = .compose
                                }) {
                                    Label("Compose New Message", systemImage: "square.and.pencil")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PurpleFilledButton())
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // MARK: - Backup Email Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Backup Email")
                                .font(.headline)
                            
                            Text("Set a backup email address for emergency access to your messages")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Backup Email")
                                .font(.subheadline)
                                .bold()
                            
                            TextField("Enter backup email", text: $backupEmail)
                                .padding()
                                .background(Color("Primary"))
                                .cornerRadius(8)
                                .font(.subheadline)
                            Text("This email will be used if your account becomes inactive for 12 months.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                // update email
                                updateBackupEmail()
                            }) {
                                Text("Update Backup Email")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PurpleFilledButton())
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
                .background(Color("Primary"))
                .navigationTitle("")
                .navigationBarHidden(true)
               
            }
            if showAlert, let alert = currentAlert {
                  AlertBanner(alert: alert)
                      .padding(.top, 1)
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
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        .onAppear {
            userManager.updateLastActive()
        }
    
        .onAppear {
            if let user = userManager.currentUser {
                backupEmail = user.backupEmail ?? ""
            }
            fetchLatestPhotoURL()
        }
    
        .onAppear {
            requestNotificationPermission()
        }

    }
    
    func updateBackupEmail() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        // ✅ Validate email format
        if backupEmail == "" && !isValidEmail(backupEmail) {
            currentAlert = .error(message: "Please enter a valid backup email.")
            showAlert = true
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "backupEmail": backupEmail
        ]) { error in
            isLoading = false
            if let error = error {
                print("❌ Failed to update backup email:", error.localizedDescription)
                currentAlert = .error(message: "Failed to update backup email: \(error.localizedDescription)")
                showAlert = true
            } else {
                // ✅ Update local user
                if var user = userManager.currentUser {
                    user.backupEmail = backupEmail
                    userManager.saveUser(user)
                }
                print("✅ Backup email updated successfully.")
                currentAlert = .info(message: "Backup email updated successfully.")
                showAlert = true
            }
        }
        
    }
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("🔴 Notification permission error: \(error.localizedDescription)")
            } else {
                print("🔔 Notification permission granted: \(granted)")
            }
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return predicate.evaluate(with: email)
    }
    
    func imageFromBase64(_ base64String: String?) -> Image? {
        guard let base64String = base64String,
              let imageData = Data(base64Encoded: base64String),
              let uiImage = UIImage(data: imageData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    func fetchLatestPhotoURL() {
        Task {
            guard let uid = Auth.auth().currentUser?.uid else {
                return
            }
            let ref = Storage.storage().reference().child("users/\(uid)/images") // e.g. "users/<uid>/images"
            let result = try await ref.listAll()
            print(result.items)
            
            guard let first = result.items.first else {
                return
            }
            do {
                let url = try await first.downloadURL()
                print(url)
                self.loadImage(from: url)
                
                
            } catch {
                print("Fail to download file")
                
            }
            
        }
    }
    
    func loadImage(from url: URL?) {
        SDWebImageManager.shared.loadImage(
            with: url,
            options: .highPriority,
            progress: nil
        ) { image, data, error, cacheType, finished, imageURL in
            if let image = image, finished {
                self.profileImage = image
            }
        }
    }


}

// MARK: - Reusable Purple Button

struct PurpleFilledButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color("Button"))
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
