//
//  UserManager.swift
//  Orli
//
//  Created by mohammad ali panhwar on 28/06/2025.
//

import Foundation

struct LocalUser: Codable {
    let uid: String
    var fullName: String
    let email: String
    var backupEmail: String?
    var profileImageBase64: String?
    var lastActive: Date?   

}


class UserManager: ObservableObject {
    @Published var currentUser: LocalUser?

    private let userDefaultsKey = "localUser"

    init() {
        loadUser()
    }

    func saveUser(_ user: LocalUser) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            currentUser = user
        } catch {
            print("❌ Failed to save user locally:", error)
        }
    }

    func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            let user = try JSONDecoder().decode(LocalUser.self, from: data)
            currentUser = user
        } catch {
            print("❌ Failed to load user from local storage:", error)
        }
    }

    func clearUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        currentUser = nil
    }
    
    func updateLastActive() {
        guard var user = currentUser else { return }
        user.lastActive = Date()
        saveUser(user)
    }

}

