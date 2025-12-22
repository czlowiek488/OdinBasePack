package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Animation"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
setTextureOffset :: proc(
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
	textureId: Renderer.TextureId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err := RendererClient.setTextureOffset(manager.rendererManager, textureId, offset)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
createTexture :: proc(
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
	config: Renderer.TextureConfig(TShapeName),
) -> (
	textureId: Renderer.TextureId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName)
	textureId, paint, err = RendererClient.createTexture(
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
		cast(^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName))paint,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeTexture :: proc(
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
	textureId: Renderer.TextureId,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removeTexture(manager.rendererManager, textureId)
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
getTexture :: proc(
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
	textureId: Renderer.TextureId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	result, ok, err = RendererClient.getTexture(manager.rendererManager, textureId, required)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}
