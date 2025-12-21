package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Animation"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
setAnimationOffset :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	animationId: Renderer.AnimationId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err := RendererClient.setAnimationOffset(manager.rendererManager, animationId, offset)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
setAnimation :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.AnimationConfig(TShapeName, TAnimationName),
) -> (
	animationId: Renderer.AnimationId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(
		Renderer.Animation(TShapeName, TAnimationName),
		TShapeName,
		TAnimationName,
	)
	animationId, paint, err = RendererClient.setAnimation(
		manager.rendererManager,
		metaConfig,
		config,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = trackEntity(
		manager,
		cast(^Renderer.Paint(
			Renderer.PaintData(TShapeName, TAnimationName),
			TShapeName,
			TAnimationName,
		))paint,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	animation := cast(^Renderer.Paint(
		Renderer.Animation(TShapeName, TAnimationName),
		TShapeName,
		TAnimationName,
	))paint
	if animation.element.animation.infinite {
		return
	}
	switch value in animation.element.animation.config {
	case Animation.AnimationConfig(TShapeName, TAnimationName):
		paint.element.timeoutId = manager.eventLoop->task(
			.TIMEOUT,
			value.frameList[0].duration,
			Painter.PainterEvent(
				Painter.AnimationFrameFinishedEvent{animationId, metaConfig.layer},
			),
		) or_return
	case Animation.DynamicAnimationConfig:
		paint.element.timeoutId = manager.eventLoop->task(
			.TIMEOUT,
			value.frameList[0].duration,
			Painter.PainterEvent(
				Painter.AnimationFrameFinishedEvent{animationId, metaConfig.layer},
			),
		) or_return
	}
	return
}

@(require_results)
removeAnimation :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	animationId: Renderer.AnimationId,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removeAnimation(manager.rendererManager, animationId)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = unTrackEntity(manager, &paint)

	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	if timeoutId, ok := paint.element.timeoutId.?; ok {
		_ = manager.eventLoop->unSchedule(timeoutId, true) or_return
	}
	return
}

@(require_results)
getAnimation :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	animationId: Renderer.AnimationId,
	required: bool,
) -> (
	result: ^Renderer.Paint(
		Renderer.Animation(TShapeName, TAnimationName),
		TShapeName,
		TAnimationName,
	),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	result, ok, err = RendererClient.getAnimation(manager.rendererManager, animationId, required)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}
