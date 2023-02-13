//
//  Submesh.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 02.01.23.
//

import MetalKit

struct Submesh {
  let indexCount: Int
  let indexType: MTLIndexType
  let indexBuffer: MTLBuffer
  let indexBufferOffset: Int

  class Textures {
    var baseColor: MTLTexture?
    var normal: MTLTexture?
    var roughness: MTLTexture?
    var metallic: MTLTexture?
    var ambientOcclusion: MTLTexture?
    var opacity: MTLTexture?
    init(material: MDLMaterial?) {
      func property(with semantic: MDLMaterialSemantic,
                    callback: @escaping (_ texture: MTLTexture) -> Void) -> Void {
        let property = material?.property(with: semantic)
//
//        if ((property?.stringValue?.contains("material_0_diffuse")) != nil) {
//          TextureController.texture(filename: "dino-diffuse", callback: callback)
//        }
//        if ((property?.stringValue?.contains("material_0_normal")) != nil) {
//          TextureController.texture(filename: "dino-normal", callback: callback)
//        }
//        if ((property?.stringValue?.contains("material_0_occlusion")) != nil) {
//          TextureController.texture(filename: "dino-occlusion", callback: callback)
//        }

        if property?.type == .string {
          guard let filename = property?.stringValue else {
            fatalError("Not a valid texture property")
          }

        } else if property?.type == .texture {
          guard let mdlTexture = property?.textureSamplerValue?.texture else {
            fatalError("Can't load texture")
          }
          TextureController.loadTexture(
            texture: mdlTexture,
            callback: { texture, error in
              if error != nil || texture == nil {
                fatalError("Loaded texture is not valid")
              }
              callback(texture!)
            })
        }
      }
      property(with: MDLMaterialSemantic.baseColor, callback: { texture in
        self.baseColor = texture
      })
      property(with: .tangentSpaceNormal, callback: { texture in
        self.normal = texture
      })
      property(with: .roughness, callback: { texture in
        self.roughness = texture
      })
      property(with: .metallic, callback: { texture in
        self.metallic = texture
      })
      property(with: .ambientOcclusion, callback: { texture in
        self.ambientOcclusion = texture
      })
      property(with: .opacity, callback: { texture in
        self.opacity = texture
      })
    }
  }

  let textures: Textures
  let material: Material
}

extension Submesh {
  init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
    indexCount = mtkSubmesh.indexCount
    indexType = mtkSubmesh.indexType
    indexBuffer = mtkSubmesh.indexBuffer.buffer
    indexBufferOffset = mtkSubmesh.indexBuffer.offset
    textures = Textures(material: mdlSubmesh.material)
    material = Material(material: mdlSubmesh.material)
  }
}

private extension Submesh.Textures {

}

private extension Material {
  init(material: MDLMaterial?) {
    self.init()
    if let baseColor = material?.property(with: .baseColor),
      baseColor.type == .float3 {
      self.baseColor = baseColor.float3Value
    }
    if let specular = material?.property(with: .specular),
      specular.type == .float3 {
      self.specularColor = specular.float3Value
    }
    if let shininess = material?.property(with: .specularExponent),
      shininess.type == .float {
      self.shininess = shininess.floatValue
    }
    self.ambientOcclusion = 1
    if let roughness = material?.property(with: .roughness),
      roughness.type == .float3 {
      self.roughness = roughness.floatValue
    }
    if let metallic = material?.property(with: .metallic),
      metallic.type == .float3 {
      self.metallic = metallic.floatValue
    }
    if let ambientOcclusion = material?.property(with: .ambientOcclusion),
      ambientOcclusion.type == .float3 {
      self.ambientOcclusion = ambientOcclusion.floatValue
    }
  }
}

