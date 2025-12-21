package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
createString :: proc(
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
	config: Renderer.StringConfig,
) -> (
	stringId: Renderer.StringId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "stringId = {}", stringId)
	paint: ^Renderer.Paint(Renderer.String, TShapeName, TAnimationName)
	stringId, paint, err = RendererClient.createString(manager.rendererManager, metaConfig, config)
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
getString :: proc(
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
	stringId: Renderer.StringId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.String, TShapeName, TAnimationName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "stringId = {}", stringId)
	result, ok, err = RendererClient.getString(manager.rendererManager, stringId, required)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
setStringOffset :: proc(
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
	stringId: Renderer.StringId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err := RendererClient.setStringOffset(manager.rendererManager, stringId, offset)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeString :: proc(
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
	stringId: Renderer.StringId,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removeString(manager.rendererManager, stringId)
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
