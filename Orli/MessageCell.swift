//
//  MessageCell.swift
//  Orli
//
//  Created by mohammad ali panhwar on 20/06/2025.
//

import SwiftUI

struct MessageCell: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(message.subject)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

//                Text(message.status.rawValue.capitalized)
//                    .font(.caption)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(message.status.color.opacity(0.2))
//                    .foregroundColor(message.status.color)
//                    .cornerRadius(6)
            }

            Text("To: \(message.recipient)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Label {
                Text(formattedDate(message.deliveryDate))
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)

    }
        

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
