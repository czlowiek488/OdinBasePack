package PainterClient

import "../../../OdinBasePack"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
createLine :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.LineConfig,
) -> (
	lineId: Renderer.LineId,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint: ^Renderer.Paint(Renderer.Line, TShapeName)
	lineId, paint = RendererClient.createLine(module.rendererModule, metaConfig, config) or_return
	trackEntity(
		module,
		cast(^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName))paint,
	) or_return
	return
}

@(require_results)
getLine :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	lineId: Renderer.LineId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Line, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = RendererClient.getLine(module.rendererModule, lineId, required) or_return
	return
}


@(require_results)
removeLine :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	lineId: Renderer.LineId,
) -> (
	error: OdinBasePack.Error,
) {
	paint := RendererClient.removeLine(module.rendererModule, lineId) or_return
	unTrackEntity(module, &paint) or_return
	return
}
