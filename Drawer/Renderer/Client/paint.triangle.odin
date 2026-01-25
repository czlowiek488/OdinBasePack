package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import "vendor:sdl3"

@(require_results)
createTriangle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.TriangleConfig,
) -> (
	triangleId: Renderer.TriangleId,
	paint: ^Renderer.Paint(Renderer.Triangle, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId: Renderer.PaintId
	paintId, paint = createPaint(module, metaConfig, Renderer.Triangle{0, config}) or_return
	triangleId = Renderer.TriangleId(paintId)
	return
}


@(require_results)
getTriangle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	triangleId: Renderer.TriangleId,
	required: bool,
) -> (
	meta: ^Renderer.Paint(Renderer.Triangle, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "triangleId = {}", triangleId)
	meta, ok = getPaint(module, triangleId, Renderer.Triangle, required) or_return
	return
}

@(require_results)
removeTriangle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	triangleId: Renderer.TriangleId,
) -> (
	paintCopy: Renderer.Paint(Renderer.Triangle, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintCopy = removePaint(module, triangleId, Renderer.Triangle) or_return
	return
}


@(require_results)
drawTriangle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	triangle: ^Renderer.Paint(Renderer.Triangle, TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	a, b, c: Math.Vector
	switch triangle.config.positionType {
	case .CAMERA:
		a = triangle.element.config.triangle.a + triangle.offset
		b = triangle.element.config.triangle.b + triangle.offset
		c = triangle.element.config.triangle.c + triangle.offset
	case .MAP:
		a = triangle.element.config.triangle.a + triangle.offset - module.camera.bounds.position
		b = triangle.element.config.triangle.b + triangle.offset - module.camera.bounds.position
		c = triangle.element.config.triangle.c + triangle.offset - module.camera.bounds.position
	}
	leftTopCorner := a
	if b.y < leftTopCorner.y || (b.y == leftTopCorner.y && b.x < leftTopCorner.x) {
		leftTopCorner = b
	}
	if c.y < leftTopCorner.y || (c.y == leftTopCorner.y && c.x < leftTopCorner.x) {
		leftTopCorner = c
	}
	updateRenderOrderPosition(module, triangle.paintId, leftTopCorner) or_return
	color := Renderer.getColor(triangle.config.color)
	sdl3.SetRenderDrawColor(module.renderer, color.r, color.g, color.b, color.a)
	sdl3.RenderLine(module.renderer, a.x, a.y, b.x, b.y)
	sdl3.RenderLine(module.renderer, b.x, b.y, c.x, c.y)
	sdl3.RenderLine(module.renderer, c.x, c.y, a.x, a.y)
	return
}

@(require_results)
setTriangleOffset :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	triangleId: Renderer.TriangleId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getTriangle(module, triangleId, true) or_return
	meta.offset = offset
	return
}
