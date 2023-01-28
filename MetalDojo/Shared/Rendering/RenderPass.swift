//
//  RenderPass.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 27.12.22.
//

import MetalKit

enum RenderPass {}

extension RenderPass {
  static func buildDepthStencilState() -> MTLDepthStencilState? {
    let descriptor = MTLDepthStencilDescriptor()
    descriptor.depthCompareFunction = .less
    descriptor.isDepthWriteEnabled = true
    return Renderer.device.makeDepthStencilState(
      descriptor: descriptor)
  }

  static func makeCubeTexture(
    size: CGFloat,
    pixelFormat: MTLPixelFormat,
    label: String,
    mipmapped: Bool = false,
    storageMode: MTLStorageMode = .private,
    usage: MTLTextureUsage = [.shaderRead, .renderTarget]
  ) -> MTLTexture? {
    let size = Int(size)
    guard size > 0 else {
      return nil
    }
    let textureDesc = MTLTextureDescriptor.textureCubeDescriptor(
      pixelFormat: pixelFormat,
      size: size,
      mipmapped: mipmapped
    )
    textureDesc.storageMode = storageMode
    textureDesc.usage = usage
    guard let texture = Renderer.device.makeTexture(descriptor: textureDesc) else {
      fatalError("Failed to create a cube texture")
    }
    texture.label = label
    return texture
  }

  static func makeTexture(
    size: CGSize,
    pixelFormat: MTLPixelFormat,
    label: String,
    storageMode: MTLStorageMode = .private,
    type: MTLTextureType = .type2D,
    usage: MTLTextureUsage = [.shaderRead, .renderTarget]
  ) -> MTLTexture? {
    let width = Int(size.width)
    let height = Int(size.height)
    guard width > 0 && height > 0 else { return nil }
    let textureDesc = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: pixelFormat,
      width: width,
      height: height,
      mipmapped: false
    )
    textureDesc.storageMode = storageMode
    textureDesc.usage = usage
    textureDesc.textureType = type
    guard let texture = Renderer.device.makeTexture(descriptor: textureDesc) else {
        fatalError("Failed to create texture")
      }
    texture.label = label
    return texture
  }
}
