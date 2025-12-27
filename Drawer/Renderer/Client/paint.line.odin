package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import "vendor:sdl3"

@(require_results)
createLine :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.LineConfig,
) -> (
	lineId: Renderer.LineId,
	paint: ^Renderer.Paint(Renderer.Line, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId: Renderer.PaintId
	paintId, paint = createPaint(module, metaConfig, Renderer.Line{0, config}) or_return
	lineId = Renderer.LineId(paintId)
	return
}

@(require_results)
getLine :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	lineId: Renderer.LineId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Line, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = getPaint(module, lineId, Renderer.Line, required) or_return
	return
}


@(require_results)
removeLine :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	lineId: Renderer.LineId,
) -> (
	paint: Renderer.Paint(Renderer.Line, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint = removePaint(module, lineId, Renderer.Line) or_return
	return
}

@(require_results)
drawLine :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	line: ^Renderer.Paint(Renderer.Line, TShapeName),
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
	if start.y < end.y {
		setTopLeftCorner(module, line.paintId, line.config.layer, start) or_return
	} else if start.y > end.y {
		setTopLeftCorner(module, line.paintId, line.config.layer, end) or_return
	} else {
		if start.x < end.x {
			setTopLeftCorner(module, line.paintId, line.config.layer, start) or_return
		} else {
			setTopLeftCorner(module, line.paintId, line.config.layer, end) or_return
		}
	}
	sdl3.SetRenderDrawColor(
		module.renderer,
		line.config.color.r,
		line.config.color.g,
		line.config.color.b,
		line.config.color.a,
	)
	sdl3.RenderLine(module.renderer, start.x, start.y, end.x, end.y)
	return
}
