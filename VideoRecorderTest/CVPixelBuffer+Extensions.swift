//
//  CVPixelBuffer+Extensions.swift
//  VideoRecorderTest
//
//  Created by Bart Trzynadlowski on 10/2/24.
//

import CoreVideo

extension CVPixelBuffer {
    var width: Int {
        return CVPixelBufferGetWidth(self)
    }

    var height: Int {
        return CVPixelBufferGetHeight(self)
    }

    var bytesPerRow: Int {
        return CVPixelBufferGetBytesPerRow(self)
    }

    var format: OSType {
        return CVPixelBufferGetPixelFormatType(self)
    }

    func copy() -> CVPixelBuffer? {
        // Create a new pixel buffer
        var newPixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferIOSurfacePropertiesKey: [:]  // no specific IOSurface properties
        ] as CFDictionary

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            self.width,
            self.height,
            self.format,
            attributes,
            &newPixelBuffer
        )

        guard status == kCVReturnSuccess, let newBuffer = newPixelBuffer else {
            return nil
        }

        // Copy pixel data
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        CVPixelBufferLockBaseAddress(newBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let originalBaseAddress = CVPixelBufferGetBaseAddress(self)
        let newBaseAddress = CVPixelBufferGetBaseAddress(newBuffer)
        let originalBytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let newBytesPerRow = CVPixelBufferGetBytesPerRow(newBuffer)
        for row in 0..<height {
            let src = originalBaseAddress!.advanced(by: row * originalBytesPerRow)
            let dst = newBaseAddress!.advanced(by: row * newBytesPerRow)
            memcpy(dst, src, min(originalBytesPerRow, newBytesPerRow))
        }
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        CVPixelBufferUnlockBaseAddress(newBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return newBuffer
    }
}
