components {
  id: "boat"
  component: "/example/scripts/boat.script"
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/example/assets/kenney-pirates/GLB format/ship-pirate-large.glb\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"colormap\"\n"
  "  material: \"/example/components/materials/model_instanced.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/example/assets/kenney-pirates/GLB format/Textures/colormap.png\"\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
  position {
    y: 3.210658
  }
  rotation {
    y: -0.70710677
    w: 0.70710677
  }
}
