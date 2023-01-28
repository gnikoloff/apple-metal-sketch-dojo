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
//      print("loaded texture: \(filename)")
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
//    print("loaded texture: \(url.lastPathComponent)")
    return texture
  }

  // load from USDZ file
  static func loadTexture(texture: MDLTexture) throws -> MTLTexture? {
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
      .origin: MTKTextureLoader.Origin.bottomLeft,
      .SRGB: false,
      .generateMipmaps: NSNumber(booleanLiteral: false)
    ]
    let texture = try? textureLoader.newTexture(
      texture: texture,
      options: textureLoaderOptions)
//    print("loaded texture from MDLTexture")
    if texture != nil {
      let filename = UUID().uuidString
      textures[filename] = texture
    }
    return texture
  }

  // load a cube texture
  static func loadCubeTexture(imageName: String) throws -> MTLTexture {
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    if let texture = MDLTexture(cubeWithImagesNamed: [imageName]) {
      let options: [MTKTextureLoader.Option: Any] = [
        .origin: MTKTextureLoader.Origin.topLeft,
        .SRGB: false,
        .generateMipmaps: NSNumber(booleanLiteral: false)
      ]
      return try textureLoader.newTexture(
        texture: texture,
        options: options)
    }
    let texture = try textureLoader.newTexture(
      name: imageName,
      scaleFactor: 1.0,
      bundle: .main)
    return texture
  }
}
