//
//  FillRenderer.swift
//  PiPBatteryDrain
//
//  Created by Naruki Chigira on 2022/08/13.
//

import CoreGraphics
import CoreMedia
import UIKit

/// Fill sample buffer with single color.
class FillRenderer: PiPRenderer {
    private let gradationInterval: Int = 150
    private var count: Int = 0
    
    init() {
    }
    
    var preferedCanvasSize: CGSize {
        .init(width: 160, height: 90)
    }
    
    func render(on sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let pixelBuffer = imageBuffer as CVPixelBuffer

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }

        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: data,
            width: Int(preferedCanvasSize.width),
            height: Int(preferedCanvasSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return
        }

        count += 1
        let hue = CGFloat(count % gradationInterval) / CGFloat(gradationInterval)
        let color = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1).cgColor
        context.setFillColor(color)
        context.fill(.init(origin: .zero, size: preferedCanvasSize))
    }
}
