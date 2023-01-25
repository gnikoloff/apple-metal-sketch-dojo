//
//  InfiniteSpace.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 05.01.23.
//

// swiftlint:disable identifier_name
// swiftlint:disable type_body_length

import MetalKit

final class InfiniteSpace: ExampleScreen {
  private static let POINT_LIGHTS_COUNT: Int = 100
  private static let BOXES_COUNT: Int = 3000
  private static let BOX_SEGMENTS_COUNT = 10
  private static let WORLD_SIZE: float3 = [3.75, 3.75, 40]

  var outputTexture: MTLTexture!
  var outputDepthTexture: MTLTexture!
  var outputPassDescriptor: MTLRenderPassDescriptor

  private var perspCamera = PerspectiveCamera()
  private var perspCameraUniforms = CameraUniforms()
  private var boidsSettings = InfiniteSpace_BoidsSettings()
  private var deferredSettings = InfiniteSpace_DeferredSettings()

  private var gBufferPSO: MTLRenderPipelineState
  private var sunLightPSO: MTLRenderPipelineState
  private let pointLightPSO: MTLRenderPipelineState
  private let depthStencilState: MTLDepthStencilState
  private let lightingDepthStencilState: MTLDepthStencilState?
  private let computeBoxesPipelineState: MTLComputePipelineState
  private let computePointLightsPipelineState: MTLComputePipelineState

  private var cameraBuffer: MTLBuffer
  private var sunLightBuffer: MTLBuffer
  private var pointLightBuffer: MTLBuffer
  private let controlPointsBuffer: MTLBuffer
  private let cubesMaterialsBuffer: MTLBuffer

  private var normalShininessBaseColorTexture: MTLTexture!
  private var positionSpecularColorTexture: MTLTexture!

  var options: Options
  private var cube: Cube
  private var pointLightSphere: Sphere

  private static func createCameraBuffer() -> MTLBuffer {
    return Renderer.device.makeBuffer(
      length: MemoryLayout<CameraUniforms>.stride,
      options: []
    )!
  }

  private static func createCubesMaterialsBuffer() -> MTLBuffer {
    let materialsBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<Material>.stride * Self.BOXES_COUNT,
      options: []
    )!
    let bufferPointer = materialsBuffer
      .contents()
      .bindMemory(to: Material.self, capacity: Self.BOXES_COUNT)
    for i in 0 ..< Self.BOXES_COUNT {
      bufferPointer[i].shininess = Float.random(in: 0..<1)
      bufferPointer[i].baseColor = float3(Float.random(in: 0..<0.3), 0, 0)
      bufferPointer[i].specularColor = float3(Float.random(in: 0..<0.4), 0, 0)
    }
    return materialsBuffer
  }

  private static func createSunLightsBuffer() -> MTLBuffer {
    var lights: [Light] = []
    var sunLight0 = Self.buildDefaultLight()
    sunLight0.position = [100, -100, 100]
    sunLight0.color = float3(repeating: 0.7)
    lights.append(sunLight0)
    var sunLight1 = Self.buildDefaultLight()
    sunLight1.position = [-100, 100, -50]
    sunLight1.color = float3(repeating: 0.8)
    lights.append(sunLight1)
    return Self.createLightBuffer(lights: lights)
  }

  private static func createPointLightsBuffer() -> MTLBuffer {
//    let worldX = Self.WORLD_SIZE[0]
//    let worldY = Self.WORLD_SIZE[1]
    var pointLights: [Light] = []
    for i in 0 ..< InfiniteSpace.POINT_LIGHTS_COUNT {
      var light = Self.buildDefaultLight()
      light.type = Point
      light.color = float3.random(in: 0..<1)
      light.position = float3(
//        Float.random(in: -worldX..<worldX) * 2,
//        Float.random(in: -worldY..<worldY) * 2,
        cos(Float(i)) * Float.random(in: 0 ..< WORLD_SIZE[0]) + 1,
        sin(Float(i)) * Float.random(in: 0 ..< WORLD_SIZE[1]) + 1,
        Float.random(in: 0 ..< WORLD_SIZE[2])
      )
      light.attenuation = [0.1, 1, 8]
      light.speed = Float.random(in: 0.02 ..< 0.1)
      pointLights.append(light)
    }
    return Self.createLightBuffer(lights: pointLights)
  }

  private static func createBoxesControlPointsBuffer() -> MTLBuffer {
    // create boxes initial data
    let controlPointsCount = Self.BOX_SEGMENTS_COUNT * Self.BOXES_COUNT
    let controlPointsBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<InfiniteSpace_ControlPoint>.stride * controlPointsCount
    )!
    let bufferPointer = controlPointsBuffer
      .contents()
      .bindMemory(to: InfiniteSpace_ControlPoint.self, capacity: controlPointsCount)
    for i in 0 ..< Self.BOXES_COUNT {
      let randZ = Float.random(
        in: 0 ..< Self.WORLD_SIZE[2]
      )
      let moveRadiusX = Float.random(in: 0 ..< WORLD_SIZE[0] * 1.2) + 1
      let moveRadiusY = Float.random(in: 0 ..< WORLD_SIZE[1] * 1.2) + 1
      for n in 0 ..< Self.BOX_SEGMENTS_COUNT {
        let controlPointIdx = i * Self.BOX_SEGMENTS_COUNT + n
        let randMoveRadX = Float.random(in: 0.5 ..< 1) * moveRadiusX
        let randMoveRadY = Float.random(in: 0.5 ..< 1) * moveRadiusY
        if n == 0 {
          let position = float3(
            cos(randZ * 0.1 + Float(controlPointIdx)) * randMoveRadX,
            sin(randZ * 0.1 + Float(controlPointIdx)) * randMoveRadY,
            randZ - 0.5
          )
          bufferPointer[controlPointIdx].position = position
        } else {
          let localSpaceZ = Float(n) / Float(Self.BOX_SEGMENTS_COUNT)
          let prevPoint = bufferPointer[controlPointIdx - 1]
          let position = float3(
            prevPoint.position.x + cos(randZ * 0.1 + Float(controlPointIdx)) * 0.1,
            prevPoint.position.y + sin(randZ * 0.1 + Float(controlPointIdx)) * 0.1,
            prevPoint.position.z + localSpaceZ
          )
          bufferPointer[controlPointIdx].position = position
        }
        bufferPointer[controlPointIdx].moveRadius[0] = randMoveRadX
        bufferPointer[controlPointIdx].moveRadius[1] = randMoveRadY
        bufferPointer[controlPointIdx].zVelocityHead = Float.random(in: 0 ..< 0.01) + 0.01
        bufferPointer[controlPointIdx].zVelocityTail = Float.random(in: 0 ..< 0.06) + 0.06
      }
    }
    return controlPointsBuffer
  }

  init(options: Options) {
    self.options = options
    outputPassDescriptor = MTLRenderPassDescriptor()
    do {
      try computeBoxesPipelineState = InfiniteSpacePipelineStates.createBoxesComputePSO()
      try computePointLightsPipelineState = InfiniteSpacePipelineStates.createPointLightsComputePSO()
    } catch {
      fatalError(error.localizedDescription)
    }
    gBufferPSO = InfiniteSpacePipelineStates.createGBufferPSO(colorPixelFormat: Renderer.viewColorFormat)
    sunLightPSO = InfiniteSpacePipelineStates.createSunLightPSO(colorPixelFormat: Renderer.viewColorFormat)
    pointLightPSO = InfiniteSpacePipelineStates.createPointLightPSO(colorPixelFormat: Renderer.viewColorFormat)

    depthStencilState = PipelineState.buildDepthStencilState()!
    lightingDepthStencilState = InfiniteSpacePipelineStates.buildLightingDepthStencilState()

    perspCamera.target.y = 0.1
    perspCamera.target.z = 30
    perspCamera.position.y = 0.2
//    perspCamera.position.x = 1
//    perspCamera.position.z = -2

    cube = Cube(
      size: [0.075, 0.075, 1],
      segments: [1, 1, UInt32(Self.BOX_SEGMENTS_COUNT)],
      inwardNormals: true
    )
    pointLightSphere = Sphere(size: 1)

    cameraBuffer = Self.createCameraBuffer()
    cubesMaterialsBuffer = Self.createCubesMaterialsBuffer()
    controlPointsBuffer = Self.createBoxesControlPointsBuffer()
    sunLightBuffer = Self.createSunLightsBuffer()
    pointLightBuffer = Self.createPointLightsBuffer()

    boidsSettings.boxSegmentsCount = UInt32(Self.BOX_SEGMENTS_COUNT)
    boidsSettings.worldSize = Self.WORLD_SIZE

    deferredSettings.cameraProjectionInverse = perspCamera.projectionMatrix.inverse
    deferredSettings.cameraViewInverse = perspCamera.viewMatrix.inverse
  }

  func resize(view: MTKView) {
    let size = options.drawableSize
    deferredSettings.viewportSize = SIMD2<UInt32>(UInt32(size.width), UInt32(size.height))
    normalShininessBaseColorTexture = RenderPass.makeTexture(
      size: size,
      pixelFormat: .rgba16Float,
      label: "G-Buffer Normal + Shininess + Color Base Texture",
      storageMode: .memoryless
    )
    positionSpecularColorTexture = RenderPass.makeTexture(
      size: size,
      pixelFormat: .rgba16Float,
      label: "G-Buffer Position + Specular Color Base Texture",
      storageMode: .memoryless
    )
    outputDepthTexture = RenderPass.makeTexture(
      size: size,
      pixelFormat: .depth32Float,
      label: "G-Buffer Depth Texture",
      storageMode: .memoryless
    )
    outputTexture = Self.createOutputTexture(
      size: size,
      label: "InfiniteSpace output texture"
    )
    self.perspCamera.update(size: size)
  }

  func update(elapsedTime: Float, deltaTime: Float) {
    perspCamera.update(deltaTime: deltaTime)
//    let accelometerData = InputController.shared.motion.accelerometerData
//    let rotX = Float(accelometerData?.acceleration.x ?? 0) * 2
//    let rotY = (Float(accelometerData?.acceleration.y ?? 0) + Float.pi / 4) * 0.2
//    let camSpeed = deltaTime * 5
//    perspCamera.position.x += (rotX - perspCamera.position.x) * camSpeed
//    perspCamera.position.y += (rotY - perspCamera.position.y) * camSpeed

    let camBufferPointer = cameraBuffer.contents().bindMemory(
      to: CameraUniforms.self,
      capacity: 1
    )
    camBufferPointer.pointee.viewMatrix = perspCamera.viewMatrix
    camBufferPointer.pointee.projectionMatrix = perspCamera.projectionMatrix
    camBufferPointer.pointee.position = perspCamera.position
  }

  func computePointLightsPositions(commandBuffer: MTLCommandBuffer) {
    commandBuffer.pushDebugGroup("Compute Point Lights Positions")
    guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
      return
    }
    computeEncoder.setComputePipelineState(computePointLightsPipelineState)

    let threadsPerThreadGroup = MTLSizeMake(
      computeBoxesPipelineState.threadExecutionWidth,
      1,
      1
    )
    let threadsPerGrid = MTLSizeMake(Self.POINT_LIGHTS_COUNT, 1, 1)
    computeEncoder.setBuffer(
      pointLightBuffer,
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

  func computeBoxesPositions(commandBuffer: MTLCommandBuffer) {
    commandBuffer.pushDebugGroup("Compute Boxes Positions")
    guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
      return
    }
    computeEncoder.setComputePipelineState(computeBoxesPipelineState)
    let threadsPerThreadGroup = MTLSizeMake(
      computeBoxesPipelineState.threadExecutionWidth,
      1,
      1
    )
    let threadsPerGrid = MTLSizeMake(
      Int(Self.BOXES_COUNT),
      1,
      1
    )

    computeEncoder.setBytes(
      &boidsSettings,
      length: MemoryLayout<InfiniteSpace_BoidsSettings>.stride,
      index: BoidsSettingsBuffer.index
    )
    computeEncoder.setBuffer(
      controlPointsBuffer,
      offset: 0,
      index: ControlPointsBuffer.index
    )

    computeEncoder.dispatchThreads(
      threadsPerGrid,
      threadsPerThreadgroup: threadsPerThreadGroup
    )
    computeEncoder.endEncoding()
    commandBuffer.popDebugGroup()
  }

  func drawGBufferRenderPass(renderEncoder: MTLRenderCommandEncoder) {
    renderEncoder.pushDebugGroup("GBuffer render pass")
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(gBufferPSO)
    renderEncoder.setVertexBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.setVertexBuffer(
      controlPointsBuffer,
      offset: 0,
      index: ControlPointsBuffer.index
    )
    renderEncoder.setVertexBuffer(
      cubesMaterialsBuffer,
      offset: 0,
      index: MaterialsBuffer.index
    )
    cube.instanceCount = Int(Self.BOXES_COUNT)
    cube.draw(renderEncoder: renderEncoder)
    renderEncoder.popDebugGroup()
  }

  func drawSunLight(renderEncoder: MTLRenderCommandEncoder) {
    renderEncoder.pushDebugGroup("Sun Light")
    renderEncoder.setRenderPipelineState(sunLightPSO)
    renderEncoder.setDepthStencilState(lightingDepthStencilState)
    renderEncoder.setFragmentBuffer(
      sunLightBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    renderEncoder.setFragmentBytes(
      &deferredSettings,
      length: MemoryLayout<InfiniteSpace_DeferredSettings>.stride,
      index: DeferredSettingsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    renderEncoder.drawPrimitives(
      type: .triangle,
      vertexStart: 0,
      vertexCount: 6
    )
    renderEncoder.popDebugGroup()
  }

  func drawPointLight(renderEncoder: MTLRenderCommandEncoder) {
    var camUniforms = perspCameraUniforms
    renderEncoder.pushDebugGroup("Point Lights")
    renderEncoder.setRenderPipelineState(pointLightPSO)
    renderEncoder.setVertexBuffer(
      pointLightBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      pointLightBuffer,
      offset: 0,
      index: LightBuffer.index
    )
    renderEncoder.setFragmentBytes(
      &deferredSettings,
      length: MemoryLayout<InfiniteSpace_DeferredSettings>.stride,
      index: DeferredSettingsBuffer.index
    )
    renderEncoder.setFragmentBuffer(
      cameraBuffer,
      offset: 0,
      index: CameraUniformsBuffer.index
    )
    pointLightSphere.instanceCount = Self.POINT_LIGHTS_COUNT
    pointLightSphere.draw(renderEncoder: renderEncoder)
    renderEncoder.popDebugGroup()
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    
    computePointLightsPositions(commandBuffer: commandBuffer)
    computeBoxesPositions(commandBuffer: commandBuffer)

//    let descriptor = view.currentRenderPassDescriptor!
    let descriptor = outputPassDescriptor
    descriptor.colorAttachments[0].texture = outputTexture
    descriptor.colorAttachments[0].storeAction = .store
    descriptor.depthAttachment.texture = outputDepthTexture
    descriptor.depthAttachment.storeAction = .store

    let textures = [
      normalShininessBaseColorTexture,
      positionSpecularColorTexture
    ]
    for (index, texture) in textures.enumerated() {
      let attachment = descriptor.colorAttachments[RenderTargetNormal.index + index]
      attachment?.texture = texture
      attachment?.loadAction = .clear
      attachment?.storeAction = .dontCare
    }

    descriptor.depthAttachment.texture = outputDepthTexture
    descriptor.depthAttachment.storeAction = .dontCare

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    drawGBufferRenderPass(renderEncoder: renderEncoder)
    drawSunLight(renderEncoder: renderEncoder)
    drawPointLight(renderEncoder: renderEncoder)

    renderEncoder.endEncoding()
  }

  func destroy() {
  }
}
