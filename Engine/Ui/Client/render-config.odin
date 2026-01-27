package UiClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Renderer"
import RendererClient "../../../Renderer/Client"
import "../../Ui"

@(private)
@(require_results)
getBoundsFromTileRenderConfig :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
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
	case Renderer.AnimationConfig(TAnimationName):
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
		$TImageName,
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
	case Renderer.AnimationConfig(TAnimationName):
		animationId: Renderer.AnimationId
		animationId, err = RendererClient.setAnimation(module.rendererModule, value)
		module.eventLoop.mapper(err) or_return
		painterRenderId = Ui.PainterRenderId(animationId)
	case Renderer.RectangleConfig:
		rectangleId, err := RendererClient.createRectangle(
			module.rendererModule,
			config.metaConfig,
			value,
		)
		module.eventLoop.mapper(err) or_return
		painterRenderId = Ui.PainterRenderId(rectangleId)
	case Renderer.CircleConfig:
		circleId, err := RendererClient.createCircle(
			module.rendererModule,
			config.metaConfig,
			value,
		)
		module.eventLoop.mapper(err) or_return
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
		$TImageName,
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
	case Renderer.AnimationConfig(TAnimationName):
		err := RendererClient.removeAnimation(
			module.rendererModule,
			Renderer.AnimationId(tile.painterRenderId),
		)
		module.eventLoop.mapper(err) or_return
	case Renderer.RectangleConfig:
		err := RendererClient.removeRectangle(
			module.rendererModule,
			Renderer.RectangleId(tile.painterRenderId),
		)
		module.eventLoop.mapper(err) or_return
	case Renderer.CircleConfig:
		err := RendererClient.removeCircle(
			module.rendererModule,
			Renderer.CircleId(tile.painterRenderId),
		)
		module.eventLoop.mapper(err) or_return
	}
	return
}
