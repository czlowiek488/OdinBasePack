package UiClient

import "../../../../OdinBasePack"
import "../../../Drawer/Painter"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../Drawer/Renderer"
import "../../../Math"
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
) -> (
	bounds: Math.Rectangle,
) {
	switch value in renderConfig {
	case Painter.AnimationConfig(TAnimationName):
		bounds = value.bounds
	case Renderer.RectangleConfig:
		bounds = value.bounds
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
	color: Renderer.Color,
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
	}
	return
}
