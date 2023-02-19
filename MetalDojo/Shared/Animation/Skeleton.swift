//
//  Skeleton.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 26.01.23.
//

import MetalKit

class Skeleton {
  let parentIndices: [Int?]
  let jointPaths: [String]
  let bindTransforms: [float4x4]
  let restTransforms: [float4x4]
  let jointMatrixPaletteBuffer: MTLBuffer?

  static func getParentIndices(jointPaths: [String]) -> [Int?] {
    var parentIndices = [Int?](repeating: nil, count: jointPaths.count)
    for (jointIndex, jointPath) in jointPaths.enumerated() {
      let url = URL(fileURLWithPath: jointPath)
      let parentPath = url.deletingLastPathComponent().relativePath
      parentIndices[jointIndex] = jointPaths.firstIndex {
        $0 == parentPath
      }
    }
    return parentIndices
  }

  init?(animationBindComponent: MDLAnimationBindComponent?) {
    guard let skeleton = animationBindComponent?.skeleton else {
      return nil
    }
    jointPaths = skeleton.jointPaths
    bindTransforms = skeleton.jointBindTransforms.float4x4Array
    restTransforms = skeleton.jointRestTransforms.float4x4Array
    parentIndices = Skeleton.getParentIndices(
      jointPaths: jointPaths
    )

    let bufferSize = jointPaths.count * MemoryLayout<float4x4>.stride
    print("bufferSize \(bufferSize)")
    jointMatrixPaletteBuffer =
      Renderer.device.makeBuffer(
        length: bufferSize,
        options: [])
  }

  func updatePose(
    animationClip: AnimationClip?,
    at time: Float
  ) {
    guard let paletteBuffer = jointMatrixPaletteBuffer
      else { return }
    var palettePointer = paletteBuffer.contents().bindMemory(
      to: float4x4.self,
      capacity: jointPaths.count)
    guard let animationClip = animationClip else {
      palettePointer.initialize(
        repeating: .identity,
        count: jointPaths.count)
      return
    }
    var poses =
      [float4x4](repeatElement(.identity, count: jointPaths.count))
    for (jointIndex, jointPath) in jointPaths.enumerated() {
      // 1
      let pose = animationClip.getPose(
        at: time * animationClip.speed,
        jointPath: jointPath) ?? restTransforms[jointIndex]
      // 2
      let parentPose: float4x4
      if let parentIndex = parentIndices[jointIndex] {
        parentPose = poses[parentIndex]
      } else {
        parentPose = .identity
      }
      poses[jointIndex] = parentPose * pose
      palettePointer.pointee =
        poses[jointIndex] * bindTransforms[jointIndex].inverse
      palettePointer = palettePointer.advanced(by: 1)
    }
  }
}
