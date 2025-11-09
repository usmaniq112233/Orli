//
//  AudioRecordingView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 25/06/2025.
//

import SwiftUI

struct AudioWaveformView: View {
    @State private var amplitudes: [CGFloat] = Array(repeating: 0.5, count: 20)
    @State private var timer: Timer?

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<amplitudes.count, id: \.self) { index in
                Capsule()
                    .fill(Color.blue)
                    .frame(width: 4, height: 20 + amplitudes[index] * 80)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(radius: 5)
        )
        .onAppear {
            startFakeRecordingAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    func startFakeRecordingAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                amplitudes = amplitudes.map { _ in CGFloat.random(in: 0.1...1.0) }
            }
        }
    }
}


struct AudioRecordingView: View {
    @State private var isRecording = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Recording...")
                .font(.headline)

            if isRecording {
                AudioWaveformView()
            }

            Button(action: {
                isRecording.toggle()
            }) {
                Label(isRecording ? "Stop Recording" : "Start Recording", systemImage: "mic.fill")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isRecording ? Color.red : Color("Button"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}
