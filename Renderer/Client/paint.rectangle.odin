package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Renderer"
import "vendor:sdl3"


@(require_results)
createRectangle :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.RectangleConfig,
) -> (
	rectangleId: Renderer.RectangleId,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	drawBounds: Math.Rectangle
	switch config.type {
	case .BORDER:
		drawBounds = {config.bounds.position, config.bounds.size - 1}
	case .FILL:
		drawBounds = config.bounds
	}
	paintId, paint := createPaint(
		module,
		metaConfig,
		Renderer.Rectangle{0, drawBounds, config},
	) or_return
	rectangleId = Renderer.RectangleId(paintId)
	trackEntity(
		module,
		cast(^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName))paint,
	) or_return
	return
}

@(require_results)
getRectangle :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName),
	rectangleId: Renderer.RectangleId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Rectangle, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "rectangleId = {}", rectangleId)
	result, ok = getPaint(module, rectangleId, Renderer.Rectangle, required) or_return
	return
}

@(require_results)
removeRectangle :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName),
	rectangleId: Renderer.RectangleId,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint := removePaint(module, rectangleId, Renderer.Rectangle) or_return
	unTrackEntity(module, &paint) or_return
	return
}

@(require_results)
setRectangleOffset :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName),
	rectangleId: Renderer.RectangleId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getRectangle(module, rectangleId, true) or_return
	meta.offset = offset
	return
}

@(require_results)
drawRectangle :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName),
	rectangle: ^Renderer.Paint(Renderer.Rectangle, TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	color := Renderer.getColor(rectangle.config.color)
	sdl3.SetRenderDrawColor(module.renderer, color.r, color.g, color.b, color.a)
	destination: Math.Vector
	switch rectangle.config.positionType {
	case .CAMERA:
		destination = rectangle.element.config.bounds.position + rectangle.offset
	case .MAP:
		destination =
			rectangle.element.config.bounds.position +
			rectangle.offset -
			module.camera.bounds.position
	}
	bounds: sdl3.FRect = {
		destination.x,
		destination.y,
		rectangle.element.config.bounds.size.x,
		rectangle.element.config.bounds.size.y,
	}
	switch rectangle.element.config.type {
	case .BORDER:
		sdl3.RenderRect(module.renderer, &bounds)
	case .FILL:
		sdl3.RenderFillRect(module.renderer, &bounds)
	}
	return
}
