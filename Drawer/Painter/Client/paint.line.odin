package PainterClient

import "../../../../OdinBasePack"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
createLine :: proc(
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
	config: Renderer.LineConfig,
) -> (
	lineId: Renderer.LineId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(Renderer.Line, TShapeName)
	lineId, paint, err = RendererClient.createLine(module.rendererModule, metaConfig, config)
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
getLine :: proc(
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
	lineId: Renderer.LineId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Line, TShapeName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	result, ok, err = RendererClient.getLine(module.rendererModule, lineId, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}


@(require_results)
removeLine :: proc(
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
	lineId: Renderer.LineId,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removeLine(module.rendererModule, lineId)
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
