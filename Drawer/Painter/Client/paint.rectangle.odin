package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "vendor:sdl3"


@(require_results)
createRectangle :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.RectangleConfig,
) -> (
	rectangleId: Renderer.RectangleId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(Renderer.Rectangle, TShapeName, TAnimationName)
	rectangleId, paint, err = RendererClient.createRectangle(
		manager.rendererManager,
		metaConfig,
		config,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = trackEntity(
		manager,
		cast(^Renderer.Paint(
			Renderer.PaintData(TShapeName, TAnimationName),
			TShapeName,
			TAnimationName,
		))paint,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
getRectangle :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	rectangleId: Renderer.RectangleId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Rectangle, TShapeName, TAnimationName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "rectangleId = {}", rectangleId)
	result, ok, err = RendererClient.getRectangle(manager.rendererManager, rectangleId, required)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeRectangle :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	rectangleId: Renderer.RectangleId,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removeRectangle(manager.rendererManager, rectangleId)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = unTrackEntity(manager, &paint)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
setRectangleOffset :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	rectangleId: Renderer.RectangleId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	err = RendererClient.setRectangleOffset(manager.rendererManager, rectangleId, offset)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}
