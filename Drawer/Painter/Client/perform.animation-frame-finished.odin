package PainterClient

import "../../../../OdinBasePack"
import "../../../Timer"
import "../../Animation"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
animationFrameFinishedPerform :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	input: Painter.AnimationFrameFinishedEvent,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	animation, _ := getAnimation(module, input.animationId, true) or_return
	if animation.animation.infinite {
		error = .ANIMATION_CANNOT_CHANGE_FRAME_ON_INFINITE_ANIMATION
		return
	}
	animation.animation.currentFrameIndex += 1
	if animation.animation.frameListLength <= animation.animation.currentFrameIndex {
		animation.animation.currentFrameIndex = 0
	}
	removeTexture(module, animation.currentTextureId) or_return
	shapeName: union {
		TShapeName,
		string,
	}
	duration: Timer.Time
	switch value in animation.animation.config {
	case Animation.AnimationConfig(TShapeName, TAnimationName):
		frame := &value.frameList[animation.animation.currentFrameIndex]
		shapeName = frame.shapeName
		duration = frame.duration
	case Animation.DynamicAnimationConfig:
		frame := &value.frameList[animation.animation.currentFrameIndex]
		shapeName = frame.shapeName
		duration = frame.duration
	}
	animation.currentTextureId = createTexture(
		module,
		animation.config.metaConfig,
		Renderer.TextureConfig(TShapeName) {
			shapeName,
			animation.config.rotation,
			animation.config.zoom,
			animation.config.bounds,
		},
	) or_return
	animation.timeoutId = module.eventLoop->task(
		.TIMEOUT,
		duration,
		Painter.PainterEvent(
			Painter.AnimationFrameFinishedEvent{input.animationId, input.layerId},
		),
	) or_return
	return
}
