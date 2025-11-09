//
//  PreviewMessageView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 27/06/2025.
//

import SwiftUI
import AVKit

struct PreviewMessageView: View {
    let message: Message
    let videoURL: String?
    let audioURL: String?
    let textContent: String?
    
    @EnvironmentObject var messageStore: MessageStore
    @Environment(\.presentationMode) var presentationMode

    @State private var showDeleteAlert = false


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("To: \(message.recipient)")
                        .font(.title2).bold()
                    
                    Text("Delivered on \(formattedDate(message.deliveryDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()
                
                // Content Type Badge
                HStack {
                    Label {
                        Text(contentTypeLabel)
                    } icon: {
                        Image(systemName: contentTypeIcon)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color("Button").opacity(0.1))
                    .foregroundColor(Color("Button"))
                    .cornerRadius(8)

                    Spacer()
                }

                // Content Preview
                Group {
                    if let text = textContent {
                        Text(text)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    } else if let videoURL = videoURL {
                        VideoPlayer(player: AVPlayer(url: getVideoURL(from: videoURL)!))
                            .frame(height: 240)
                            .cornerRadius(12)
                    } else if let audioURL = audioURL {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Audio Message")
                                .font(.headline)
                            AudioPlayerView(audioURL: getVideoURL(from: audioURL)!)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    } else {
                        Text("No content available.")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Message", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
                .padding(.top, 32)

            }
            .padding()
        }
        .alert("Delete this message?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteMessage()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .background(Color("Primary").ignoresSafeArea())
        .navigationTitle("Message Preview")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func getVideoURL(from path: String) -> URL? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documents.appendingPathComponent(path)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        } else {
            print("File does not exist at path: \(fileURL.path)")
            return nil
        }
    }

    
    func deleteMessage() {
        switch message.status {
        case .draft:
            messageStore.draftMessages.removeAll { $0.id == message.id }
        case .scheduled:
            messageStore.scheduledMessages.removeAll { $0.id == message.id }
        case .sent:
            messageStore.sentMessages.removeAll { $0.id == message.id }
        }

        presentationMode.wrappedValue.dismiss()
    }


    // Helpers
    var contentTypeLabel: String {
        if videoURL != nil { return "Video Message" }
        if audioURL != nil { return "Audio Message" }
        if textContent != nil { return "Text Message" }
        return "Unknown"
    }

    var contentTypeIcon: String {
        if videoURL != nil { return "video.fill" }
        if audioURL != nil { return "music.note" }
        if textContent != nil { return "text.alignleft" }
        return "questionmark"
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
