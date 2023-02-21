//
//  Animation.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 26.01.23.
//

struct Keyframe<Value> {
  var time: Float = 0
  var value: Value
}

class Animation {
  var translationKeyFramePairs: [(previous: Keyframe<float3>, next: Keyframe<float3>)] = []
  var translations: [Keyframe<float3>] = [] {
    didSet {
      translationKeyFramePairs = translations.indices.dropFirst().map {
        (previous: translations[$0 - 1], next: translations[$0])
      }
    }
  }
  var rotationKeyFramePairs: [(previous: Keyframe<simd_quatf>, next: Keyframe<simd_quatf>)] = []
  var rotations: [Keyframe<simd_quatf>] = [] {
    didSet {
      rotationKeyFramePairs = rotations.indices.dropFirst().map {
        (previous: rotations[$0 - 1], next: rotations[$0])
      }
    }
  }
  var scaleKeyFramePairs: [(previous: Keyframe<float3>, next: Keyframe<float3>)] = []
  var scales: [Keyframe<float3>] = [] {
    didSet {
      scaleKeyFramePairs = scales.indices.dropFirst().map {
        (previous: scales[$0 - 1], next: scales[$0])
      }
    }
  }
  var repeatAnimation = true

  func getTranslation(at time: Float) -> float3? {
    guard let lastKeyframe = translations.last else {
      return nil
    }
    var currentTime = time
    if let first = translations.first,
      first.time >= currentTime {
      return first.value
    }
    if currentTime >= lastKeyframe.time,
      !repeatAnimation {
      return lastKeyframe.value
    }
    currentTime = fmod(currentTime, lastKeyframe.time)
    guard let (previousKey, nextKey) = (translationKeyFramePairs.first {
      currentTime < $0.next.time
    }) else {
      return nil
    }
    let interpolant = (currentTime - previousKey.time) / (nextKey.time - previousKey.time)
    return simd_mix(previousKey.value, nextKey.value, float3(repeating: interpolant))
  }

  func getRotation(at time: Float) -> simd_quatf? {
    guard let lastKeyframe = rotations.last else {
      return nil
    }
    var currentTime = time
    if let first = rotations.first,
      first.time >= currentTime {
      return first.value
    }
    if currentTime >= lastKeyframe.time,
      !repeatAnimation {
      return lastKeyframe.value
    }
    currentTime = fmod(currentTime, lastKeyframe.time)

    guard let (previousKey, nextKey) = (rotationKeyFramePairs.first {
      currentTime < $0.next.time
    }) else {
      return nil
    }
    let interpolant = (currentTime - previousKey.time) / (nextKey.time - previousKey.time)
    return simd_slerp(
      previousKey.value,
      nextKey.value,
      interpolant
    )
  }

  func getScale(at time: Float) -> float3? {
    guard let lastKeyframe = scales.last else {
      return nil
    }
    var currentTime = time
    if let first = scales.first,
      first.time >= currentTime {
      return first.value
    }
    if currentTime >= lastKeyframe.time,
      !repeatAnimation {
      return lastKeyframe.value
    }
    currentTime = fmod(currentTime, lastKeyframe.time)
    guard let (previousKey, nextKey) = (scaleKeyFramePairs.first {
      currentTime < $0.next.time
    }) else {
      return nil

    }
    let interpolant = (currentTime - previousKey.time) / (nextKey.time - previousKey.time)
    return simd_mix(
      previousKey.value,
      nextKey.value,
      float3(repeating: interpolant)
    )
  }
}

