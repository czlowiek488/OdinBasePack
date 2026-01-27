package PainterClient

import "../../../OdinBasePack"
import "../../Math"
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
	error: OdinBasePack.Error,
) {
	err := RendererClient.setTextureOffset(module.rendererModule, textureId, offset)
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
	error: OdinBasePack.Error,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	paint: ^Renderer.Paint(Renderer.Texture(TShapeName), TShapeName)
	textureId, paint = RendererClient.createTexture(
		module.rendererModule,
		metaConfig,
		config,
	) or_return
	trackEntity(
		module,
		cast(^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName))paint,
	) or_return
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
	error: OdinBasePack.Error,
) {
	paint := RendererClient.removeTexture(module.rendererModule, textureId) or_return
	unTrackEntity(module, &paint) or_return
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
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	result, ok = RendererClient.getTexture(module.rendererModule, textureId, required) or_return
	return
}
