//
//  TestRecorder.swift
//  VideoRecorderTest
//
//  Created by Bart Trzynadlowski on 10/2/24.
//
//  Records camera frames and plays an audio clip every few seconds. A video will be recorded to
//  the phone's photo library. If everything worked correctly, all of the audio clips should be
//  present at the correct times.
//

import Foundation

class TestRecorder {
    private var _videoRecorder: VideoRecorder?

    init() {
        Task {
            await runTask()
        }
    }

    private func runTask() async {
        // Load an MP3 to memory
        guard let clip = try? Data(contentsOf: Bundle.main.url(forResource: "Computer.mp3", withExtension: nil)!) else { return }

        // Start the recording task
        let videoTask = Task {
            await recordVideoTask()
        }

        // Play audio a few times with pauses in between
        for _ in 0..<5 {
            try? await Task.sleep(for: .seconds(4))
            try? await _videoRecorder?.addMP3AudioClip(clip)
            await AudioManager.shared.playSound(fileData: clip)
        }

        // This will finalize the video recording and save it
        videoTask.cancel()
    }

    /// Recording task: samples the ARKit frames at ~20Hz and writes them to video
    private func recordVideoTask() async {
        guard let firstFrame = try? await ARSessionManager.shared.nextFrame() else { return }
        if _videoRecorder == nil {
            let resolution = CGSize(width: firstFrame.capturedImage.width, height: firstFrame.capturedImage.height)
            _videoRecorder = VideoRecorder(outputSize: resolution, frameRate: 20)
        }
        let videoRecorder = _videoRecorder!
        try? await videoRecorder.startRecording()

        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(50))
            guard let frame = try? await ARSessionManager.shared.nextFrame() else { continue }
            if let capturedImage = frame.capturedImage.copy() {
                await videoRecorder.addFrame(capturedImage)
            }
        }

        // Finish and write the file to photo library
        try? await videoRecorder.finishRecording()
    }
}
