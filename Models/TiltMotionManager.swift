//
//  TiltMotionManager.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-14.
//

import Foundation
import Combine
import CoreMotion

@MainActor
final class TiltMotionManager: ObservableObject {

    enum Action: Equatable {
        case correct
        case skip
    }

    @Published private(set) var lastAction: Action? = nil

    private let motion = CMMotionManager()
    private var timer: Timer? = nil

    // Tune these if needed
    private let updateInterval: TimeInterval = 1.0 / 25.0   // 25Hz sampling
    private let cooldownSeconds: TimeInterval = 0.9         // prevents repeats
    private let pitchThreshold: Double = 0.70               // radians (~40°)

    private var lastFireTime: Date = .distantPast

    func start() {
        guard motion.isDeviceMotionAvailable else {
            // Simulator usually hits this
            return
        }

        motion.deviceMotionUpdateInterval = updateInterval
        motion.startDeviceMotionUpdates()

        stopTimerOnly()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.sample()
        }
    }

    func stop() {
        stopTimerOnly()
        motion.stopDeviceMotionUpdates()
        lastAction = nil
    }

    private func stopTimerOnly() {
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        guard let data = motion.deviceMotion else { return }

        // Pitch: forward/back tilt (we use it as up/down)
        let pitch = data.attitude.pitch

        // Cooldown gate
        let now = Date()
        if now.timeIntervalSince(lastFireTime) < cooldownSeconds {
            return
        }

        // Tilt up (screen toward user) / Tilt down (screen away)
        // You may want to swap these depending on feel; easy change below.
        if pitch > pitchThreshold {
            fire(.skip)      // DOWN
        } else if pitch < -pitchThreshold {
            fire(.correct)   // UP
        }
    }

    private func fire(_ action: Action) {
        lastFireTime = Date()
        lastAction = action

        // Clear quickly so .onChange can trigger again later
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.lastAction = nil
        }
    }
}
