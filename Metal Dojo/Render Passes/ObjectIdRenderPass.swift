//
//  ObjectIdRenderPass.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import MetalKit

struct ObjectIdRenderPass: RenderPass {
  let label = "Object ID Render Pass"
  var descriptor: MTLRenderPassDescriptor?
  var pipelineState: MTLRenderPipelineState
  var idTexture: MTLTexture?

  init() {
    pipelineState = PipelineStates.createObjectIdPSO()
    descriptor = MTLRenderPassDescriptor()
  }

  mutating func resize(view: MTKView, size: CGSize) {
    idTexture = Self.makeTexture(
      size: size,
      pixelFormat: .r32Uint,
      label: "ID Texture",
      storageMode: .shared
    )
  }
  
  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    orthoCameraUniforms: CameraUniforms,
    perspCameraUniforms: CameraUniforms,
    params: Params
  ) {
    guard let descriptor = descriptor else {
      return
    }
    descriptor.colorAttachments[0].texture = idTexture
    descriptor.colorAttachments[0].loadAction = .clear
    descriptor.colorAttachments[0].storeAction = .store
    guard let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }
    renderEncoder.label = label
    renderEncoder.setRenderPipelineState(pipelineState)
    var scene = scene
    scene.projectsGrid.draw(encoder: renderEncoder, orthoCameraUniforms: orthoCameraUniforms, params: params)
    renderEncoder.endEncoding()
  }
  
}
