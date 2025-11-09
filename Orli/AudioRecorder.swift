//
//  AudioRecorder.swift
//  Orli
//
//  Created by mohammad ali panhwar on 26/06/2025.
//
import SwiftUI
import AVFoundation
import Foundation
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordedURL: URL?
    @Published var levels: [CGFloat] = [] // 🎵 For waveform

    private var audioRecorder: AVAudioRecorder?
    private var meterTimer: Timer?

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let filename = UUID().uuidString + ".m4a"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            recordedURL = nil

            levels = []
            meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                self.audioRecorder?.updateMeters()
                let level = self.normalizedPower(level: self.audioRecorder?.averagePower(forChannel: 0) ?? -160)
                DispatchQueue.main.async {
                    self.levels.append(level)
                    if self.levels.count > 30 {
                        self.levels.removeFirst()
                    }
                }
            }
        } catch {
            print("🎤 Failed to start recording: \(error)")
        }
    }


    func stopRecording() {
        audioRecorder?.stop()
        recordedURL = audioRecorder?.url
        isRecording = false
        meterTimer?.invalidate()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    
    func clearRecording() {
        recordedURL = nil
        levels = []
    }

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func normalizedPower(level: Float) -> CGFloat {
        let minDb: Float = -80
        let clamped = max(min(level, 0), minDb)
        return CGFloat((clamped + abs(minDb)) / abs(minDb))
    }
}

struct LiveWaveformView: View {
    let levels: [CGFloat]

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(levels.indices, id: \.self) { i in
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: max(2, levels[i] * 50))
            }
        }
        .frame(height: 50)
        .animation(.easeOut(duration: 0.05), value: levels)
    }
}
