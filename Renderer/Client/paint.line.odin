package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Renderer"
import "vendor:sdl3"

@(require_results)
createLine :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.LineConfig,
) -> (
	lineId: Renderer.LineId,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId, paint := createPaint(module, metaConfig, Renderer.Line{0, config}) or_return
	lineId = Renderer.LineId(paintId)
	trackEntity(module, cast(^Renderer.Paint(Renderer.PaintData))paint) or_return
	return
}

@(require_results)
getLine :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	lineId: Renderer.LineId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Line),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = getPaint(module, lineId, Renderer.Line, required) or_return
	return
}


@(require_results)
removeLine :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	lineId: Renderer.LineId,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint := removePaint(module, lineId, Renderer.Line) or_return
	unTrackEntity(module, &paint) or_return
	return
}

@(require_results)
drawLine :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	line: ^Renderer.Paint(Renderer.Line),
) -> (
	error: OdinBasePack.Error,
) {
	start, end: Math.Vector
	switch line.config.positionType {
	case .CAMERA:
		start = line.element.config.start
		end = line.element.config.end
	case .MAP:
		start = line.element.config.start - module.camera.bounds.position
		end = line.element.config.end - module.camera.bounds.position
	}
	color := Renderer.getColor(line.config.color)
	sdl3.SetRenderDrawColor(module.renderer, color.r, color.g, color.b, color.a)
	sdl3.RenderLine(module.renderer, start.x, start.y, end.x, end.y)
	return
}
