import SwiftUI
import FirebaseAuth
import UserNotifications
import FirebaseFirestore
import FirebaseStorage
import SDWebImage



struct SettingsView: View {
    @AppStorage("areNotificationsEnabled") private var areNotificationsEnabled = true
    @StateObject private var faceIDManager = FaceIDManager()
    @AppStorage("isDarkModeOn") private var isDarkModeOn = false
    @State private var showEditProfile = false
    @State private var name = "John Doe"
    @State private var email = "john.doe@example.com"
    @State private var profileImage: UIImage? = nil
    @State private var showLogin = false
    @StateObject var subscriptionManager = SubscriptionManager()
    @StateObject var userManager = UserManager()
    @State private var emailStatus: String = "Ready to send..."
    @State private var isSending: Bool = false
    @State private var showDeleteAlert = false

    private let sendGridService = SendGridService()

    var body: some View {
        NavigationView {
            Form {
                // MARK: - PROFILE SECTION
                Section(header: Text("Profile")) {
                    Button(action: {
                        // Open sheet cleanly
                        showEditProfile = true
                    }) {
                        HStack(spacing: 16) {
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

                            VStack(alignment: .leading, spacing: 4) {
                                if let user = userManager.currentUser{
                                    Text(user.fullName)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(user.email.isEmpty ? "*****@icloud.com" : user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                // 👇 Subscribed badge
                                SubscribedBadge(isSubscribed: subscriptionManager.purchasedProductIDs.contains("com.orli.premium"))
                                        .padding(.top, 4)
                                
                            }
                        }
                        .contentShape(Rectangle()) // makes full area tappable
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle()) // prevent weird sheet auto-dismiss
                }

     
                Section(header: Text("Product")) {
                    NavigationLink(destination: PaywallView().environmentObject(subscriptionManager)) {
                        HStack {
                            Image(systemName: "dollarsign")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.green)
                                .cornerRadius(6)
                            Text("Subscription")
                        }
                    }
                    
                    NavigationLink(destination: FeaturesView()) {
                        HStack {
                            Image(systemName: "text.book.closed.fill")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.indigo)
                                .cornerRadius(6)
                            Text("Features")
                        }
                    }
                }
                
                // MARK: - GENERAL SETTINGS SECTION
                Section(header: Text("General")) {
                    
                    // Toggle for a boolean setting
                    Toggle(isOn: Binding(
                        get: { faceIDManager.useFaceID },
                        set: { newValue in
                            faceIDManager.toggleFaceID(to: newValue)
                        })) {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.black)
                                .cornerRadius(6)
                            Text("Face ID")
                        }
                    }

                    
                    // Toggle for a boolean setting
                    Toggle(isOn: Binding(
                        get: { isDarkModeOn },
                        set: { newValue in
                            withAnimation {
                                isDarkModeOn = newValue
                            }
                        })) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.black)
                                .cornerRadius(6)
                            Text("Dark Mode")
                        }
                    }

                    
                    Toggle(isOn: Binding(
                        get: { areNotificationsEnabled },
                        set: { newValue in
                            areNotificationsEnabled = newValue
                            if newValue {
                                // 👇 Schedule test notification when enabled
                                requestNotificationPermissionAndSchedule()
                            }
                        })) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.red)
                                .cornerRadius(6)
                            Text("Notifications")
                        }
                    }

                }
                
                // MARK: - ABOUT SECTION
                Section(header: Text("About")) {
                   
                    NavigationLink(destination: WebContainerView(link: "https://future-echo-messages.lovable.app/about")) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color("Button"))
                                .cornerRadius(6)
                            Text("About Us")
                        }
                    }

                    NavigationLink(destination: ContactUsView()) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.green)
                                .cornerRadius(6)
                            Text("Contact Us")
                        }
                    }
                    NavigationLink(destination: WebContainerView(link: "https://future-echo-messages.lovable.app/privacy")) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.red)
                                .cornerRadius(6)
                            Text("Privacy Policy")
                        }
                    }
                    NavigationLink(destination: WebContainerView(link: "https://future-echo-messages.lovable.app/terms")) {
                        HStack {
                            Image(systemName: "list.clipboard")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.orange)
                                .cornerRadius(6)
                            Text("Terms of Use")
                        }
                    }
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.blue)
                            .cornerRadius(6)
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
                
                
                // MARK: - ACTIONS SECTION
                Section {
                    Button(action: {
                        // Handle delete action here
                        showDeleteAlert = true
                    }) {
                        Text("Delete Account")
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Button(action: {
                        // Handle sign out action here
                        logOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                
            }
            .alert(item: $faceIDManager.error) { error in
                Alert(
                    title: Text("Authentication Failed"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
                    .environmentObject(userManager)
            }
            .navigationTitle("Settings") // Sets the title in the navigation bar
            .alert("Are you sure?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. Your account and all associated data will be permanently deleted.")
            }
            .onAppear {
                fetchLatestPhotoURL()
            }

        }
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
        .fullScreenCover(isPresented: $showLogin) {
            NavigationStack {
                LoginView()
            }
        }
    }
       
    func imageFromBase64(_ base64String: String?) -> Image? {
        guard let base64String = base64String,
              let imageData = Data(base64Encoded: base64String),
              let uiImage = UIImage(data: imageData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    func sendEmailAutomatically() async {
          let recipient = "panhwarali11@gmail.com" // Replace with the actual recipient email
          let sender = "orlisupport@proton.me" // Must be your SendGrid verified sender
          let subject = "Automated Test Email from SwiftUI"
          let body = "This is a test email sent automatically from a SwiftUI app without direct user input for the email content. \n\nBest regards, \nYour App"

          do {
              try await sendGridService.sendEmail(
                  to: recipient,
                  toName: "Test Recipient", // Optional name
                  from: sender,
                  fromName: "Your App Name", // Optional name
                  subject: subject,
                  body: body,
                  isHTML: false // Set to true if your body contains HTML
              )
              emailStatus = "Email sent successfully to \(recipient)!"
              print("Successfully sent email to \(recipient)")
          } catch let error as SendGridService.SendEmailError {
              emailStatus = "Error sending email: \(error.localizedDescription)"
              print("Error sending email: \(error.localizedDescription)")
          } catch {
              emailStatus = "An unexpected error occurred: \(error.localizedDescription)"
              print("Unexpected error: \(error.localizedDescription)")
          }
      }
    
    
    func logOut() {
        do {
            try Auth.auth().signOut()
            userManager.clearUser()
            print("User logged out.")
            showLogin = true

        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            print("❌ No user signed in.")
            return
        }

        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.uid)

        // Delete user document from Firestore
        userDocRef.delete { error in
            if let error = error {
                print("❌ Error deleting Firestore user document: \(error.localizedDescription)")
                return
            }

            // Delete Firebase Auth account
            user.delete { authError in
                if let authError = authError {
                    print("❌ Error deleting Firebase Auth user: \(authError.localizedDescription)")
                } else {
                    print("✅ User account deleted successfully.")
                    userManager.clearUser()
                    print("User logged out.")
                    showLogin = true
                }
            }
        }
    }

    
    func requestNotificationPermissionAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if granted {
                print("✅ Notification permission granted")
//                Task{
//                     await sendEmailAutomatically()
//                }
            } else if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification permission not granted.")
            }
        }
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

struct FaceIDError: Identifiable {
    var id: String { message }
    let message: String
}

struct SubscribedBadge: View {
    let isSubscribed: Bool

    var body: some View {
        if isSubscribed {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                    .scaleEffect(1.1)

                Text("Subscribed")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [Color("Button").opacity(0.9), Color("Button").opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("Primary").opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color("Button").opacity(0.3), radius: 6, x: 0, y: 4)
            .transition(.scale)
            .animation(.spring(), value: true)
        }
    }
}
