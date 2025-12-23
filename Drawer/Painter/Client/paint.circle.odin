package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "vendor:sdl3"

@(require_results)
createCircle :: proc(
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
	metaConfig: Renderer.MetaConfig,
	config: Renderer.CircleConfig,
) -> (
	circleId: Renderer.CircleId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(Renderer.Circle, TShapeName)
	circleId, paint, err = RendererClient.createCircle(module.rendererModule, metaConfig, config)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = trackEntity(
		module,
		cast(^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName))paint,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
setCircleOffset :: proc(
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
	circleId: Renderer.CircleId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err := RendererClient.setCircleOffset(module.rendererModule, circleId, offset)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeCircle :: proc(
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
	circleId: Renderer.CircleId,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removeCircle(module.rendererModule, circleId)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = unTrackEntity(module, &paint)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}


@(require_results)
getCircle :: proc(
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
	circleId: Renderer.CircleId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Circle, TShapeName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "circleId = {}", circleId)
	result, ok, err = RendererClient.getCircle(module.rendererModule, circleId, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
