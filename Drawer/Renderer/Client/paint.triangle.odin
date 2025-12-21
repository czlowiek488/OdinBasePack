package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import "vendor:sdl3"

@(require_results)
createTriangle :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.TriangleConfig,
) -> (
	triangleId: Renderer.TriangleId,
	paint: ^Renderer.Paint(Renderer.Triangle, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId: Renderer.PaintId
	paintId, paint = createPaint(manager, metaConfig, Renderer.Triangle{0, config}) or_return
	triangleId = Renderer.TriangleId(paintId)
	return
}


@(require_results)
getTriangle :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	triangleId: Renderer.TriangleId,
	required: bool,
) -> (
	meta: ^Renderer.Paint(Renderer.Triangle, TShapeName, TAnimationName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "triangleId = {}", triangleId)
	meta, ok = getPaint(manager, triangleId, Renderer.Triangle, required) or_return
	return
}

@(require_results)
removeTriangle :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	triangleId: Renderer.TriangleId,
) -> (
	paintCopy: Renderer.Paint(Renderer.Triangle, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintCopy = removePaint(manager, triangleId, Renderer.Triangle) or_return
	return
}

@(require_results)
drawTriangle :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	triangle: ^Renderer.Paint(Renderer.Triangle, TShapeName, TAnimationName),
) -> (
	error: OdinBasePack.Error,
) {
	sdl3.SetRenderDrawColor(
		manager.renderer,
		triangle.config.color.r,
		triangle.config.color.g,
		triangle.config.color.b,
		triangle.config.color.a,
	)
	a := triangle.element.config.triangle.a + triangle.offset - manager.camera.bounds.position
	b := triangle.element.config.triangle.b + triangle.offset - manager.camera.bounds.position
	c := triangle.element.config.triangle.c + triangle.offset - manager.camera.bounds.position
	sdl3.RenderLine(manager.renderer, a.x, a.y, b.x, b.y)
	sdl3.RenderLine(manager.renderer, b.x, b.y, c.x, c.y)
	sdl3.RenderLine(manager.renderer, c.x, c.y, a.x, a.y)
	return
}

@(require_results)
setTriangleOffset :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	triangleId: Renderer.TriangleId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getTriangle(manager, triangleId, true) or_return
	meta.offset = offset
	return
}
