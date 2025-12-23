package UiClient

import "../../../OdinBasePack"
import "../../Drawer/Painter"
import PainterClient "../../Drawer/Painter/Client"
import "../../Drawer/Renderer"
import "../../Math"
import "../../Ui"

@(private)
@(require_results)
getBoundsFromTileRenderConfig :: proc(
	manager: ^Manager(
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
	manager: ^Manager(
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
		animationId := PainterClient.setAnimation(manager.painterManager, value) or_return
		painterRenderId = Ui.PainterRenderId(animationId)
	case Renderer.RectangleConfig:
		rectangleId := PainterClient.createRectangle(
			manager.painterManager,
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
	manager: ^Manager(
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
			manager.painterManager,
			Painter.AnimationId(tile.painterRenderId),
		) or_return
	case Renderer.RectangleConfig:
		PainterClient.removeRectangle(
			manager.painterManager,
			Painter.RectangleId(tile.painterRenderId),
		) or_return
	}
	return
}
