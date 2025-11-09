//
//  AlertView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 24/06/2025.
//

import SwiftUI

struct AlertBanner: View {
    let alert: AlertType

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: alert.icon)
                .foregroundColor(.white)
                .padding(8)
                .background(alert.color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding()
        .background(alert.color.opacity(0.9))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(radius: 4)
    }
}

enum AlertType {
    case error(message: String)
    case warning(message: String)
    case info(message: String)

    var title: String {
        switch self {
        case .error: return "Error"
        case .warning: return "Warning"
        case .info: return "Info"
        }
    }

    var message: String {
        switch self {
        case .error(let msg), .warning(let msg), .info(let msg): return msg
        }
    }

    var icon: String {
        switch self {
        case .error: return "xmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .yellow
        case .info: return .blue
        }
    }
}
