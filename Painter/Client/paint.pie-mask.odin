package PainterClient

import "../../../OdinBasePack"
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
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint: ^Renderer.Paint(Renderer.PieMask, TShapeName)
	pieMaskId, paint = RendererClient.createPieMask(
		module.rendererModule,
		metaConfig,
		config,
	) or_return
	trackEntity(
		module,
		cast(^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName))paint,
	) or_return
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
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = RendererClient.getPieMask(module.rendererModule, pieMaskId, required) or_return
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
	error: OdinBasePack.Error,
) {
	RendererClient.updatePieMask(module.rendererModule, pieMaskId, fillPercentage) or_return
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
	error: OdinBasePack.Error,
) {
	paint := RendererClient.removePieMask(module.rendererModule, pieMaskId, location) or_return
	unTrackEntity(module, &paint) or_return
	return
}
