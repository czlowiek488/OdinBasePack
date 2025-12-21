package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import "vendor:sdl3"

@(require_results)
createLine :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.LineConfig,
) -> (
	lineId: Renderer.LineId,
	paint: ^Renderer.Paint(Renderer.Line, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId: Renderer.PaintId
	paintId, paint = createPaint(manager, metaConfig, Renderer.Line{0, config}) or_return
	lineId = Renderer.LineId(paintId)
	return
}

@(require_results)
getLine :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	lineId: Renderer.LineId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Line, TShapeName, TAnimationName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = getPaint(manager, lineId, Renderer.Line, required) or_return
	return
}


@(require_results)
removeLine :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	lineId: Renderer.LineId,
) -> (
	paint: Renderer.Paint(Renderer.Line, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint = removePaint(manager, lineId, Renderer.Line) or_return
	return
}

@(require_results)
drawLine :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	line: ^Renderer.Paint(Renderer.Line, TShapeName, TAnimationName),
) -> (
	error: OdinBasePack.Error,
) {
	start, end: Math.Vector
	switch line.config.positionType {
	case .CAMERA:
		start = line.element.config.start
		end = line.element.config.end
	case .MAP:
		start = line.element.config.start - manager.camera.bounds.position
		end = line.element.config.end - manager.camera.bounds.position
	}
	sdl3.SetRenderDrawColor(
		manager.renderer,
		line.config.color.r,
		line.config.color.g,
		line.config.color.b,
		line.config.color.a,
	)
	sdl3.RenderLine(manager.renderer, start.x, start.y, end.x, end.y)
	return
}
