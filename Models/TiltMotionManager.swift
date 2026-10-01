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

    // MARK: - Actions

    enum Action: Equatable {
        case correct
        case skip
    }

    @Published private(set) var lastAction: Action? = nil

    // MARK: - Motion

    private let motion = CMMotionManager()
    private var timer: Timer?

    // MARK: - Orientation

    private enum ScreenOrientation: Equatable {
        case portrait
        case portraitUpsideDown
        case landscapeLeft
        case landscapeRight
    }

    private var currentOrientation: ScreenOrientation?

    // MARK: - Tuning

    /// 25 samples per second.
    private let updateInterval: TimeInterval = 1.0 / 25.0

    /// Forward/backward movement required to fire an action.
    /// ~28 degrees.
    private let triggerThreshold: Double = 0.50

    /// Player must return this close to neutral before another action.
    /// ~10 degrees.
    private let rearmThreshold: Double = 0.18

    /// Reject the motion when the phone is leaning too far sideways.
    private let lateralLimit: Double = 0.40

    /// The device should be reasonably upright before calibration.
    private let minimumUprightComponent: Double = 0.45

    /// Number of initial samples used to establish the natural
    /// neutral holding position.
    private let calibrationSampleCount = 8

    /// Small protection against extremely fast accidental duplicates.
    private let minimumFireInterval: TimeInterval = 0.25

    // MARK: - Direction Mapping

    /*
     These preserve the intended mapping from your previous manager.

     If TestFlight testing shows that forward/backward is now correct
     but Correct and Skip are reversed, ONLY swap these two values.
     */

    private let positiveTiltAction: Action = .skip
    private let negativeTiltAction: Action = .correct

    // MARK: - Runtime State

    private var neutralAngle: Double = 0

    private var calibrationTotal: Double = 0
    private var calibrationSamples: Int = 0
    private var isCalibrated = false

    private var isArmed = false

    private var lastFireTime: Date = .distantPast

    // MARK: - Start

    func start() {
        guard motion.isDeviceMotionAvailable else {
            return
        }

        // Avoid creating multiple sampling timers.
        if motion.isDeviceMotionActive {
            return
        }

        resetRuntimeState()

        motion.deviceMotionUpdateInterval = updateInterval
        motion.startDeviceMotionUpdates()

        stopTimerOnly()

        timer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in

            guard let self else {
                return
            }

            self.sample()
        }
    }

    // MARK: - Stop

    func stop() {
        stopTimerOnly()

        motion.stopDeviceMotionUpdates()

        lastAction = nil

        resetRuntimeState()
    }

    private func stopTimerOnly() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Sampling

    private func sample() {
        guard let data = motion.deviceMotion else {
            return
        }

        let gravity = data.gravity

        /*
         Instead of using attitude.pitch directly, we determine
         which direction is currently "up" on the screen.

         That allows the same forward/backward gesture to work in:

         Portrait
         Portrait upside-down
         Landscape left
         Landscape right
         */

        let detectedOrientation =
            orientationFromGravity(
                x: gravity.x,
                y: gravity.y
            )

        guard let detectedOrientation else {
            return
        }

        // If the player rotates the phone from portrait to landscape
        // or vice versa, recalibrate for the new orientation.
        if currentOrientation != detectedOrientation {

            currentOrientation =
                detectedOrientation

            resetCalibration()

            return
        }

        let components =
            motionComponents(
                orientation: detectedOrientation,
                gravityX: gravity.x,
                gravityY: gravity.y
            )

        let downComponent =
            components.down

        let lateralComponent =
            components.lateral

        // Ignore positions where the phone is almost flat.
        guard downComponent >= minimumUprightComponent else {
            return
        }

        /*
         gravity.z tells us how far the screen is tilting
         toward/away from the player.

         downComponent supplies the orientation-aware vertical
         reference.

         Together these give us forward/backward tilt regardless
         of whether the phone is portrait or landscape.
         */

        let rawAngle =
            atan2(
                gravity.z,
                downComponent
            )

        // MARK: Calibration

        if !isCalibrated {

            // Do not calibrate while the player is leaning
            // strongly left or right.
            guard abs(lateralComponent) < lateralLimit else {
                return
            }

            calibrationTotal += rawAngle
            calibrationSamples += 1

            if calibrationSamples >= calibrationSampleCount {

                neutralAngle =
                    calibrationTotal
                    / Double(calibrationSamples)

                isCalibrated = true

                /*
                 We start disarmed.

                 The player must first be reasonably close to
                 neutral before the first tilt can trigger.
                 */
                isArmed = false
            }

            return
        }

        // Difference from the player's calibrated neutral position.
        let tiltAngle =
            normalizeAngle(
                rawAngle - neutralAngle
            )

        // MARK: Re-arm

        /*
         This is important.

         Once Correct/Skip fires, another event cannot occur until
         the player brings the phone back near neutral.

         That prevents:

         Correct
         Correct
         Correct

         simply because the player held the phone tilted.
         */

        if !isArmed {

            if abs(tiltAngle) <= rearmThreshold &&
                abs(lateralComponent) <= lateralLimit {

                isArmed = true
            }

            return
        }

        // MARK: Reject Sideways Tilts

        /*
         QA specifically found that sideways movement was behaving
         like forward/backward movement.

         If the sideways gravity component is too large, ignore it.
         */

        guard abs(lateralComponent) <= lateralLimit else {
            return
        }

        // MARK: Cooldown

        let now = Date()

        guard
            now.timeIntervalSince(lastFireTime)
                >= minimumFireInterval
        else {
            return
        }

        // MARK: Forward / Backward Detection

        if tiltAngle >= triggerThreshold {

            fire(
                positiveTiltAction
            )

        } else if tiltAngle <= -triggerThreshold {

            fire(
                negativeTiltAction
            )
        }
    }

    // MARK: - Orientation Detection

    private func orientationFromGravity(
        x: Double,
        y: Double
    ) -> ScreenOrientation? {

        let absX = abs(x)
        let absY = abs(y)

        /*
         When the phone is basically face-up/face-down,
         X and Y are both too small to reliably determine
         screen orientation.
         */

        guard max(absX, absY) >= minimumUprightComponent else {
            return nil
        }

        if absY >= absX {

            if y < 0 {
                return .portrait
            } else {
                return .portraitUpsideDown
            }

        } else {

            if x < 0 {
                return .landscapeLeft
            } else {
                return .landscapeRight
            }
        }
    }

    // MARK: - Orientation-Aware Components

    private func motionComponents(
        orientation: ScreenOrientation,
        gravityX: Double,
        gravityY: Double
    ) -> (
        down: Double,
        lateral: Double
    ) {

        switch orientation {

        case .portrait:

            return (
                down: -gravityY,
                lateral: gravityX
            )

        case .portraitUpsideDown:

            return (
                down: gravityY,
                lateral: -gravityX
            )

        case .landscapeLeft:

            return (
                down: -gravityX,
                lateral: -gravityY
            )

        case .landscapeRight:

            return (
                down: gravityX,
                lateral: gravityY
            )
        }
    }

    // MARK: - Fire

    private func fire(
        _ action: Action
    ) {

        guard isArmed else {
            return
        }

        lastFireTime = Date()

        // Require return-to-neutral before another event.
        isArmed = false

        lastAction = action

        /*
         Clearing this allows GameplayView's .onChange
         to recognize the same action again later.
         */
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.05
        ) { [weak self] in

            self?.lastAction = nil
        }
    }

    // MARK: - Calibration

    private func resetCalibration() {
        neutralAngle = 0

        calibrationTotal = 0
        calibrationSamples = 0

        isCalibrated = false
        isArmed = false
    }

    private func resetRuntimeState() {
        currentOrientation = nil

        neutralAngle = 0

        calibrationTotal = 0
        calibrationSamples = 0

        isCalibrated = false
        isArmed = false

        lastFireTime = .distantPast
    }

    // MARK: - Angle Helper

    private func normalizeAngle(
        _ angle: Double
    ) -> Double {

        var result = angle

        while result > .pi {
            result -= 2 * .pi
        }

        while result < -.pi {
            result += 2 * .pi
        }

        return result
    }
}
