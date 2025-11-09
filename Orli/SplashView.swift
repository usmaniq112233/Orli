//
//  SplashView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 18/06/2025.
//

import SwiftUI
import LocalAuthentication
import FirebaseAuth
import UserNotifications


struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @StateObject private var faceIDManager = FaceIDManager()
    var isUserLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }

    var body: some View {
        
            if isActive {
                if hasSeenOnboarding {
                    TabBarView()
                } else {
                    if isUserLoggedIn {
                        TabBarView()
                          
                    } else {
                        NavigationStack {
                            LoginView()
                        }
                    }
                   
                }
            } else {
                VStack {
                    Image("Logo")
                        .resizable()
                        .frame(width: 300, height: 300)
                        .foregroundColor(.blue)
                }
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.5)) {
                        self.opacity = 1.0
                    }
                    // Navigate to main view after 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.isActive = true
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("Primary"))
                .onAppear {
                    faceIDManager.authenticateIfNeeded()
                }
            }
        
            
       
        
   
    }
      

}

struct MainView: View {
    var body: some View {
        Text("Main App View")
            .font(.largeTitle)
    }
}
