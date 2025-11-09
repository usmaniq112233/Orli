//
//  ContactsListView.swift
//  Orli
//
//  Created by SMASCO - Usman Javed on 25/08/2025.
//

import SwiftUI
import Contacts

struct ContactsListView: View {
    @EnvironmentObject var contactsManager: ContactsManager
    @State private var searchText = ""

    private var sortedContacts: [PhoneContact] {
        contactsManager.contacts.sorted {
            $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending
        }
    }

    private var filtered: [PhoneContact] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return sortedContacts }
        let q = searchText.lowercased()
        return sortedContacts.filter { c in
            c.fullName.lowercased().contains(q) ||
            c.phoneNumbers.contains(where: { $0.lowercased().contains(q) })
        }
    }

    var body: some View {
        List(filtered) { contact in
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.fullName).font(.headline)
                if let phone = contact.phoneNumbers.first {
                    Text(phone).font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Contacts")
        .searchable(text: $searchText)
    }
}


private struct ContactRow: View {
    let contact: CNContact

    private var name: String {
        let n = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "Unnamed" : n
    }
    private var phone: String? { contact.phoneNumbers.first?.value.stringValue }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(.quaternary)
                Text(initials(from: name)).font(.subheadline.weight(.semibold))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.headline)
                if let phone, !phone.isEmpty {
                    Text(phone).font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "#"
        let second = parts.dropFirst().first?.prefix(1) ?? ""
        return String(first + second).uppercased()
    }
}
