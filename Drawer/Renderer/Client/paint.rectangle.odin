package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import "vendor:sdl3"


@(require_results)
createRectangle :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.RectangleConfig,
) -> (
	rectangleId: Renderer.RectangleId,
	paint: ^Renderer.Paint(Renderer.Rectangle, TShapeName, TAnimationName),
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
	paintId: Renderer.PaintId
	paintId, paint = createPaint(
		manager,
		metaConfig,
		Renderer.Rectangle{0, drawBounds, config},
	) or_return
	rectangleId = Renderer.RectangleId(paintId)
	return
}

@(require_results)
getRectangle :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	rectangleId: Renderer.RectangleId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Rectangle, TShapeName, TAnimationName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "rectangleId = {}", rectangleId)
	result, ok = getPaint(manager, rectangleId, Renderer.Rectangle, required) or_return
	return
}

@(require_results)
removeRectangle :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	rectangleId: Renderer.RectangleId,
) -> (
	paint: Renderer.Paint(Renderer.Rectangle, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paint = removePaint(manager, rectangleId, Renderer.Rectangle) or_return
	return
}

@(require_results)
setRectangleOffset :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	rectangleId: Renderer.RectangleId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getRectangle(manager, rectangleId, true) or_return
	meta.offset = offset
	return
}

@(require_results)
drawRectangle :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	rectangle: ^Renderer.Paint(Renderer.Rectangle, TShapeName, TAnimationName),
) -> (
	error: OdinBasePack.Error,
) {
	sdl3.SetRenderDrawColor(
		manager.renderer,
		rectangle.config.color.r,
		rectangle.config.color.g,
		rectangle.config.color.b,
		rectangle.config.color.a,
	)
	destination: Math.Vector
	switch rectangle.config.positionType {
	case .CAMERA:
		destination = rectangle.element.config.bounds.position + rectangle.offset
	case .MAP:
		destination =
			rectangle.element.config.bounds.position +
			rectangle.offset -
			manager.camera.bounds.position
	}
	bounds: sdl3.FRect = {
		destination.x,
		destination.y,
		rectangle.element.config.bounds.size.x,
		rectangle.element.config.bounds.size.y,
	}
	switch rectangle.element.config.type {
	case .BORDER:
		sdl3.RenderRect(manager.renderer, &bounds)
	case .FILL:
		sdl3.RenderFillRect(manager.renderer, &bounds)
	}
	return
}
