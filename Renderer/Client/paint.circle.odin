package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Renderer"
import "core:math"
import "vendor:sdl3"

@(require_results)
createCircle :: proc(
	module: ^Module,
	metaConfig: Renderer.MetaConfig,
	config: Renderer.CircleConfig,
) -> (
	circleId: Renderer.CircleId,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId, paint := createPaint(module, metaConfig, Renderer.Circle{0, config}) or_return
	circleId = Renderer.CircleId(paintId)
	trackEntity(module, cast(^Renderer.Paint(Renderer.PaintData))paint) or_return
	return
}

@(require_results)
setCircleOffset :: proc(
	module: ^Module,
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
drawCircle :: proc(
	module: ^Module,
	circle: ^Renderer.Paint(Renderer.Circle),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	color := Renderer.getColor(circle.config.color)
	sdl3.SetRenderDrawColor(module.renderer, color.r, color.g, color.b, color.a)
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
	switch circle.element.config.type {
	case .FILL:
		y := -circle.element.config.circle.radius
		for y <= circle.element.config.circle.radius {
			x := math.sqrt(
				(circle.element.config.circle.radius * circle.element.config.circle.radius) -
				(y * y),
			)
			sdl3.RenderLine(
				module.renderer,
				destination.x - x,
				destination.y + y,
				destination.x + x,
				destination.y + y,
			)
			y += 1.0
		}
	case .BORDER:
		for i in 0 ..< segments {
			angle1 := offset_angle + angle_step * f32(i)
			angle2 := offset_angle + angle_step * f32(i + 1)

			x1 := destination.x + (circle.element.config.circle.radius * math.cos(angle1))
			y1 := destination.y + (circle.element.config.circle.radius * math.sin(angle1))
			x2 := destination.x + (circle.element.config.circle.radius * math.cos(angle2))
			y2 := destination.y + (circle.element.config.circle.radius * math.sin(angle2))

			sdl3.RenderLine(module.renderer, x1, y1, x2, y2)
		}
	}
	return
}


@(require_results)
removeCircle :: proc(module: ^Module, circleId: Renderer.CircleId) -> (error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error, "circleId = {}", circleId)
	paint := removePaint(module, circleId, Renderer.Circle) or_return
	unTrackEntity(module, &paint) or_return
	return
}


@(require_results)
getCircle :: proc(
	module: ^Module,
	circleId: Renderer.CircleId,
	required: bool,
) -> (
	meta: ^Renderer.Paint(Renderer.Circle),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "circleId = {}", circleId)
	meta, ok = getPaint(module, circleId, Renderer.Circle, required) or_return
	return
}
