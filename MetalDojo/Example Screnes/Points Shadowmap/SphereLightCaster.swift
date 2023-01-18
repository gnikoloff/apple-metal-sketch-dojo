//
//  SphereLightCaster.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 04.01.23.
//

// swiftlint:disable identifier_name

import MetalKit

var shadowDescriptor = MTLRenderPassDescriptor()
var depthStencilState: MTLDepthStencilState?

struct SphereLightCaster: Transformable {
  static let SHADOWMAP_SIZE: CGFloat = 512
  static let SHADOW_CUBE_SIDES = 6
  private static let SHADOW_PASS_LABEL = "Point Shadow Pass"

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
    float3(0, 1, 0)
  ]

  var cubeShadowTexture: MTLTexture
  var transform = Transform()

  private let shadowPipelineState: MTLRenderPipelineState


  private var sphere: Sphere
  private var centerSphere: Sphere

  private var shadowPerspCamera = PerspectiveCamera(
    aspect: Float(SphereLightCaster.SHADOWMAP_SIZE / SphereLightCaster.SHADOWMAP_SIZE),
    fov: Float(90).degreesToRadians,
    near: 0.1,
    far: 25
  )
  private var shadowCamUniformBuffer: MTLBuffer
  private var cubeSidesContents: UnsafeMutablePointer<PointsShadowmap_View>

  init() {
    sphere = Sphere(size: 0.1435)
    centerSphere = Sphere(size: 0.05)

    shadowCamUniformBuffer = Renderer.device.makeBuffer(
      length: MemoryLayout<PointsShadowmap_View>.stride * SphereLightCaster.SHADOW_CUBE_SIDES
    )!
    cubeSidesContents = shadowCamUniformBuffer
      .contents()
      .bindMemory(to: PointsShadowmap_View.self, capacity: SphereLightCaster.SHADOW_CUBE_SIDES)
    cubeShadowTexture = RenderPass.makeCubeTexture(
      size: SphereLightCaster.SHADOWMAP_SIZE,
      pixelFormat: .depth16Unorm,
      label: "Shadow Cube Map Texture"
    )!

    do {
      try shadowPipelineState = PointsShadowmapPipelineStates.createShadowPSO()
    } catch {
      fatalError(error.localizedDescription)
    }

    if depthStencilState == nil {
      depthStencilState = PipelineState.buildDepthStencilState()
    }
  }

  mutating func drawCubeShadow(commandBuffer: MTLCommandBuffer, idx: Int, shadowCastersBuffer: MTLBuffer) {
    shadowPerspCamera.position = position
    shadowPerspCamera.rotation = rotation
    let lightPos = shadowPerspCamera.position

    for i in 0 ..< SphereLightCaster.SHADOW_CUBE_SIDES {
      shadowPerspCamera.target = lightPos + SphereLightCaster.SHADOW_CAMERA_LOOK_ATS[i]
      shadowPerspCamera.up = SphereLightCaster.SHADOW_CAMERA_UPS[i]
      cubeSidesContents[i].viewProjectionMatrix = shadowPerspCamera.projectionMatrix * shadowPerspCamera.viewMatrix
    }

    shadowDescriptor.depthAttachment.texture = cubeShadowTexture
    shadowDescriptor.depthAttachment.storeAction = .store
    shadowDescriptor.renderTargetArrayLength = SphereLightCaster.SHADOW_CUBE_SIDES

    guard let shadowRenderEncoder = commandBuffer
      .makeRenderCommandEncoder(descriptor: shadowDescriptor) else {
      return
    }

    shadowRenderEncoder.label = SphereLightCaster.SHADOW_PASS_LABEL
    shadowRenderEncoder.setDepthStencilState(depthStencilState)
    shadowRenderEncoder.setRenderPipelineState(shadowPipelineState)

    shadowRenderEncoder.setVertexBuffer(
      shadowCamUniformBuffer,
      offset: 0,
      index: ShadowCameraUniformsBuffer.index
    )
    shadowRenderEncoder.setFragmentBuffer(
      shadowCastersBuffer,
      offset: idx * MemoryLayout<PointsShadowmap_Light>.stride,
      index: ShadowCameraUniformsBuffer.index
    )

    sphere.instanceCount = SphereLightCaster.SHADOW_CUBE_SIDES
    sphere.scale = 2
    sphere.draw(renderEncoder: shadowRenderEncoder)


    shadowRenderEncoder.endEncoding()
  }

  mutating func drawCenterSphere(renderEncoder: MTLRenderCommandEncoder) {
    centerSphere.draw(renderEncoder: renderEncoder)
  }

  mutating func draw(renderEncoder: MTLRenderCommandEncoder) {
    sphere.scale = 1
    sphere.instanceCount = 1
    sphere.draw(renderEncoder: renderEncoder)
  }
}

extension SphereLightCaster {
  var position: float3 {
    get { sphere.position }
    set {
      sphere.position = newValue
      centerSphere.position = newValue
    }
  }
  var rotation: float3 {
    get { sphere.rotation }
    set {
      sphere.rotation = newValue
      centerSphere.rotation = newValue
    }
  }
  var scale: Float {
    get { sphere.scale }
    set {
      sphere.scale = newValue
      centerSphere.scale = newValue
    }
  }
  var cullMode: MTLCullMode {
    get { sphere.cullMode }
    set { sphere.cullMode = newValue }
  }
}
