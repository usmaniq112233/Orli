import SwiftUI

class MessageStore: ObservableObject {
    @Published var draftMessages: [Message] = [] {
        didSet { save(draftMessages, to: draftsURL) }
    }

    @Published var scheduledMessages: [Message] = [] {
        didSet {
            save(scheduledMessages, to: scheduledURL)
        }
    }


    @Published var sentMessages: [Message] = [] {
        didSet { save(sentMessages, to: sentURL) }
    }

    private let uid: String

    // MARK: - Init

    init(uid: String) {
        self.uid = uid
        draftMessages = load(from: draftsURL)
        scheduledMessages = load(from: scheduledURL)
        sentMessages = load(from: sentURL)
    }

    // MARK: - File URLs (UID-based)

    private var draftsURL: URL {
        fileURL(for: "draftMessages_\(uid).json")
    }

    private var scheduledURL: URL {
        fileURL(for: "scheduledMessages_\(uid).json")
    }

    private var sentURL: URL {
        fileURL(for: "sentMessages_\(uid).json")
    }

    private func fileURL(for filename: String) -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent(filename)
    }

    // MARK: - Generic Save & Load

    private func save(_ messages: [Message], to url: URL) {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: url)
        } catch {
            print("❌ Failed to save messages to \(url.lastPathComponent):", error)
        }
    }

    private func load(from url: URL) -> [Message] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Message].self, from: data)
        } catch {
            print("❌ Failed to load messages from \(url.lastPathComponent):", error)
            return []
        }
    }

    func markAsSent(_ message: Message) {
        if let index = scheduledMessages.firstIndex(where: { $0.id == message.id }) {
            scheduledMessages.remove(at: index)
            var sentMessage = message
            sentMessage.status = .sent
            sentMessages.insert(sentMessage, at: 0)

        }
    }
    

    
    func moveExpiredScheduledMessagesToSent() {
        let now = Date()

        let expiredMessages = scheduledMessages.filter { $0.deliveryDate <= now }

        for message in expiredMessages {
            markAsSent(message)
        }
    }
    
    func deliverImmediately(_ message: Message) {
        if let index = scheduledMessages.firstIndex(where: { $0.id == message.id }) {
            var updatedMessage = message
            updatedMessage.deliveryDate = Date()
            updatedMessage.status = .sent

            // Remove from scheduled and insert into sent
            scheduledMessages.remove(at: index)
            sentMessages.insert(updatedMessage, at: 0)
        }
    }
    
}
