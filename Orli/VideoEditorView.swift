//
//  VideoEditorView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 26/06/2025.
//

import UIKit
import SwiftUI

struct VideoEditorView: UIViewControllerRepresentable {
    var videoURL: URL
    var onTrimmed: (URL) -> Void

    func makeUIViewController(context: Context) -> some UIViewController {
        let editor = UIVideoEditorController()
        editor.videoPath = videoURL.path
        editor.delegate = context.coordinator
        return editor
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onTrimmed: onTrimmed)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIVideoEditorControllerDelegate {
        var onTrimmed: (URL) -> Void

        init(onTrimmed: @escaping (URL) -> Void) {
            self.onTrimmed = onTrimmed
        }

        func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
            onTrimmed(URL(fileURLWithPath: editedVideoPath))
            editor.dismiss(animated: true)
        }

        func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
            editor.dismiss(animated: true)
        }

        func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
            print("Trimming failed: \(error)")
            editor.dismiss(animated: true)
        }
    }

}
