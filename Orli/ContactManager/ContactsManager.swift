//
//  ContactManager.swift
//  Orli
//
//  Created by SMASCO - Usman Javed on 22/08/2025.
//

//import Foundation
//import Contacts
//import UIKit
//
//struct PhoneContact: Identifiable, Hashable {
//    let id: String
//    let givenName: String
//    let familyName: String
//    let fullName: String
//    let phoneNumbers: [String]
//    let emails: [String]
//}

import Foundation
import Contacts
import UIKit

public struct PhoneContact: Identifiable, Hashable {
    public let id: String
    public let givenName: String
    public let familyName: String
    public let fullName: String
    public let phoneNumbers: [String]
    public let emails: [String]
}

@MainActor
public final class ContactsManager: ObservableObject {
    @Published public private(set) var contacts: [PhoneContact] = []
    @Published public private(set) var authorizationStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)

    private let store = CNContactStore()

    public init() {}

    // MARK: - Authorization

    public func refreshAuthorizationStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    /// Standard request access flow (system may offer "All" vs "Some contacts" on iOS 18+).
    private func requestAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Bool, Error>) in
            store.requestAccess(for: .contacts) { granted, error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Loading

    /// Loads contacts respecting the current authorization level.
    /// - Note: On iOS 18+ with `.limited`, this returns only the subset the user allowed.
    public func loadContacts() async {
        refreshAuthorizationStatus()

        switch authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await requestAccess()
                authorizationStatus = granted ? .authorized : .denied
                if granted {
                    await fetchContacts()
                } else {
                    openAppSettings()
                }
            } catch {
                authorizationStatus = .denied
                openAppSettings()
            }
        case .authorized:
            await fetchContacts()

        case .limited: // iOS 18+
            await fetchContacts() // returns only the allowed subset

        case .denied, .restricted:
            // Consider showing UI to explain and offer Settings
            break

        @unknown default:
            break
        }
    }

    // MARK: - Fetch

    public func fetchContacts() async {
        let fetched: [PhoneContact] = await Task.detached { [store] in
            let keys: [CNKeyDescriptor] = [
                CNContactIdentifierKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor
            ]
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .givenName

            var items: [PhoneContact] = []
            do {
                try store.enumerateContacts(with: request) { c, _ in
                    let phones = c.phoneNumbers
                        .map { $0.value.stringValue }
                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

                    let emails = c.emailAddresses
                        .map { String($0.value) }
                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

                    let full = [c.givenName, c.familyName]
                        .joined(separator: " ")
                        .trimmingCharacters(in: .whitespaces)

                    items.append(PhoneContact(
                        id: c.identifier,
                        givenName: c.givenName,
                        familyName: c.familyName,
                        fullName: full.isEmpty ? "Unnamed" : full,
                        phoneNumbers: phones,
                        emails: emails
                    ))
                }
            } catch {
                // Log as needed
            }

            // de-dupe & sort
            return Array(Set(items))
                .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
        }.value

        contacts = fetched
    }

    // MARK: - Settings

    public func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}


/**
@MainActor
final class ContactsManager: ObservableObject {
    @Published private(set) var contacts: [PhoneContact] = []
    @Published private(set) var authorizationStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    private let store = CNContactStore()

    func loadContacts() async {
        // Check/request permission first
        let status = CNContactStore.authorizationStatus(for: .contacts)
        authorizationStatus = status

        switch status {
        case .notDetermined:
            do {
                let granted = try await requestAccess()
                authorizationStatus = granted ? .authorized : .denied
                if granted {
                    await fetchContacts()
                } else {
                    openAppSettings()
                }
            } catch {
                authorizationStatus = .denied
                openAppSettings()
            }
        case .authorized:
            await fetchContacts()
        case .denied, .restricted:
            // Nothing to do; you can show UI to guide user to Settings
            break
        case .limited:
            break
        @unknown default:
            break
        }
    }

    private func requestAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { cont in
            store.requestAccess(for: .contacts) { granted, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: granted) }
            }
        }
    }

    private func fetchContacts() async {
        // Run heavy fetch off the main thread
        let fetched: [PhoneContact] = await Task.detached { [store] in
            let keys: [CNKeyDescriptor] = [
                CNContactIdentifierKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor
            ]

            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .givenName

            var items: [PhoneContact] = []
            do {
                try store.enumerateContacts(with: request) { c, _ in
                    let phones = c.phoneNumbers
                        .map { $0.value.stringValue }
                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

                    let emails = c.emailAddresses
                        .map { String($0.value) }
                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

                    let full = [c.givenName, c.familyName]
                        .joined(separator: " ")
                        .trimmingCharacters(in: .whitespaces)

                    items.append(PhoneContact(
                        id: c.identifier,
                        givenName: c.givenName,
                        familyName: c.familyName,
                        fullName: full.isEmpty ? "Unnamed" : full,
                        phoneNumbers: phones,
                        emails: emails
                    ))
                }
            } catch {
                // swallow for now; you can add logging if you like
            }

            // Example: unique + sorted
            let unique = Array(Set(items))
                .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }

            return unique
        }.value

        // Publish on main actor
        contacts = fetched
        print(fetched)
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
**/
