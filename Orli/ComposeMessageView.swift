import SwiftUI
import PhotosUI
import AVKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct ComposeMessageView: View {
    
    @EnvironmentObject var messageStore: MessageStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @StateObject private var audioRecorder = AudioRecorder()

    @State private var recipientName = ""
    @State private var subject = ""
    @State private var messageContent = ""
    @State private var recipientEmail: String = ""
    @State private var selectedMethod: DeliveryMethod = .inAppStorage
    @State private var deliveryTime = "Immediate delivery"
    @State private var showPromptSheet = false
    @State private var showVideoCamera = false
    @State private var recordedVideoURL: URL?
    @State private var recordedAudioURL: URL?
    @State private var showAlert = false
    @State private var currentAlert: AlertType?
    @State private var inputMode: InputMode = .text
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showVideoTrimmer = false
    @State private var showScheduleSheet = false
    @State private var showPaywall = false
    @State private var selectedDeliveryDate: Date? = nil
    @State private var repeatOption: String = "None"
    @State private var selectedTimeZone: TimeZone = .current
    @State private var pendingInputMode: InputMode? = nil
    @State private var showSwitchAlert: Bool = false
    @State private var isLoading = false
    
    @State private var contentType: String = ""
    @State private var contentText: String = ""
    @State private var mediaFilePath: String = ""
    @State private var uploadProgress: Double = 0.0
    @State private var isUploading: Bool = false


    var onDraftUpdated: ((Message) -> Void)? = nil
    var draft: Message? = nil
    
    var isEditingDraft: Bool {
        draft != nil
    }
    var isEmailValid: Bool {
        recipientEmail.contains("@") && recipientEmail.contains(".")
    }
    func hasExistingInput() -> Bool {
        switch inputMode {
        case .text:
            return !messageContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .photo:
            return recordedVideoURL != nil || !selectedItems.isEmpty
        case .audio:
            return recordedAudioURL != nil
        }
    }
    var isFormValid: Bool {
        let hasRecipient = !recipientName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasSubject = !subject.trimmingCharacters(in: .whitespaces).isEmpty
        let hasContent = !messageContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         recordedVideoURL != nil ||
                         recordedAudioURL != nil
        let isEmailValid = selectedMethod == .email ? !recipientEmail.trimmingCharacters(in: .whitespaces).isEmpty : true

        return hasRecipient && hasSubject && hasContent && isEmailValid
    }





    var body: some View {
        
        ZStack(alignment: .top){
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Compose a Message")
                            .font(.title2).bold()
                        Text("Create a message to be delivered in the future")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Recipient
                    InputSection(title: "Recipient Name") {
                        TextField("Recipient's name", text: $recipientName)
                            .inputStyle()
                    }
                    
                    // Delivery Method
                    InputSection(title: "Delivery Method") {
                        HStack(spacing: 10) {
                            ForEach(DeliveryMethod.allCases) { method in
                                let isLocked = (method == .email && !subscriptionManager.purchasedProductIDs.contains("com.orli.premium"))

                                Button {
                                    if !isLocked {
                                        selectedMethod = method
                                    } else {
                                        showPaywall = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: isLocked ? "lock.fill" : method.icon)
                                        Text(method.rawValue)
                                            .font(.caption)
                                            .bold()
                                            
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedMethod == method && !isLocked ? Color("Button") : Color(.systemGray6))
                                    .foregroundColor(
                                          isLocked
                                              ? .gray
                                          : (selectedMethod == method ? .white : .primary)
                                      )
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    if selectedMethod == .email {
                        InputSection(title: "Recipient Email") {
                            TextField("Enter email address", text: $recipientEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .inputStyle()
                        }
                    }

                    
                    // Subject
                    InputSection(title: "Subject") {
                        TextField("Message subject", text: $subject)
                            .inputStyle()
                    }
                    
                    // Input Mode Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Message Input")
                            .font(.subheadline).bold()
                        
                        HStack(spacing: 10) {
                            ForEach(InputMode.allCases, id: \.self) { mode in
                                let isLocked = (mode != .text && !subscriptionManager.purchasedProductIDs.contains("com.orli.premium"))

                                Button {
                                    if !isLocked {
                                        if inputMode != mode {
                                            if hasExistingInput() {
                                                pendingInputMode = mode
                                                showSwitchAlert = true
                                            } else {
                                                inputMode = mode
                                            }
                                        }
                                    } else {
                                       showPaywall = true
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: isLocked ? "lock.fill" : mode.iconName)
                                        Text(mode.label)
                                            .font(.caption)
                                            .bold()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(inputMode == mode && !isLocked ? Color("Button") : Color(.systemGray6))
                                    .foregroundColor(
                                          isLocked
                                              ? .gray
                                          : (inputMode == mode ? .white : .primary)
                                      )
                                    .cornerRadius(10)
                                }
                            }
                        }

                        .frame(maxWidth: .infinity)
                    }
                    
                    // Dynamic Input Area
                    Group {
                        switch inputMode {
                        case .text:
                            VStack(spacing: 16) {
                                      // Show lock or card based on subscription
                                      if subscriptionManager.purchasedProductIDs.contains("com.orli.premium") {
                                          // ✅ Unlocked: Show Inspiration Card
                                          Button(action: {
                                              showPromptSheet = true
                                          }) {
                                              HStack(spacing: 12) {
                                                  Image(systemName: "lightbulb.fill")
                                                      .foregroundColor(.yellow)
                                                      .imageScale(.large)
                                                  VStack(alignment: .leading, spacing: 2) {
                                                      Text("Need Inspiration?")
                                                          .font(.subheadline)
                                                          .fontWeight(.semibold)
                                                      Text("Choose a storytelling prompt")
                                                          .font(.caption)
                                                          .foregroundColor(.secondary)
                                                  }
                                                  Spacer()
                                              }
                                              .padding()
                                              .background(Color(UIColor.secondarySystemBackground))
                                              .cornerRadius(12)
                                          }
                                      } else {
                                          // 🔒 Locked for free users
                                          Button(action: {
                                              showPaywall = true
                                          }) {
                                              HStack(spacing: 12) {
                                                  Image(systemName: "lock.fill")
                                                      .foregroundColor(.gray)
                                                  VStack(alignment: .leading, spacing: 2) {
                                                      Text("Need Inspiration?")
                                                          .font(.subheadline)
                                                          .fontWeight(.semibold)
                                                      Text("Unlock Premium to access writing prompts")
                                                          .font(.caption)
                                                          .foregroundColor(.secondary)
                                                  }
                                                  Spacer()
                                              }
                                          }
                                          .padding()
                                          .background(Color(.systemGray6))
                                          .cornerRadius(12)
                                          .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                                      }

                                      // Text input field
                                ZStack {
                                    // Placeholder in center
                                    if messageContent.isEmpty {
                                        Text("Write your message here...")
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                            .transition(.opacity)
                                    }

                                    // TextEditor behind the placeholder
                                    TextEditor(text: $messageContent)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .frame(minHeight: 140)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(10)
                                        .opacity(messageContent.isEmpty ? 0.85 : 1.0) // optional: slight fade-in effect
                                }

                                .frame(minHeight: 120)

                                  }
                            
                        case .photo:
                            VStack(spacing: 16) {
                                Text("Record a video messege")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Upload from Gallery
//                                PhotosPicker(
//                                    selection: $selectedItems,
//                                    matching: .any(of: [.videos]),
//                                    photoLibrary: .shared()
//                                ) {
//                                    Label("Select from Gallery", systemImage: "photo.on.rectangle")
//                                        .frame(maxWidth: .infinity)
//                                        .padding()
//                                        .background(Color("Button"))
//                                        .foregroundColor(.white)
//                                        .cornerRadius(10)
//                                }
                                
                                // Record from Camera
                                Button {
                                    showVideoCamera = true
                                } label: {
                                    Label("Record Video", systemImage: "video.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color("Button"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            // Show video preview below
                            if let url = recordedVideoURL {
                                VStack(spacing: 12) {
                                    Text("Recorded Video")
                                        .font(.subheadline)

                                    VideoPlayer(player: AVPlayer(url: url))
                                        .frame(height: 200)
                                        .cornerRadius(12)
                                        

                                    Button("Trim Video") {
                                        showVideoTrimmer = true
                                    }
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            

                            
                        case .audio:
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Record an audio message")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    if audioRecorder.isRecording {
                                        LiveWaveformView(levels: audioRecorder.levels)
                                    }
                                }

                                Button(action: {
                                    audioRecorder.toggleRecording()
                                }) {
                                    Label(audioRecorder.isRecording ? "Stop Recording" : "Start Recording", systemImage: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(audioRecorder.isRecording ? Color.red : Color("Button"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                if let url = audioRecorder.recordedURL {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Recorded Audio")
                                            .font(.subheadline)
                                        AudioPlayerView(audioURL: url)
                                    }
                                    .onAppear {
                                        recordedAudioURL = url
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)

                        }
                    }
                    
                    // Scheduled Delivery
                    InputSection(title: "Scheduled Delivery") {
                        Button(action: {
                            showScheduleSheet = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text(selectedDeliveryDate != nil
                                     ? DateFormatter.localizedString(from: selectedDeliveryDate!, dateStyle: .medium, timeStyle: .short)
                                     : "Choose delivery date")
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }

                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(isEditingDraft ? "Update Draft" : "Save Draft") {
                            let newDraft = Message(
                                  id: draft?.id ?? UUID(), // reuse ID if updating
                                  subject: subject,
                                  recipient: recipientName,
                                  recipientEmail: recipientEmail,
                                  status: .draft,
                                  deliveryDate: Date(),
                                  contentType: "contentType",
                                  contentText: "contentText",
                                  mediaFilePath: "mediaFilePath"
                              )
                            
                            
                            if let index = messageStore.draftMessages.firstIndex(where: { $0.id == newDraft.id }) {
                                  messageStore.draftMessages[index] = newDraft // update
                              } else {
                                  messageStore.draftMessages.append(newDraft) // new
                              }
                            currentAlert = .info(message: isEditingDraft ? "Draft updated!" : "Draft saved!")
                            showAlert = true
                            onDraftUpdated?(newDraft) // 👈 Trigger callback
                            resetFields()
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(Color("Text"))
                        .cornerRadius(12)
                        
                        Button("Schedule Message") {
                            
                            let isSubscribed = subscriptionManager.purchasedProductIDs.contains("com.orli.premium")
                            let totalMessages = messageStore.draftMessages.count + messageStore.scheduledMessages.count

                             if !isSubscribed && totalMessages >= 5 {
                                 currentAlert = .error(message: "Free users can only save up to 5 messages. Upgrade to Premium to continue.")
                                 showAlert = true
                                 return
                             }

                            // your schedule action
                            if isFormValid {
                                isLoading = true
                                isUploading = true
                                uploadProgress = 0.0
                                
                                if inputMode == .text {
                                    contentType = "text"
                                    contentText = messageContent
                                } else if inputMode == .audio, let audioURL = recordedAudioURL {
                                    contentType = "audio"
                                    if let savedPath = saveMediaToDocuments(audioURL) {
                                        mediaFilePath = savedPath
                                    }
                                } else if inputMode == .photo, let videoURL = recordedVideoURL {
                                    contentType = "video"
                                    if let savedPath = saveMediaToDocuments(videoURL) {
                                        mediaFilePath = savedPath
                                    }
                                }
                                
                                let newMessage = Message(
                                    id: UUID(),
                                    subject: subject,
                                    recipient: recipientName,
                                    recipientEmail: recipientEmail,
                                    status: .scheduled,
                                    deliveryDate: selectedDeliveryDate!,
                                    contentType: contentType,
                                    contentText: messageContent,
                                    mediaFilePath: mediaFilePath
                                )
                                
                                // Save locally
                               
                                
                                // Save to Firestore
                                let db = Firestore.firestore()
                                let messageData: [String: Any] = [
                                    "id": newMessage.id.uuidString,
                                    "subject": newMessage.subject,
                                    "recipient": newMessage.recipient,
                                    "recipientEmail": newMessage.recipientEmail,
                                    "status": newMessage.status.rawValue,
                                    "deliveryDate": Timestamp(date: newMessage.deliveryDate),
                                    "contentType": contentType,
                                    "contentText": contentText,
                                    "mediaFilePath": mediaFilePath,
                                    "createdAt": Timestamp(date: Date())
                                ]
                                
                            

                                // Optional: Add under user collection
                                if let uid = Auth.auth().currentUser?.uid {
                                    
                                  
                                    db.collection("users").document(uid).collection("scheduledMessages").document(newMessage.id.uuidString).setData(messageData) { error in
                                        if let error = error {
                                            currentAlert = .error(message: "Failed to save message: \(error.localizedDescription)")
                                            showAlert = true
                                            isLoading = false
                                        } else {
                                            if contentType == "video" || contentType == "audio" {
                                                print("ali" + mediaFilePath)
                                                let fileURL = FileManager.default
                                                    .urls(for: .documentDirectory, in: .userDomainMask)[0]
                                                    .appendingPathComponent(mediaFilePath)
                                                
                                                uploadMediaToFirebase(pathString: fileURL.path) { progress in
                                                    uploadProgress = progress
                                                } completion: { result in
                                                    isUploading = false
                                                    switch result {
                                                    case .success(let url):
                                                        // ✅ Save public URL to Firestore
                                                        db.collection("users")
                                                            .document(uid)
                                                            .collection("scheduledMessages")
                                                            .document(newMessage.id.uuidString)
                                                            .updateData(["mediaFilePath": url.absoluteString]) { updateError in
                                                                print("ali" + url.absoluteString)
                                                                if let updateError = updateError {
                                                                    print("⚠️ Failed to update mediaFilePath: \(updateError.localizedDescription)")
                                                                } else {
                                                                    print("📡 mediaFilePath updated successfully")
                                                                    print("✅ Message saved successfully to Firestore")
                                                                    messageStore.scheduledMessages.append(newMessage)
                                                                    onDraftUpdated?(newMessage)
                                                                    resetFields()
                                                                    isLoading = false
                                                                    uploadProgress = 0.0
                                                                }
                                                            }
                                                        
                                                    case .failure(let error):
                                                        currentAlert = .error(message: "Upload failed: \(error.localizedDescription)")
                                                        showAlert = true
                                                    }
                                                }
                                            } else {
                                                print("✅ Message saved successfully to Firestore")
                                                messageStore.scheduledMessages.append(newMessage)
                                                onDraftUpdated?(newMessage)
                                                resetFields()
                                                isLoading = false
                                                isUploading = true
                                                uploadProgress = 0.0
                                            }
                                        }
                                    }

                                   
                                } else {
                                    currentAlert = .error(message: "User not authenticated.")
                                    showAlert = true
                                    isLoading = false
                                }

                            } else {
                                currentAlert = .error(message: "Please add message content text, audio, or video before scheduling.")
                                showAlert = true
                                isLoading = false
                            }


                        }
                        .disabled(selectedDeliveryDate == nil)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(selectedDeliveryDate == nil ? Color.gray : Color("Button"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
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
                    
                    VStack(spacing: 16) {
                        LottieView(animationName: "loader")
                            .frame(width: 150, height: 150)
                        
                        // 🔢 Upload Percentage
                        Text("Uploading... \(Int(uploadProgress * 100))%")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }

        }
        .alert("Switch Input Type?", isPresented: $showSwitchAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive) {
                clearCurrentInput()
                if let newMode = pendingInputMode {
                    inputMode = newMode
                }
            }
        } message: {
            Text("Switching input type will remove your current \(inputMode.label.lowercased()) content. Do you want to continue?")
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        .background(Color("Primary").ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showPromptSheet) {
            PromptSelectorView { selectedPrompt in
                if inputMode == .text {
                    messageContent = selectedPrompt.preset
                }
                showPromptSheet = false
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleMessageView(
                isSubscribed: subscriptionManager.purchasedProductIDs.contains("com.orli.premium"),
                selectedDate: $selectedDeliveryDate,
                repeatOption: $repeatOption,
                selectedTimeZone: $selectedTimeZone
            )
        }
        .fullScreenCover(isPresented: $showVideoCamera) {
            VideoCameraView(videoURL: $recordedVideoURL)
        }
        .onAppear {
            if let draft = draft {
                recipientName = draft.recipient
                subject = draft.subject
                messageContent = draft.contentText // Load full content if needed
                selectedDeliveryDate = draft.deliveryDate
            }
        }
        .sheet(isPresented: $showVideoTrimmer) {
            if let url = recordedVideoURL {
                VideoEditorView(videoURL: url) { trimmedURL in
                    recordedVideoURL = trimmedURL
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onChange(of: selectedItems) {
            guard let item = selectedItems.first else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString + ".mov")
                    do {
                        try data.write(to: tempURL)
                        recordedAudioURL = tempURL
                    } catch {
                        print("Failed to write video: \(error)")
                    }
                }
            }
        }
    }
    
    func saveMediaToDocuments(_ originalURL: URL) -> String? {
        let fileName = UUID().uuidString + "." + originalURL.pathExtension
        let destination = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        do {
            try FileManager.default.copyItem(at: originalURL, to: destination)
            return fileName
        } catch {
            print("Error saving media:", error)
            return nil
        }
    }
    
    func uploadMediaToFirebase(
        pathString: String,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let fileURL = URL(fileURLWithPath: pathString) // Convert to URL
        let storageRef = Storage.storage().reference()
        let fileName = UUID().uuidString + "." + fileURL.pathExtension
        let mediaRef = storageRef.child("media/\(fileName)")

        let uploadTask = mediaRef.putFile(from: fileURL, metadata: nil)

        uploadTask.observe(.progress) { snapshot in
            let percent = Double(snapshot.progress?.fractionCompleted ?? 0)
            progressHandler(percent)
        }

        uploadTask.observe(.success) { _ in
            mediaRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }

        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                completion(.failure(error))
            }
        }
    }
    
    



    
    func clearCurrentInput() {
        messageContent = ""
        recordedVideoURL = nil
        selectedItems = []
        
        if recordedAudioURL != nil{
            audioRecorder.clearRecording()
            recordedAudioURL = nil // Optional if not used elsewhere
        }
    }

     func resetFields() {
        recipientName = ""
        subject = ""
        messageContent = ""
        selectedMethod = .inAppStorage
        deliveryTime = "Immediate delivery"
        selectedItems = []
        recordedVideoURL = nil
        inputMode = .text
        selectedDeliveryDate = nil
    }

    
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}

struct Prompt: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
    let preset: String
}

let samplePrompts: [Prompt] = [
    Prompt(emoji: "❤️", title: "For Someone You Love", description: "Record a message for a future anniversary or a loved one’s wedding day.", preset: "Dear [Name], I wanted to tell you this on a special day..."),
    Prompt(emoji: "🧠", title: "For Your Future Self", description: "Remind yourself why you started or what you hope never to forget.", preset: "Hey Future Me, remember when you..."),
    Prompt(emoji: "🌱", title: "Life Lessons", description: "What’s something you’ve learned the hard way?", preset: "Here’s something I wish someone told me..."),
    Prompt(emoji: "🕊️", title: "If I’m Not Around…", description: "Leave guidance, comfort, or important information in case of death or absence.", preset: "If you're hearing this, it means I'm not there, and I want you to know..."),
    Prompt(emoji: "🎉", title: "Milestones I Don’t Want to Miss", description: "For birthdays, graduations, weddings, or other important moments when you may not be there.", preset: "Happy [Occasion]! Even though I can't be there, I want to say...")
]


// MARK: - PromptSelectorView
struct PromptSelectorView: View {
    let onSelect: (Prompt) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(samplePrompts) { prompt in
                        Button(action: {
                            onSelect(prompt)
                        }) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(prompt.emoji).font(.largeTitle)
                                    Text(prompt.title)
                                        .font(.headline)
                                }
                                Text(prompt.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Storytelling Prompts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


// MARK: - Reusable Section View
struct InputSection<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline).bold()
            content()
        }
    }
}

enum DeliveryMethod: String, CaseIterable, Identifiable {
    case email = "Email Delivery"
    case inAppStorage = "In-App Storage"

    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .email: return "envelope"
        case .inAppStorage: return "bubble.left.and.bubble.right"
        }
    }
}

enum InputMode: CaseIterable {
    case text, photo, audio

    var iconName: String {
        switch self {
        case .text: return "text.bubble"
        case .photo: return "video.bubble"
        case .audio: return "music.microphone"
        }
    }

    var label: String {
        switch self {
        case .text: return "Text"
        case .photo: return "Video"
        case .audio: return "Audio"
        }
    }
}




// MARK: - Text Field Style Modifier
extension View {
    func inputStyle() -> some View {
        self
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .font(.subheadline)
    }
}


