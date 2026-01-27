package UiClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Painter"
import PainterClient "../../../Painter/Client"
import "../../../Renderer"
import "../../Ui"

@(private)
@(require_results)
getBoundsFromTileRenderConfig :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	renderConfig: Ui.RenderConfig(TAnimationName),
	offset: Math.Vector,
) -> (
	geometry: Math.Geometry,
	scaledGeometry: Math.Geometry,
) {
	switch value in renderConfig {
	case Painter.AnimationConfig(TAnimationName):
		rectangle: Math.Rectangle = {value.bounds.position + offset, value.bounds.size}
		geometry = rectangle
		scaledRectangle := Math.scaleBounds(rectangle, module.tileScale, {0, 0})
		scaledRectangle.size -= 1
		scaledGeometry = scaledRectangle
	case Renderer.RectangleConfig:
		rectangle: Math.Rectangle = {value.bounds.position + offset, value.bounds.size}
		geometry = rectangle
		scaledRectangle := Math.scaleBounds(rectangle, module.tileScale, {0, 0})
		scaledRectangle.size -= 1
		scaledGeometry = scaledRectangle
	case Renderer.CircleConfig:
		circle: Math.Circle = {value.circle.position + offset, value.circle.radius}
		geometry = circle
		scaledCircle := Math.scaleCircle(circle, module.tileScale, {0, 0})
		scaledCircle.radius -= 1
		scaledGeometry = scaledCircle
	}
	return
}

@(private)
@(require_results)
setPainterRender :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	config: Ui.CameraTileConfig(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
) -> (
	painterRenderId: Ui.PainterRenderId,
	color: Renderer.ColorDefinition,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	color = config.metaConfig.color
	switch value in config.renderConfig {
	case Painter.AnimationConfig(TAnimationName):
		animationId := PainterClient.setAnimation(module.painterModule, value) or_return
		painterRenderId = Ui.PainterRenderId(animationId)
	case Renderer.RectangleConfig:
		rectangleId := PainterClient.createRectangle(
			module.painterModule,
			config.metaConfig,
			value,
		) or_return
		painterRenderId = Ui.PainterRenderId(rectangleId)
	case Renderer.CircleConfig:
		circleId := PainterClient.createCircle(
			module.painterModule,
			config.metaConfig,
			value,
		) or_return
		painterRenderId = Ui.PainterRenderId(circleId)
	}
	return
}

@(private)
@(require_results)
unsetPainterRender :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
) -> (
	error: TError,
) {
	switch value in tile.config.renderConfig {
	case Painter.AnimationConfig(TAnimationName):
		PainterClient.removeAnimation(
			module.painterModule,
			Painter.AnimationId(tile.painterRenderId),
		) or_return
	case Renderer.RectangleConfig:
		PainterClient.removeRectangle(
			module.painterModule,
			Painter.RectangleId(tile.painterRenderId),
		) or_return
	case Renderer.CircleConfig:
		PainterClient.removeCircle(
			module.painterModule,
			Painter.CircleId(tile.painterRenderId),
		) or_return
	}
	return
}
