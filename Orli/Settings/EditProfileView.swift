//
//  EditProfileView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 23/06/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import SDWebImage


struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userManager: UserManager

    @State private var showAlert = false
    @State private var isLoading = false
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem?
    @State private var progress: Double = 0
    @State private var profilePicUrl: URL?
    @State private var currentAlert: AlertType?

    
    private let storage = Storage.storage()

    var body: some View {
        ZStack(alignment: .top) {
            NavigationView {
                Form {
                    // Profile Image Section
                    Section(header: Text("Profile Image")) {
                        VStack {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: 100, height: 100)
                            } else if let image = imageFromBase64(userManager.currentUser?.profileImageBase64) {
                                image
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: 100, height: 100)
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }

                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Text("Change Photo")
                            }
                            .onChange(of: selectedItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        profileImage = uiImage
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // Name & Email Section
                    Section(header: Text("Personal Info")) {
                        TextField("Name", text: $name)
                        TextField("Email", text: $email)
                            .disabled(true)
                            .foregroundColor(.gray)
                    }
                    
                }
                .navigationTitle("Edit Profile")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            saveProfile()
                        }
                    }

                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    if let user = userManager.currentUser {
                        name = user.fullName
                        email = user.email.isEmpty ? "*****@icloud.com" : user.email
                    }
                    fetchLatestPhotoURL()
                }
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
        
    }

    func saveProfile() {
        guard let uiImage = profileImage,
              let data = uiImage.jpegData(compressionQuality: 0.9),
              let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        progress = 0

        // If you want live progress, use the task API:
        let path = "users/\(uid)/images/\(uid).jpg"
        let ref = storage.reference(withPath: path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let task = ref.putData(data, metadata: metadata)

        task.observe(.progress) {snapshot in
            guard let total = snapshot.progress?.totalUnitCount,
                  let done = snapshot.progress?.completedUnitCount,
                  total > 0 else { return }
            self.progress = Double(done) / Double(total)
            print(self.progress)
        }

        task.observe(.success) { _ in
            Task { @MainActor in
                do {
                    let url = try await ref.downloadURL()
                    self.loadImage(from: url)
                } catch {
                    currentAlert = .error(message: "Unable to update profile. Try again later.")
                    showAlert = true
                }
                self.isLoading = false
            }
        }

        task.observe(.failure) { snapshot in
            self.isLoading = false
            currentAlert = .error(message: "Profile update faild. \(snapshot.error?.localizedDescription ?? "")")
            showAlert = true
            print("Upload failed:", snapshot.error?.localizedDescription ?? "")
        }
    }
    
    func fetchLatestPhotoURL() {
        Task {
            guard let uid = Auth.auth().currentUser?.uid else {
                return
            }
            let ref = Storage.storage().reference().child("users/\(uid)/images") // e.g. "users/<uid>/images"
            let result = try await ref.listAll()
            
            guard let first = result.items.first else {
                return
            }
            do {
                let url = try await first.downloadURL()
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
    
    func imageFromBase64(_ base64String: String?) -> Image? {
        guard let base64String = base64String,
              let data = Data(base64Encoded: base64String),
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}
