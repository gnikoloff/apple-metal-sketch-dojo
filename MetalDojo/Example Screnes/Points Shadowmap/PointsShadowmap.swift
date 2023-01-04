//
//  PointsShadowmap.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 31.12.22.
//

// swiftlint:disable identifier_name

import MetalKit

var a: Float = 0

class PointsShadowmap: ExampleScreen {
  private static let SHADOW_CUBE_SIDES = 6
  private static let SHADOWMAP_SIZE: CGFloat = 512
  private static let SHADOW_PASS_LABEL = "Point Shadow Pass"
  private static let FORWARD_PASS_LABEL = "Point Shadow Map Pass"
  private static let SHADOW_CAMERA_LOOK_ATS = [
    float3(1, 0, 0),
    float3(-1, 0, 0),
    float3(0, 1, 0),
    float3(0, -1, 0),
    float3(0, 0, 1),
    float3(0, 0, -1)
  ]
  private static let SHADOW_CAMERA_UPS = [
    float3(0, 1, 0),
    float3(0, 1, 0),
    float3(0, 0, -1),
    float3(0, 0, 1),
    float3(0, 1, 0),
    float3(0, 1, 0),
  ]

  private let shadowDescriptor: MTLRenderPassDescriptor
  private let shadowPipelineState: MTLRenderPipelineState
  private var cubeRenderPipeline: MTLRenderPipelineState
  private let sphereRenderPipeline: MTLRenderPipelineState
  private let depthStencilState: MTLDepthStencilState?

  private var cube: EnvCube
  private var sphere: DottedSphere

  private var perspCameraUniforms = CameraUniforms()
  private var perspCamera = ArcballCamera()

  private var cubeShadowTexture: MTLTexture
  private var shadowCameraUniforms = CameraUniforms()
  private var shadowLightUniforms = PointsShadowmap_Light()
  private var shadowPerspCamera = PerspectiveCamera(
    aspect: Float(PointsShadowmap.SHADOWMAP_SIZE / PointsShadowmap.SHADOWMAP_SIZE),
    fov: Float(90).degreesToRadians,
    near: 0.1,
    far: 25
  )
  private var shadowCamUniformBuffer: MTLBuffer

  var cubeSidesContents: UnsafeMutablePointer<PointsShadowmap_View>

  init() {
    shadowPipelineState = PointsShadowmapPipelineStates.createShadowPSO()
    cubeRenderPipeline = PointsShadowmapPipelineStates.createCubePSO(
      colorPixelFormat: Renderer.viewColorFormat
    )
    sphereRenderPipeline = PointsShadowmapPipelineStates.createSpherePSO(
      colorPixelFormat: Renderer.viewColorFormat
    )
    depthStencilState = Renderer.buildDepthStencilState()

    cube = EnvCube(size: 1.5)
    cube.cullMode = .front
    sphere = DottedSphere(size: 0.1435)
    sphere.cullMode = .front

    shadowDescriptor = MTLRenderPassDescriptor()
    cubeShadowTexture = RenderPass.makeCubeTexture(
      size: PointsShadowmap.SHADOWMAP_SIZE,
      pixelFormat: .depth32Float,
      label: "Shadow Cube Map Texture"
    )!
    self.shadowCamUniformBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<PointsShadowmap_View>.stride * PointsShadowmap.SHADOW_CUBE_SIDES
    )!
    cubeSidesContents = shadowCamUniformBuffer.contents().bindMemory(to: PointsShadowmap_View.self, capacity: PointsShadowmap.SHADOW_CUBE_SIDES)

  }

  func resize(view: MTKView, size: CGSize) {
    self.perspCamera.update(size: size)
  }

  func update(deltaTime: Float) {
    perspCamera.update(deltaTime: deltaTime)
  }

  func updateUniforms() {
    perspCameraUniforms.viewMatrix = perspCamera.viewMatrix
    perspCameraUniforms.projectionMatrix = perspCamera.projectionMatrix
    perspCameraUniforms.position = perspCamera.position

    shadowLightUniforms.position = shadowPerspCamera.position
  }

  func drawShadowCubeMap(commandBuffer: MTLCommandBuffer) {
    let lightPos = shadowPerspCamera.position

    for i in 0 ..< PointsShadowmap.SHADOW_CUBE_SIDES {
      shadowPerspCamera.target = lightPos + PointsShadowmap.SHADOW_CAMERA_LOOK_ATS[i]
      shadowPerspCamera.up = PointsShadowmap.SHADOW_CAMERA_UPS[i]
      cubeSidesContents[i].viewProjectionMatrix = shadowPerspCamera.projectionMatrix * shadowPerspCamera.viewMatrix
    }

    shadowDescriptor.depthAttachment.texture = cubeShadowTexture
    shadowDescriptor.depthAttachment.storeAction = .store
    shadowDescriptor.renderTargetArrayLength = PointsShadowmap.SHADOW_CUBE_SIDES

    guard let shadowRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowDescriptor) else {
      return
    }

    shadowRenderEncoder.setVertexBuffer(
      shadowCamUniformBuffer,
      offset: 0,
      index: UniformsBuffer.index + 1
    )
    shadowRenderEncoder.setFragmentBytes(
      &shadowLightUniforms,
      length: MemoryLayout<PointsShadowmap_Light>.stride,
      index: UniformsBuffer.index + 2
    )
    shadowRenderEncoder.label = PointsShadowmap.SHADOW_PASS_LABEL
    shadowRenderEncoder.setDepthStencilState(depthStencilState)
    shadowRenderEncoder.setRenderPipelineState(shadowPipelineState)

    sphere.instanceCount = PointsShadowmap.SHADOW_CUBE_SIDES
    sphere.cullMode = .none
    sphere.scale = 2
    sphere.draw(renderEncoder: shadowRenderEncoder)
    sphere.scale = 1

    shadowRenderEncoder.endEncoding()
  }

  func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
    drawShadowCubeMap(commandBuffer: commandBuffer)

    guard let descriptor = view.currentRenderPassDescriptor else {
      return
    }

    view.clearColor = MTLClearColor(red: 1, green: 0.2, blue: 1, alpha: 1)

//    descriptor.colorAttachments[0].loadAction = .load

    var camUniforms = perspCameraUniforms
    updateUniforms()

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }

    renderEncoder.setVertexBytes(
      &camUniforms,
      length: MemoryLayout<CameraUniforms>.stride,
      index: UniformsBuffer.index + 1
    )
    renderEncoder.setFragmentBytes(
      &shadowLightUniforms,
      length: MemoryLayout<PointsShadowmap_Light>.stride,
      index: UniformsBuffer.index + 2
    )

    renderEncoder.setFragmentTexture(
      cubeShadowTexture,
      index: PointsShadowmap_CubeShadowTexture.index
    )

    renderEncoder.label = PointsShadowmap.FORWARD_PASS_LABEL
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(cubeRenderPipeline)

    cube.instanceCount = 1

    cube.draw(renderEncoder: renderEncoder)

    renderEncoder.setRenderPipelineState(sphereRenderPipeline)
    sphere.position.x = sin(a) * 0.3
    sphere.position.y = cos(a) * 0.3

    sphere.rotation.x = a * 0.2
    sphere.rotation.y = a * 0.2
    sphere.rotation.z = -a
    sphere.position.z = cos(a) * 0.3
    sphere.instanceCount = 1
    shadowPerspCamera.position = sphere.position
    shadowPerspCamera.rotation = sphere.rotation
    sphere.draw(renderEncoder: renderEncoder)

    a += 0.02

    renderEncoder.endEncoding()
  }

  func destroy() {
  }

}
