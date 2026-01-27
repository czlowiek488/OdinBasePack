package PainterClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
createTriangle :: proc(
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
	config: Renderer.TriangleConfig,
) -> (
	triangleId: Renderer.TriangleId,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint: ^Renderer.Paint(Renderer.Triangle, TShapeName)
	triangleId, paint = RendererClient.createTriangle(
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
getTriangle :: proc(
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
	triangleId: Renderer.TriangleId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Triangle, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "triangleId = {}", triangleId)
	result, ok = RendererClient.getTriangle(module.rendererModule, triangleId, required) or_return
	return
}

@(require_results)
removeTriangle :: proc(
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
	triangleId: Renderer.TriangleId,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint: Renderer.Paint(Renderer.Triangle, TShapeName)
	paint = RendererClient.removeTriangle(module.rendererModule, triangleId) or_return
	unTrackEntity(module, &paint) or_return
	return
}

@(require_results)
setTriangleOffset :: proc(
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
	triangleId: Renderer.TriangleId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	RendererClient.setTriangleOffset(module.rendererModule, triangleId, offset) or_return
	return
}
