package PainterClient

import "../../../../OdinBasePack"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
createPieMask :: proc(
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
	config: Renderer.PieMaskConfig,
) -> (
	pieMaskId: Renderer.PieMaskId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(Renderer.PieMask, TShapeName)
	pieMaskId, paint, err = RendererClient.createPieMask(
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
		cast(^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName))paint,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
getPieMask :: proc(
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
	pieMaskId: Renderer.PieMaskId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.PieMask, TShapeName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	result, ok, err = RendererClient.getPieMask(manager.rendererManager, pieMaskId, required)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
updatePieMask :: proc(
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
	pieMaskId: Renderer.PieMaskId,
	fillPercentage: f32,
) -> (
	error: TError,
) {
	err := RendererClient.updatePieMask(manager.rendererManager, pieMaskId, fillPercentage)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}
@(require_results)
removePieMask :: proc(
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
	pieMaskId: Renderer.PieMaskId,
	location := #caller_location,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removePieMask(manager.rendererManager, pieMaskId, location)
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
