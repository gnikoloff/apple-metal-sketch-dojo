//
//  InputController.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 02.01.23.
//

// swiftlint:disable identifier_name

import GameController
import CoreMotion

class InputController {
  struct Point {
    var x: Float
    var y: Float
    static let zero = Point(x: 0, y: 0)
  }

  static let shared = InputController()
  var keysPressed: Set<GCKeyCode> = []
  var leftMouseDown = false
  var mouseDelta = Point.zero
  var mouseScroll = Point.zero
  var touchLocation = CGPoint()

  var motion: CMMotionManager
  var gyroOffsets: [Float] = [0, 0, 0]

  var touchDelta: CGSize? {
    didSet {
      touchDelta?.height *= -1
      if let delta = touchDelta {
        mouseDelta = Point(x: Float(delta.width), y: Float(delta.height))
      }
      leftMouseDown = touchDelta != nil
    }
  }

  private init() {
    motion = CMMotionManager()
    if motion.isAccelerometerAvailable {
      self.motion.accelerometerUpdateInterval = 1 / 60
      self.motion.startAccelerometerUpdates()
    }
//      if motion.isGyroAvailable {
//        self.motion.gyroUpdateInterval = 1 / 60
//        self.motion.startGyroUpdates()
//      }

    let center = NotificationCenter.default
    center.addObserver(
      forName: .GCKeyboardDidConnect,
      object: nil,
      queue: nil) { notification in
        let keyboard = notification.object as? GCKeyboard
          keyboard?.keyboardInput?.keyChangedHandler
            = { _, _, keyCode, pressed in
          if pressed {
            self.keysPressed.insert(keyCode)
          } else {
            self.keysPressed.remove(keyCode)
          }
        }
    }
    center.addObserver(
      forName: .GCMouseDidConnect,
      object: nil,
      queue: nil) { notification in
        let mouse = notification.object as? GCMouse
        mouse?.mouseInput?.leftButton.pressedChangedHandler = { _, _, pressed in
          self.leftMouseDown = pressed
        }
        mouse?.mouseInput?.scroll.valueChangedHandler = { _, xValue, yValue in
          self.mouseScroll.x = xValue
          self.mouseScroll.y = yValue
        }
    }
#if os(macOS)
  NSEvent.addLocalMonitorForEvents(
    matching: [.keyUp, .keyDown]) { _ in nil }
#endif

  }
}

