package PainterClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
createString :: proc(
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
	config: Renderer.StringConfig,
) -> (
	stringId: Renderer.StringId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "stringId = {}", stringId)
	paint: ^Renderer.Paint(Renderer.String, TShapeName)
	stringId, paint, err = RendererClient.createString(module.rendererModule, metaConfig, config)
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
getString :: proc(
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
	stringId: Renderer.StringId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.String, TShapeName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "stringId = {}", stringId)
	result, ok, err = RendererClient.getString(module.rendererModule, stringId, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
setStringOffset :: proc(
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
	stringId: Renderer.StringId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err := RendererClient.setStringOffset(module.rendererModule, stringId, offset)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeString :: proc(
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
	stringId: Renderer.StringId,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removeString(module.rendererModule, stringId)
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
