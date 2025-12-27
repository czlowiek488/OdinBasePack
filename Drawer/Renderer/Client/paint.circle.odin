package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import "core:math"
import "vendor:sdl3"

@(require_results)
createCircle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.CircleConfig,
) -> (
	circleId: Renderer.CircleId,
	paint: ^Renderer.Paint(Renderer.Circle, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId: Renderer.PaintId
	paintId, paint = createPaint(module, metaConfig, Renderer.Circle{0, config}) or_return
	circleId = Renderer.CircleId(paintId)
	return
}

@(require_results)
setCircleOffset :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	circleId: Renderer.CircleId,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	meta, _ := getPaint(module, circleId, Renderer.Circle, true) or_return
	meta.offset = offset
	return
}

@(require_results)
getLeftTopCircleCorner :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	circle: ^Renderer.Paint(Renderer.Circle, TShapeName),
) -> (
	leftTopCorner: Math.Vector,
) {
	return
}

@(require_results)
drawCircle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	circle: ^Renderer.Paint(Renderer.Circle, TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	sdl3.SetRenderDrawColor(
		module.renderer,
		circle.config.color.r,
		circle.config.color.g,
		circle.config.color.b,
		circle.config.color.a,
	)
	segments := 64
	max_angle := (1.0 - circle.element.config.limit) * 2.0 * f32(math.PI)
	offset_angle := circle.element.config.rotation * 2.0 * f32(math.PI)
	angle_step := max_angle / f32(segments)
	destination: Math.Vector
	switch circle.config.positionType {
	case .CAMERA:
		destination = circle.element.config.circle.position + circle.offset
	case .MAP:
		destination =
			circle.element.config.circle.position + circle.offset - module.camera.bounds.position
	}
	circle.leftTopCorner = destination - circle.element.config.circle.radius
	for i in 0 ..< segments {
		angle1 := offset_angle + angle_step * f32(i)
		angle2 := offset_angle + angle_step * f32(i + 1)

		x1 := destination.x + (circle.element.config.circle.radius * math.cos(angle1))
		y1 := destination.y + (circle.element.config.circle.radius * math.sin(angle1))
		x2 := destination.x + (circle.element.config.circle.radius * math.cos(angle2))
		y2 := destination.y + (circle.element.config.circle.radius * math.sin(angle2))

		sdl3.RenderLine(module.renderer, x1, y1, x2, y2)
	}
	return
}


@(require_results)
removeCircle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	circleId: Renderer.CircleId,
) -> (
	paint: Renderer.Paint(Renderer.Circle, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "circleId = {}", circleId)
	paint = removePaint(module, circleId, Renderer.Circle) or_return
	return
}


@(require_results)
getCircle :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	circleId: Renderer.CircleId,
	required: bool,
) -> (
	meta: ^Renderer.Paint(Renderer.Circle, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "circleId = {}", circleId)
	meta, ok = getPaint(module, circleId, Renderer.Circle, required) or_return
	return
}
