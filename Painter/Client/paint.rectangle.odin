package PainterClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "vendor:sdl3"


@(require_results)
createRectangle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.RectangleConfig,
) -> (
	rectangleId: Renderer.RectangleId,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint: ^Renderer.Paint(Renderer.Rectangle, TShapeName)
	rectangleId, paint = RendererClient.createRectangle(
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
getRectangle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	rectangleId: Renderer.RectangleId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Rectangle, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "rectangleId = {}", rectangleId)
	result, ok = RendererClient.getRectangle(
		module.rendererModule,
		rectangleId,
		required,
	) or_return
	return
}

@(require_results)
removeRectangle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	rectangleId: Renderer.RectangleId,
) -> (
	error: OdinBasePack.Error,
) {
	paint := RendererClient.removeRectangle(module.rendererModule, rectangleId) or_return
	unTrackEntity(module, &paint) or_return
	return
}

@(require_results)
setRectangleOffset :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	rectangleId: Renderer.RectangleId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	RendererClient.setRectangleOffset(module.rendererModule, rectangleId, offset) or_return
	return
}
