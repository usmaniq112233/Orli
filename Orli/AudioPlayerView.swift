//
//  AudioPlayerView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 26/06/2025.
//

import AVFoundation
import SwiftUI

struct AudioPlayerView: View {
    let audioURL: URL
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var delegate: AVAudioDelegateWrapper?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
            }

            Text(audioURL.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
        }
        .onAppear(perform: preparePlayer)
    }

    private func preparePlayer() {
        do {
            player = try AVAudioPlayer(contentsOf: audioURL)
            player?.prepareToPlay()

            let wrapper = AVAudioDelegateWrapper {
                isPlaying = false
            }
            player?.delegate = wrapper
            delegate = wrapper // keep reference alive
        } catch {
            print("Failed to load audio: \(error)")
        }
    }

    private func togglePlayback() {
        guard let player = player else { return }

        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
}

class AVAudioDelegateWrapper: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}
