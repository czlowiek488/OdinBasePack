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
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "stringId = {}", stringId)
	paint: ^Renderer.Paint(Renderer.String, TShapeName)
	stringId, paint = RendererClient.createString(
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
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "stringId = {}", stringId)
	result, ok = RendererClient.getString(module.rendererModule, stringId, required) or_return
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
	error: OdinBasePack.Error,
) {
	RendererClient.setStringOffset(module.rendererModule, stringId, offset) or_return
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
	error: OdinBasePack.Error,
) {
	paint := RendererClient.removeString(module.rendererModule, stringId) or_return
	unTrackEntity(module, &paint) or_return
	return
}
