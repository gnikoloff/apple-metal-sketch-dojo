//
//  Project.swift
//  MetalDojo
//
//  Created by Georgi Nikoloff on 29.12.22.
//

// swiftlint:disable line_length

let demosDescriptions: [String: String] = [
  PointsShadowmap.SCREEN_NAME: """
  Renders point light shadows into a cube texture with a single drawcall via layer selection in vertex shader.

  References:

    - [Rendering Reflections with Fewer Render Passes](https://developer.apple.com/documentation/metal/metal_sample_code_library/rendering_reflections_with_fewer_render_passes)
    - [Learn OpenGL - Point Shadows](https://learnopengl.com/Advanced-Lighting/Shadows/Point-Shadows)
  """,
  InfiniteSpace.SCREEN_NAME: """
  Renders \(InfiniteSpace.BOXES_COUNT) boxes lighted by \(InfiniteSpace.POINT_LIGHTS_COUNT) point lights.

  Uses compute shaders to animate the boxes / lights positions and deferred rendering to decouple scene geometry complexity from shading.

  It takes advantage of modern Tile-Based Deferred Rendering architecture on Apple GPUs. In traditional deferred rendering, you render the intermediate G-Buffer textures to video memory and fetch them at your final light accumulation pass.

  However TBDR GPUs introduce tile memory: "Tile memory is fast, temporary storage that resides on the GPU itself. After the GPU finishes rendering each tile into tile memory, it writes the final result to device memory".

  References:

    - [Metal Docs - Tile-Based Deferred Rendering](https://developer.apple.com/documentation/metal/tailor_your_apps_for_apple_gpus_and_tile-based_deferred_rendering)
    - [Compact Normal Storage for small G-Buffers](https://aras-p.info/texts/CompactNormalStorage.html)
  """,
  AppleMetalScreen.SCREEN_NAME: """
  Uses compute shaders to animate the particles and lights.
  """,
  CascadedShadowsMap.SCREEN_NAME: """
  Uses physically based lighting for shading the model and environment.

  Uses cascaded shadow mapping for best shadow quality up close and reduced quality further away from camera. All the scenes contained within the different cascaded are rendered in a single pass via layer selection.

  Has support for skeleton animations.

  References:

    - [Rendering Reflections with Fewer Render Passes](https://developer.apple.com/documentation/metal/metal_sample_code_library/rendering_reflections_with_fewer_render_passes)
    - [Learn OpenGL - Cascaded Shadow Mapping](https://learnopengl.com/Guest-Articles/2021/CSM)

  Models:
  
    - [Junonia Lemonias Butterfly Rigged](https://sketchfab.com/3d-models/junonia-lemonias-butterfly-rigged-d912ff1fcd0e477c8a84e08ec280377a)
    - [Animated T-Rex Dinosaur Biting Attack Loop](https://sketchfab.com/3d-models/animated-t-rex-dinosaur-biting-attack-loop-5bbcadb7d9274843abb5ada35767dba1)
  """
]

struct ProjectModel {
  var name: String
  var description: String

  init(name: String) {
    self.name = name
    self.description = demosDescriptions[name]!
  }

}
