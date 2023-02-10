//
//  ViewController.swift
//  PiPBatteryDrain
//
//  Created by Naruki Chigira on 2022/08/13.
//

import AVKit
import CoreMedia
import UIKit

/// FPS
private let frequencyPerSecond: Int = 30

class ViewController: UIViewController {
    @IBOutlet private var layerContainerView: UIView!
    @IBOutlet private var startButton: UIButton! {
        didSet {
            startButton.setImage(AVPictureInPictureController.pictureInPictureButtonStartImage, for: .normal)
        }
    }
    @IBOutlet private var stopButton: UIButton! {
        didSet {
            stopButton.setImage(AVPictureInPictureController.pictureInPictureButtonStopImage, for: .normal)
            stopButton.isEnabled = false
        }
    }
    @IBOutlet private var cpuUsageLabel: UILabel!
    @IBOutlet private var energyDrainSwitch: UISwitch! {
        didSet {
            energyDrainSwitch.addTarget(self, action: #selector(didChangeEnergyDrainValue(_:)), for: .valueChanged)
        }
    }

    private let cpuUsage = CPUUsage()
    private lazy var cpuLabelUpdateTimer: Timer = {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCPUUsageLabel()
        }
        timer.tolerance = 0.01
        return timer
    }()

    private let sampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
    private let sampleBufferFactory = SampleBufferFactory()

    private lazy var looper: Looper = {
        let looper = Looper(frequencyPerSecond: frequencyPerSecond)
        looper.delegate = self
        return looper
    }()

    private lazy var pictureInPictureController: AVPictureInPictureController = {
        let contentSource = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: sampleBufferDisplayLayer, playbackDelegate: self)
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.requiresLinearPlayback = false
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        return controller
    }()

    private var renderer: PiPRenderer = FillRenderer()
    private var presentationTimeStamp: CMTime = .zero
    private var isEnergyDrained = false

    override func viewDidLoad() {
        super.viewDidLoad()
        sampleBufferDisplayLayer.backgroundColor = UIColor.black.cgColor
        layerContainerView.layer.addSublayer(sampleBufferDisplayLayer)
        pictureInPictureController.delegate = self

        _ = cpuLabelUpdateTimer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutSampleBufferDisplayLayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        looper.run()
    }
    
    private func layoutSampleBufferDisplayLayer() {
        sampleBufferDisplayLayer.frame = .init(origin: .zero, size: layerContainerView.frame.size)
    }

    private func render() {
        if sampleBufferDisplayLayer.status == .failed {
            pictureInPictureController.invalidatePlaybackState()
            sampleBufferDisplayLayer.flush()
        }
        
        presentationTimeStamp = CMTimeAdd(presentationTimeStamp, CMTime(value: 1, timescale: CMTimeScale(frequencyPerSecond)))
        let canvasSize = renderer.preferedCanvasSize
        guard let sampleBuffer = sampleBufferFactory.make(
            width: Int(canvasSize.width),
            height: Int(canvasSize.height),
            presentationTimeStamp: presentationTimeStamp,
            refreshRate: frequencyPerSecond
        ) else {
            return
        }
        
        renderer.render(on: sampleBuffer)
        sampleBufferDisplayLayer.enqueue(sampleBuffer)
    }

    @objc
    private func updateCPUUsageLabel() {
        if let currentUsage = cpuUsage.getCurrentUsage() {
            cpuUsageLabel.text = String(format: "%4.1f%%", currentUsage)
        } else {
            cpuUsageLabel.text = "***"
        }
    }

    @objc
    private func didChangeEnergyDrainValue(_ sender: UISwitch) {
        isEnergyDrained = sender.isOn
        pictureInPictureController.invalidatePlaybackState()
    }

    @IBAction private func didTapStartButton(_ sender: UIButton) {
        pictureInPictureController.startPictureInPicture()
    }
    
    @IBAction private func didTapStopButton(_ sender: UIButton) {
        pictureInPictureController.stopPictureInPicture()
    }
}

extension ViewController: LooperDelegate {
    func loop(_ looper: Looper) {
        render()
    }
}

extension ViewController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print(#function)
        startButton.isEnabled = false
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print(#function)
        stopButton.isEnabled = true
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print(#function)
        stopButton.isEnabled = false
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print(#function)
        startButton.isEnabled = true
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print(#function, error)
    }
}

extension ViewController: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        print(#function)
        return CMTimeRange(start: .zero, end: .positiveInfinity)
    }
    
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        print(#function)
        // CPU usage become over 100% when return `false` here.
        return !isEnergyDrained
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        print(#function, playing)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
        print(#function, newRenderSize)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        print(#function)
        completionHandler()
    }
}
