package PainterClient

import "../../../../OdinBasePack"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
createPieMask :: proc(
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
	config: Renderer.PieMaskConfig,
) -> (
	pieMaskId: Renderer.PieMaskId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(Renderer.PieMask, TShapeName)
	pieMaskId, paint, err = RendererClient.createPieMask(module.rendererModule, metaConfig, config)
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
getPieMask :: proc(
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
	pieMaskId: Renderer.PieMaskId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.PieMask, TShapeName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	result, ok, err = RendererClient.getPieMask(module.rendererModule, pieMaskId, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
updatePieMask :: proc(
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
	pieMaskId: Renderer.PieMaskId,
	fillPercentage: f32,
) -> (
	error: TError,
) {
	err := RendererClient.updatePieMask(module.rendererModule, pieMaskId, fillPercentage)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
@(require_results)
removePieMask :: proc(
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
	pieMaskId: Renderer.PieMaskId,
	location := #caller_location,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removePieMask(module.rendererModule, pieMaskId, location)
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
