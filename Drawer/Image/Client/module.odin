package ImageClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/Dictionary"
import "../../Image"
import "base:intrinsics"
import "vendor:sdl3"

ModuleConfig :: struct #all_or_none {
	measureLoading: bool,
	tileScale:      f32,
	tileSize:       Math.Vector,
	windowSize:     Math.Vector,
}
Module :: struct($TFileImageName: typeid) where intrinsics.type_is_enum(TFileImageName) {
	config:          ModuleConfig,
	allocator:       OdinBasePack.Allocator,
	//
	renderer:        ^sdl3.Renderer,
	imageMap:        map[TFileImageName]Image.DynamicImage,
	dynamicImageMap: map[string]Image.DynamicImage,
	imageConfig:     map[TFileImageName]Image.ImageFileConfig,
}

@(require_results)
createModule :: proc(
	config: ModuleConfig,
	allocator: OdinBasePack.Allocator,
	imageConfig: map[$TFileImageName]Image.ImageFileConfig,
) -> (
	module: Module(TFileImageName),
	error: OdinBasePack.Error,
) {
	module.config = config
	module.imageConfig = imageConfig
	module.allocator = allocator
	module.dynamicImageMap = Dictionary.create(
		string,
		Image.DynamicImage,
		module.allocator,
	) or_return
	module.imageMap = Dictionary.create(
		TFileImageName,
		Image.DynamicImage,
		module.allocator,
	) or_return
	for imageName, config in module.imageConfig {
		Dictionary.set(
			&module.imageMap,
			imageName,
			Image.DynamicImage{nil, config.filePath},
		) or_return
	}
	return
}

@(require_results)
initializeModule :: proc(
	module: ^Module($TFileImageName),
	renderer: ^sdl3.Renderer,
) -> (
	error: OdinBasePack.Error,
) {
	module.renderer = renderer
	return
}
