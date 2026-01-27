package PainterClient


import "../../../OdinBasePack"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "vendor:sdl3"


ModuleConfig :: struct($TAnimationName: typeid, $TShapeName: typeid) {}

Module :: struct(
	$TImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
	$TAnimationName: typeid,
)
{
	rendererModule: ^RendererClient.Module(
		TImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	allocator:      OdinBasePack.Allocator,
	config:         ModuleConfig(TAnimationName, TShapeName),
	//
	initialized:    bool,
	created:        bool,
}


@(require_results)
createModule :: proc(
	rendererModule: ^RendererClient.Module(
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	config: ModuleConfig(TAnimationName, TShapeName),
	allocator: OdinBasePack.Allocator,
) -> (
	module: Module(TImageName, TBitmapName, TMarkerName, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) {
	module.allocator = allocator
	module.config = config
	module.rendererModule = rendererModule
	return
}


@(require_results)
getShape :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	name: union {
		TShapeName,
		string,
	},
	required: bool,
) -> (
	shape: ^Renderer.Shape(TMarkerName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	shape, ok = RendererClient.getShape(module.rendererModule, name, required) or_return
	return
}

@(require_results)
registerDynamicImage :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	imageName: string,
	path: string,
) -> (
	error: OdinBasePack.Error,
) {
	RendererClient.registerDynamicImage(module.rendererModule, imageName, path) or_return
	return
}
