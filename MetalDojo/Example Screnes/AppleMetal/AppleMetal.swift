//
//  AppleMetal.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 19.01.23.
//

// swiftlint:disable identifier_name

import MetalKit
import MetalPerformanceShaders

enum AnimMode {
  case physics, word
}

enum WordAnimMode {
  case word0, word1
}

class AppleMetalScreen: ExampleScreen {
  private static let MESHES_COUNT = APPLE_WORD_POSITIONS.count / 2
  private static let LIGHTS_COUNT = 15

  var options: Options
  var outputTexture: MTLTexture!
  var postFXTexture: MTLTexture!
  var outputDepthTexture: MTLTexture!
  var outputPassDescriptor: MTLRenderPassDescriptor

  private var mode: AnimMode = .word
  private var wordMode: WordAnimMode = .word0
  private let depthStencilState: MTLDepthStencilState?
  private let meshPipelineState: MTLRenderPipelineState
  private let lightPipelineState: MTLRenderPipelineState
  private let updateLightsPipelineState: MTLComputePipelineState
  private let updatePointsPipelineState: MTLComputePipelineState
  private let cameraBuffer: MTLBuffer
  private let instanceBuffer: MTLBuffer
  private let animSettingsBuffer: MTLBuffer
  private let lightsBuffer: MTLBuffer
  private var finalTexture: MTLTexture!

  private var perspCamera = ArcballCamera()
  private var mesh = Cube(size: float3(repeating: 0.005), inwardNormals: false)
  private var lightSphere = Sphere(size: 0.0125)

  private static func makeInstancesBuffer() -> MTLBuffer {
    let instanceBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<AppleMetal_MeshInstance>.stride * Self.MESHES_COUNT,
      options: []
    )!
    let instanceBufferPointer = instanceBuffer
      .contents()
      .bindMemory(to: AppleMetal_MeshInstance.self, capacity: Self.MESHES_COUNT)
    for i in 0 ..< Self.MESHES_COUNT {
      let x = APPLE_WORD_POSITIONS[i * 2 + 0] - 0.5
      let y = APPLE_WORD_POSITIONS[i * 2 + 1] - 0.5
      let idx = i * 2 + 1 > METAL_WORD_POSITIONS.count ? METAL_WORD_POSITIONS.count / 2 - 2 : i
      let x2 = (METAL_WORD_POSITIONS[idx * 2 + 0] ?? 0) - 0.5
      let y2 = (METAL_WORD_POSITIONS[idx * 2 + 1] ?? 0) - 0.5
      instanceBufferPointer[i].position = float3(x, y, 0)
      instanceBufferPointer[i].position1 = float3(x, y, 0)
      instanceBufferPointer[i].position2 = float3(x2, y2, 0)
      instanceBufferPointer[i].prevPosition = float3(x, y, 0)
      instanceBufferPointer[i].velocity = float3.random(in: -2 ..< 2)
      instanceBufferPointer[i].scale = Float.random(in: 0 ..< 1)
      instanceBufferPointer[i].rotateAxis = float3.random(in: 0 ..< 1)
    }
    return instanceBuffer
  }

  init(options: Options) {
    self.options = options
    outputPassDescriptor = MTLRenderPassDescriptor()
    do {
      try meshPipelineState = AppleMetalPipelineStates.createForwardPSO(
        colorPixelFormat: Renderer.viewColorFormat,
        lightsCount: Self.LIGHTS_COUNT
      )
      try lightPipelineState = AppleMetalPipelineStates.createForwardPSO(
        colorPixelFormat: Renderer.viewColorFormat,
        isLight: true
      )
      try updateLightsPipelineState = AppleMetalPipelineStates.createUpdateComputePSO(
        fnName: "appleMetal_updateLights",
        entitiesCount: Self.LIGHTS_COUNT,
        entityRadius: 0.0125 * 0.5,
        checkEntitiesCollisions: true
      )
      try updatePointsPipelineState = AppleMetalPipelineStates.createUpdateComputePSO(
        fnName: "appleMetal_updatePoints",
        entitiesCount: Self.MESHES_COUNT,
        entityRadius: 0.005 * 0.5,
        gravity: float3(0, -0.007, 0),
        bounceFactor: float3(0.8, 0.9, 0.8)
      )
    } catch {
      fatalError(error.localizedDescription)
    }
    depthStencilState = PipelineState.buildDepthStencilState()

    cameraBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<CameraUniforms>.stride,
      options: []
    )!
    instanceBuffer = Self.makeInstancesBuffer()
    animSettingsBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<AppleMetal_AnimSettings>.stride,
      options: []
    )!
    let animSettingsBufferPointer = animSettingsBuffer
      .contents()
      .bindMemory(to: AppleMetal_AnimSettings.self, capacity: 1)

    animSettingsBufferPointer.pointee.mode = 0

    var lights: [Light] = []

    for i in 0 ..< Self.LIGHTS_COUNT {
      var light = Self.buildDefaultLight()
      light.type = Point
      light.color = float3.random(in: 0.2 ..< 1)
      light.attenuation = 0.5
      light.position = float3(
        Float.random(in: -0.5 ..< 0.5),
        Float.random(in: -0.3 ..< 0.3),
        -0.08
      )
      light.prevPosition = light.position
      light.velocity = float3.random(in: -0.5 ..< 0.5)
      lights.append(light)
    }

    lightsBuffer = Self.createLightBuffer(lights: lights)

//    let frustumHeight: Float = 0.65
    let frustumWidth: Float = 0.71875 * 2.5
    let frustumHeight = frustumWidth / perspCamera.aspect
    perspCamera.distance = frustumHeight * 0.5 / tan(perspCamera.fov * 0.5)

    mesh.instanceCount = Self.MESHES_COUNT
    lightSphere.instanceCount = Self.LIGHTS_COUNT

    let instanceBufferPointer = self.instanceBuffer
      .contents()
      .bindMemory(to: AppleMetal_MeshInstance.self, capacity: Self.MESHES_COUNT)
    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
      if self.mode == .physics {
        for i in 0 ..< Self.MESHES_COUNT {
          instanceBufferPointer[i].velocity = float3.random(in: -2 ..< 2)
        }
      }
      if self.mode == .word {
        Tween(
          duration: 0.8,
          delay: 1.2,
          ease: .quadIn,
          onUpdate: { time in
            let tweenFactor = self.wordMode == .word0 ? Float(time) : Float(1 - time)
            animSettingsBufferPointer.pointee.wordMode = tweenFactor

          },
          onComplete: {
            self.wordMode = self.wordMode == .word0 ? .word1 : .word0
          }).start()
      }
      Tween(
        duration: 1.2,
        delay: 0,
        ease: .quadIn,
        onUpdate: { time in
          let tweenFactor = self.mode == .word ? Float(time) : Float(1 - time)
          animSettingsBufferPointer.pointee.mode = tweenFactor
        },
        onComplete: {
          self.mode = self.mode == .word ? .physics : .word
        }).start()
    }
  }

  func resize(view: MTKView) {
    let size = options.drawableSize
    perspCamera.update(size: size)
    postFXTexture = RenderPass.makeTexture(
      size: size,
      pixelFormat: Renderer.viewColorFormat,
      label: "Output Texture",
      usage: [.shaderRead, .shaderWrite]
    )
    outputTexture = Self.createOutputTexture(
      size: size,
      label: "PointsShadowmap output texture"
    )
    outputDepthTexture = Self.createDepthOutputTexture(size: size)
    finalTexture = RenderPass.makeTexture(
      size: size,
      pixelFormat: Renderer.viewColorFormat,
      label: "Final Texture",
      usage: [.shaderRead, .shaderWrite]
    )
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    perspCamera.update(deltaTime: deltaTime)

    let cameraBufferPointer = cameraBuffer
      .contents()
      .bindMemory(to: CameraUniforms.self, capacity: 1)
    cameraBufferPointer.pointee.viewMatrix = perspCamera.viewMatrix
    cameraBufferPointer.pointee.projectionMatrix = perspCamera.projectionMatrix
    cameraBufferPointer.pointee.position = perspCamera.position
    cameraBufferPointer.pointee.time = elapsedTime
  }

  func updateLights(commandBuffer: MTLCommandBuffer) {
    commandBuffer.pushDebugGroup("Compute Light Positions")
    guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
      return
    }
    computeEncoder.setComputePipelineState(updateLightsPipelineState)
    let threadsPerThreadGroup = MTLSizeMake(
      updateLightsPipelineState.threadExecutionWidth,
      1,
      1
    )
    let threadsPerGrid = MTLSizeMake(
      Int(Self.LIGHTS_COUNT),
      1,
      1
    )

    computeEncoder.setBuffer(
      lightsBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    computeEncoder.dispatchThreads(
      threadsPerGrid,
      threadsPerThreadgroup: threadsPerThreadGroup
    )

    computeEncoder.endEncoding()
    commandBuffer.popDebugGroup()
  }

  func updatePoints(commandBuffer: MTLCommandBuffer) {
    commandBuffer.pushDebugGroup("Compute Points Positions")
    guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
      return
    }
    computeEncoder.setComputePipelineState(updatePointsPipelineState)
    let threadsPerThreadGroup = MTLSizeMake(
      updatePointsPipelineState.threadExecutionWidth,
      1,
      1
    )
    let threadsPerGrid = MTLSizeMake(
      Int(Self.MESHES_COUNT),
      1,
      1
    )

    computeEncoder.setBuffer(
      instanceBuffer,
      offset: 0,
      index: InstancesBuffer.index
    )
    computeEncoder.dispatchThreads(
      threadsPerGrid,
      threadsPerThreadgroup: threadsPerThreadGroup
    )

    computeEncoder.endEncoding()
    commandBuffer.popDebugGroup()
  }

  func postProcess(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    guard let drawableTexture = view.currentDrawable?.texture else { return }
    let brightness = MPSImageThresholdToZero(
      device: Renderer.device,
      thresholdValue: 0.2,
      linearGrayColorTransform: nil
    )
    brightness.label = "MPS brightness"
    brightness.encode(
      commandBuffer: commandBuffer,
      sourceTexture: drawableTexture,
      destinationTexture: postFXTexture
    )

    let blur = MPSImageGaussianBlur(
      device: Renderer.device,
      sigma: 120.0
    )
    blur.label = "MPS blur"
    blur.encode(
      commandBuffer: commandBuffer,
      inPlaceTexture: &postFXTexture,
      fallbackCopyAllocator: nil
    )

    let add = MPSImageAdd(device: Renderer.device)
    add.encode(
      commandBuffer: commandBuffer,
      primaryTexture: drawableTexture,
      secondaryTexture: postFXTexture,
      destinationTexture: finalTexture
    )

//    finalTexture = postFXTexture

    guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
      return
    }
    let origin = MTLOrigin(x: 0, y: 0, z: 0)
    let size = MTLSize(
      width: drawableTexture.width,
      height: drawableTexture.height,
      depth: 1
    )
    blitEncoder.copy(
      from: finalTexture,
      sourceSlice: 0,
      sourceLevel: 0,
      sourceOrigin: origin,
      sourceSize: size,
      to: drawableTexture,
      destinationSlice: 0,
      destinationLevel: 0,
      destinationOrigin: origin
    )
    blitEncoder.endEncoding()
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    updateLights(commandBuffer: commandBuffer)
    if mode == .physics {
      updatePoints(commandBuffer: commandBuffer)
    }

//    guard let descriptor = view.currentRenderPassDescriptor,

    let descriptor = outputPassDescriptor
    descriptor.colorAttachments[0].texture = outputTexture
    descriptor.colorAttachments[0].loadAction = .clear
    descriptor.colorAttachments[0].storeAction = .store
    descriptor.depthAttachment.texture = outputDepthTexture
    descriptor.depthAttachment.storeAction = .dontCare

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    renderEncoder.label = "AppleMetal Render Pass"
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(meshPipelineState)

    renderEncoder.setVertexBuffer(
      lightsBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    renderEncoder.setVertexBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setVertexBuffer(
      instanceBuffer,
      offset: 0,
      index: InstancesBuffer.index
    )
    renderEncoder.setVertexBuffer(
      animSettingsBuffer,
      offset: 0,
      index: AnimationSettingsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      lightsBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    mesh.draw(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(lightPipelineState)
    lightSphere.draw(renderEncoder: renderEncoder)

    renderEncoder.endEncoding()

    postProcess(in: view, commandBuffer: commandBuffer)
  }
}
