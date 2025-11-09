//
//  TabBarView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 18/06/2025.
//
import SwiftUI
import FirebaseAuth

enum Tab: Hashable {
    case profile
    case manageMessages
    case compose
    case settings
    case contacts
}



struct TabBarView: View {
    
    
    @State private var selectedTab: Tab = .profile
    @State private var scrollToMessageID: UUID? = nil // 👈 New state
    @State private var selectedDraft: Message? = nil

    @AppStorage("isDarkModeOn") private var isDarkModeOn = false
    
    @StateObject var messageStore = MessageStore(uid: Auth.auth().currentUser?.uid ?? "guest")
    @StateObject var subscriptionManager = SubscriptionManager()
    @StateObject private var contactsManager = ContactsManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            ProfileView(selectedTab: $selectedTab)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)


            ManageMessagesView(selectedTab: $selectedTab, selectedDraft: $selectedDraft, scrollToMessageID: $scrollToMessageID)
                .environmentObject(messageStore)
                .tabItem { Label("Messages", systemImage: "tray.full") }
                .tag(Tab.manageMessages)

            ComposeMessageView(onDraftUpdated: { updatedDraft in
                scrollToMessageID = updatedDraft.id
                selectedTab = .manageMessages
                selectedDraft = nil // ✅ THIS resets the draft
            }, draft: selectedDraft)
                .environmentObject(messageStore)
                .environmentObject(subscriptionManager)
                .tabItem { Label("Compose", systemImage: "square.and.pencil") }
                .tag(Tab.compose)
            NavigationStack {
                ContactsListView()                // 👈 shows all contacts
            }
            .tabItem { Label("Contacts", systemImage: "person.2") }
            .tag(Tab.contacts)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
            
        }
        .task {
            await contactsManager.loadContacts()
        }
        .environmentObject(contactsManager)
        .accentColor(Color("Button"))
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
    }
}
