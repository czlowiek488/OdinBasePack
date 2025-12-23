package PainterClient

import "../../../../OdinBasePack"
import RendererClient "../../Renderer/Client"
import "../../Shape"
import "vendor:sdl3"

@(require_results)
loadSurfaceFromShape :: proc(
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
	shape: ^Shape.Shape(TMarkerName),
) -> (
	surface: ^sdl3.Surface,
	error: OdinBasePack.Error,
) {
	surface = RendererClient.loadSurfaceFromShape(module.rendererModule, shape) or_return
	return
}
