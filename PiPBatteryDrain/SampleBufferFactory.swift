//
//  SampleBufferFactory.swift
//  PiPBatteryDrain
//
//  Created by Naruki Chigira on 2022/08/13.
//

import CoreMedia

class SampleBufferFactory {
    private var pixelBufferPoolDictionary: [String: CVPixelBufferPool] = [:]

    func make(width: Int, height: Int, presentationTimeStamp: CMTime, refreshRate: Int) -> CMSampleBuffer? {
        let pixelBufferPoolKey = makePixelBufferPoolDictionaryKey(width: width, height: height)

        if pixelBufferPoolDictionary[pixelBufferPoolKey] == nil, let pixelBufferPool = makePixelBufferPool(width: width, height: height) {
            pixelBufferPoolDictionary[pixelBufferPoolKey] = pixelBufferPool
        }
        guard let pixelBufferPool = pixelBufferPoolDictionary[pixelBufferPoolKey] else {
            print("Failed to get pixelBufferPool.")
            return nil
        }
        
        /// Create CVPixelBuffer
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
        guard let pixelBuffer = pixelBuffer else {
            print("Failed to create pixelBuffer.")
            return nil
        }

        /// Create CMSampleBuffer
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
        guard let formatDescription = formatDescription else {
            print("Failed to create CMFormatDescription.")
            return nil
        }

        var sampleTiming = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: CMTimeScale(refreshRate)),
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: presentationTimeStamp
        )
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &sampleTiming,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }

    private func makePixelBufferPoolDictionaryKey(width: Int, height: Int) -> String {
        "\(width),\(height)"
    }
    
    /// Create CVPixelBufferPool
    private func makePixelBufferPool(width: Int, height: Int) -> CVPixelBufferPool? {
        let attributes = [
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferBytesPerRowAlignmentKey as String: width * 4,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ] as CFDictionary
        var pixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(nil, nil, attributes, &pixelBufferPool)
        return pixelBufferPool
    }
}
