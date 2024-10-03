//
//  ARSessionManager.swift
//  VideoRecorderTest
//
//  Created by Bart Trzynadlowski on 10/2/24.
//

import ARKit
import Combine
import RealityKit
import SwiftUI

class ARSessionManager: ObservableObject {
    static let shared = ARSessionManager()

    var session: ARSession? {
        return arView?.session
    }

    var scene: RealityKit.Scene? {
        return arView?.scene
    }

    fileprivate let frameSubject = CurrentValueSubject<ARFrame?, Never>(nil)
    let frames: AnyPublisher<ARFrame, Never>

    fileprivate weak var arView: ARView?

    fileprivate init() {
        // Allows multiple callers to nextFrame() to share a frame
        self.frames = frameSubject.compactMap { $0 }.share().eraseToAnyPublisher()
    }

    func startSession(preserveAnchors: Bool = false) {
        guard let arView = arView else { return }
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.environmentTexturing = .none
        config.isCollaborationEnabled = false
        arView.session.run(config, options: preserveAnchors ? [] : .removeExistingAnchors)
    }

    func nextFrame() async throws -> ARFrame {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = frames.first()
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(with: .success(value))
                }
        }
    }

    /// SwiftUI coordinator instantiated in the SwiftUI `ARViewContainer` to run the ARKit session.
    class Coordinator: NSObject, ARSessionDelegate {
        private let _parentView: ARViewContainer

        weak var arView: ARView? {
            didSet {
                // Pass view to the session manager so it can modify the session. This is so gross,
                // is there a better way to structure all of this?
                ARSessionManager.shared.arView = arView
            }
        }

        init(_ arViewContainer: ARViewContainer) {
            _parentView = arViewContainer
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            ARSessionManager.shared.frameSubject.send(frame)
        }
    }
}

fileprivate func log(_ message: String) {
    print("[ARSessionManager] \(message)")
}
