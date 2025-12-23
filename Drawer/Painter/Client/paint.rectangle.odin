package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "vendor:sdl3"


@(require_results)
createRectangle :: proc(
	module: ^Module(
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
	paint: ^Renderer.Paint(Renderer.Rectangle, TShapeName)
	rectangleId, paint, err = RendererClient.createRectangle(
		module.rendererModule,
		metaConfig,
		config,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = trackEntity(
		module,
		cast(^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName))paint,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
getRectangle :: proc(
	module: ^Module(
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
	result: ^Renderer.Paint(Renderer.Rectangle, TShapeName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err, "rectangleId = {}", rectangleId)
	result, ok, err = RendererClient.getRectangle(module.rendererModule, rectangleId, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeRectangle :: proc(
	module: ^Module(
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
	paint, err := RendererClient.removeRectangle(module.rendererModule, rectangleId)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = unTrackEntity(module, &paint)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
setRectangleOffset :: proc(
	module: ^Module(
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
	err = RendererClient.setRectangleOffset(module.rendererModule, rectangleId, offset)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
