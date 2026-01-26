package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
setTextureOffset :: proc(
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
	textureId: Renderer.TextureId,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err := RendererClient.setTextureOffset(module.rendererModule, textureId, offset)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
createTexture :: proc(
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
	config: Renderer.TextureConfig(TShapeName),
) -> (
	textureId: Renderer.TextureId,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName)
	textureId, paint, err = RendererClient.createTexture(module.rendererModule, metaConfig, config)
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
removeTexture :: proc(
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
	textureId: Renderer.TextureId,
) -> (
	error: TError,
) {
	paint, err := RendererClient.removeTexture(module.rendererModule, textureId)
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
getTexture :: proc(
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
	textureId: Renderer.TextureId,
	required: bool,
) -> (
	result: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	result, ok, err = RendererClient.getTexture(module.rendererModule, textureId, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
