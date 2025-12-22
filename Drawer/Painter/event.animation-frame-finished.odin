package Painter

import "../Renderer"

AnimationFrameFinishedEvent :: struct #all_or_none {
	animationId: Renderer.AnimationId,
	layerId:     Renderer.LayerId,
}
