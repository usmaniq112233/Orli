//
//  LoaderView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 23/06/2025.
//
import SwiftUI

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            LottieView(animationName: "loader")
                .frame(width: 120, height: 120)
        }
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool) -> some View {
        ZStack {
            self

            if isLoading {
                LoadingOverlay()
            }
        }
    }
}

