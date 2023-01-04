//
//  Tween.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 29.12.22.
//

import QuartzCore

typealias OnUpdateFunc = (_ time: CFAbsoluteTime) -> Void
typealias OnCompleteFunc = () -> Void

class Tween {
  private var startTime: Double = 0
  private var duration: Double
  private var delay: Double
  private var ease: Easing
  private var displayLink: CADisplayLink?
  private var onUpdate: OnUpdateFunc
  private var onComplete: OnCompleteFunc?

  init(
    duration: Double,
    delay: Double,
    ease: Easing,
    onUpdate: @escaping OnUpdateFunc,
    onComplete: OnCompleteFunc? = nil
  ) {
    self.duration = duration
    self.delay = delay
    self.ease = ease
    self.onUpdate = onUpdate
    self.onComplete = onComplete
  }

  func start() {
    func _start () {
      self.startTime = CACurrentMediaTime()
      displayLink = CADisplayLink(target: self, selector: #selector(update))
      displayLink?.add(to: .main, forMode: .default)
    }
    if delay == 0 {
      _start()
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        _start()
      }
    }
  }

  func stop() {
    guard let displayLink = displayLink else {
      return
    }
    displayLink.invalidate()
  }

  @objc private func update(displayLink: CADisplayLink) {
    let now = CACurrentMediaTime()
    var norm = (now - startTime) / duration
    if norm < 0 {
      norm = 0
    } else if norm > 1 {
      norm = 1
    }
    
    let easedTime = ease.apply(time: norm)
    
    onUpdate(easedTime)
    
    if norm >= 1 {
      onComplete?()
      stop()
    }
  }
  
}
