package Painter

import "../Renderer"

AnimationFrameFinishedEvent :: struct #all_or_none {
	animationId: AnimationId,
	layerId:     Renderer.LayerId,
}
