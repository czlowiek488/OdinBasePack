package PainterClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "vendor:sdl3"

@(require_results)
createCircle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.CircleConfig,
) -> (
	circleId: Renderer.CircleId,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint: ^Renderer.Paint(Renderer.Circle, TShapeName)
	circleId, paint = RendererClient.createCircle(
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
setCircleOffset :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	circleId: Renderer.CircleId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	RendererClient.setCircleOffset(module.rendererModule, circleId, offset) or_return
	return
}

@(require_results)
removeCircle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	circleId: Renderer.CircleId,
) -> (
	error: OdinBasePack.Error,
) {
	paint := RendererClient.removeCircle(module.rendererModule, circleId) or_return
	unTrackEntity(module, &paint) or_return
	return
}


@(require_results)
getCircle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	circleId: Renderer.CircleId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Circle, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "circleId = {}", circleId)
	result, ok = RendererClient.getCircle(module.rendererModule, circleId, required) or_return
	return
}
