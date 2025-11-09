import SwiftUI


enum MessageStatus: String, Codable {
    case scheduled, sent, draft
}



struct Message: Identifiable, Codable {
    var id = UUID()
    let subject: String
    let recipient: String
    let recipientEmail: String
    var status: MessageStatus
    var deliveryDate: Date

    let contentType: String
    let contentText: String       // for text messages
    let mediaFilePath: String     // for video/audio stored locally
}


enum MessageTab: String, CaseIterable {
    case scheduled = "Scheduled"
    case sent = "Sent"
    case drafts = "Drafts"
}

struct ManageMessagesView: View {
    @EnvironmentObject var messageStore: MessageStore
    @Binding var selectedTab: Tab
    @Binding var selectedDraft: Message?
    @Binding var scrollToMessageID: UUID?
    
    @State private var actionSheetMessage: Message?
    @State private var showActionSheet: Bool = false
    @State private var selectedMessages: MessageTab = .scheduled
    @State private var previewMessage: Message? = nil

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Manage your scheduled, sent, and draft messages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedMessages) {
                    ForEach(MessageTab.allCases, id: \.self) { tab in
                        Text("\(tab.rawValue) (\(messageCount(for: tab)))")
                    }
                }
                .pickerStyle(.segmented)

                // Swipeable Tabs
                TabView(selection: $selectedMessages) {
                    ForEach(MessageTab.allCases, id: \.self) { tab in
                        messageListView(for: tab)
                            .tag(tab)
                            .padding(.top, 8)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding()
            .navigationTitle("Your Messages")
            .background(Color("Primary"))
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Message Options"),
                buttons: [
//                    .default(Text("Edit Message")) {
//                        if let message = actionSheetMessage {
//                            selectedDraft = message
//                            selectedTab = .compose
//                        }
//                    },
                    .default(Text("Deliver Immediately")) {
                        if let message = actionSheetMessage {
                            deliverImmediately(message)
                        }
                    },
                    .destructive(Text("Delete")) {
                        if let message = actionSheetMessage {
                            deleteMessageDirectly(message)
                        }
                    },
                    .cancel()
                ]
            )
        }
        .onAppear {
            messageStore.moveExpiredScheduledMessagesToSent()
        }
        .sheet(item: $previewMessage) { message in
            PreviewMessageView(
                message: message,
                videoURL: message.contentType == "video" ? message.mediaFilePath : nil,
                audioURL: message.contentType == "audio" ? message.mediaFilePath : nil,
                textContent: message.contentType == "text" ? message.contentText : nil
            )
        }


    }
    
    func deleteMediaFile(for message: Message) {
        guard !message.mediaFilePath.isEmpty else { return }
        let fileURL = URL(fileURLWithPath: message.mediaFilePath)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    
    func deleteMessageDirectly(_ message: Message) {
        switch message.status {
        case .scheduled:
            messageStore.scheduledMessages.removeAll { $0.id == message.id }
        case .sent:
            messageStore.sentMessages.removeAll { $0.id == message.id }
        case .draft:
            messageStore.draftMessages.removeAll { $0.id == message.id }
        }
    }

    func deliverImmediately(_ message: Message) {
        // Simulate immediate delivery
        if let index = messageStore.scheduledMessages.firstIndex(where: { $0.id == message.id }) {
            messageStore.scheduledMessages.remove(at: index)
            var sentMessage = message
            sentMessage.status = .sent
            messageStore.sentMessages.insert(sentMessage, at: 0)
        }
    }


    // MARK: - Message List View

    func messageListView(for tab: MessageTab) -> some View {
        let messages = messages(for: tab)

        return Group {
            if messages.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: iconName(for: tab))
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No \(tab.rawValue.lowercased()) messages yet. Create your first message to get started!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(messages) { message in
                        Button {
                            if tab == .sent {
                                previewMessage = message

                            }else{
                                  actionSheetMessage = message
                                  showActionSheet = true
                              }
                        } label: {
                            MessageCell(message: message)
                                .scaleEffect(message.id == scrollToMessageID ? 1.03 : 1.0)
                                .animation(.easeInOut(duration: 0.25), value: scrollToMessageID)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 4)
                        .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
    }

    // MARK: - Helpers

    func messages(for tab: MessageTab) -> [Message] {
        switch tab {
        case .scheduled: return messageStore.scheduledMessages
        case .sent: return messageStore.sentMessages
        case .drafts: return messageStore.draftMessages
        }
    }

    func messageCount(for tab: MessageTab) -> Int {
        messages(for: tab).count
    }

    func iconName(for tab: MessageTab) -> String {
        switch tab {
        case .scheduled: return "calendar"
        case .sent: return "paperplane"
        case .drafts: return "doc.plaintext"
        }
    }

    func deleteMessages(at offsets: IndexSet, in tab: MessageTab) {
        switch tab {
        case .scheduled:
            messageStore.scheduledMessages.remove(atOffsets: offsets)
        case .sent:
            messageStore.sentMessages.remove(atOffsets: offsets)
        case .drafts:
            messageStore.draftMessages.remove(atOffsets: offsets)
        }
    }
}



