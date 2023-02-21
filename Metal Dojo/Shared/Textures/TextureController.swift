//
//  TextureController.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 25.01.23.
//

// swiftlint:disable compiler_protocol_init

import MetalKit

enum TextureController {
  static var textures: [String: MTLTexture] = [:]

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
    usage: MTLTextureUsage = [.shaderRead, .renderTarget],
    arrayLength: Int = 1
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
    textureDesc.arrayLength = arrayLength

    guard let texture = Renderer.device.makeTexture(descriptor: textureDesc) else {
        fatalError("Failed to create texture")
      }
    texture.label = label
    return texture
  }

  static func texture(filename: String) -> MTLTexture? {
    if let texture = textures[filename] {
      return texture
    }
    let texture = try? loadTexture(filename: filename)
    if texture != nil {
      textures[filename] = texture
    }
    return texture
  }

  // load from string file name
  static func loadTexture(filename: String) throws -> MTLTexture? {
    let textureLoader = MTKTextureLoader(device: Renderer.device)

    if let texture = try? textureLoader.newTexture(
      name: filename,
      scaleFactor: 1.0,
      bundle: Bundle.main,
      options: nil) {
      print("loaded texture: \(filename)")
      return texture
    }

    let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
      .origin: MTKTextureLoader.Origin.bottomLeft,
      .SRGB: false,
      .generateMipmaps: NSNumber(value: true)
    ]
    let fileExtension =
      URL(fileURLWithPath: filename).pathExtension.isEmpty ?
        "png" : nil
    guard let url = Bundle.main.url(
      forResource: filename,
      withExtension: fileExtension)
      else {
        print("Failed to load \(filename)")
        return nil
    }
    let texture = try textureLoader.newTexture(
      URL: url,
      options: textureLoaderOptions)
    print("loaded texture: \(url.lastPathComponent)")
    return texture
  }

  // load from USDZ file
  static func loadTexture(texture: MDLTexture) throws -> MTLTexture? {
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
      .origin: MTKTextureLoader.Origin.bottomLeft,
      .SRGB: false,
      .generateMipmaps: NSNumber(booleanLiteral: true)
    ]
    let texture = try? textureLoader.newTexture(
      texture: texture,
      options: textureLoaderOptions)
    print("loaded texture from MDLTexture")
    if texture != nil {
      let filename = UUID().uuidString
      textures[filename] = texture
    }
    return texture
  }
}
