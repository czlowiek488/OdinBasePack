package PainterClient

import "../../../../OdinBasePack"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
createLine :: proc(
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
	config: Renderer.LineConfig,
) -> (
	lineId: Renderer.LineId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(Renderer.Line, TShapeName, TAnimationName)
	lineId, paint, err = RendererClient.createLine(manager.rendererManager, metaConfig, config)
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
	return
}

@(require_results)
getLine :: proc(
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
	lineId: Renderer.LineId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Line, TShapeName, TAnimationName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	result, ok, err = RendererClient.getLine(manager.rendererManager, lineId, required)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}


@(require_results)
removeLine :: proc(
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
	lineId: Renderer.LineId,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removeLine(manager.rendererManager, lineId)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = unTrackEntity(manager, &paint)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}
