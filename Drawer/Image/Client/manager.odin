package ImageClient

import "../../../../OdinBasePack"
import "../../../Dictionary"
import "../../../Math"
import "../../Image"
import "base:intrinsics"
import "vendor:sdl3"

ManagerConfig :: struct #all_or_none {
	measureLoading: bool,
	tileScale:      f32,
	tileSize:       Math.Vector,
	windowSize:     Math.Vector,
}
Manager :: struct($TFileImageName: typeid) where intrinsics.type_is_enum(TFileImageName) {
	config:          ManagerConfig,
	allocator:       OdinBasePack.Allocator,
	//
	renderer:        ^sdl3.Renderer,
	imageMap:        map[TFileImageName]Image.DynamicImage,
	dynamicImageMap: map[string]Image.DynamicImage,
	imageConfig:     map[TFileImageName]Image.ImageFileConfig,
}

@(require_results)
createManager :: proc(
	config: ManagerConfig,
	allocator: OdinBasePack.Allocator,
	imageConfig: map[$TFileImageName]Image.ImageFileConfig,
) -> (
	manager: Manager(TFileImageName),
	error: OdinBasePack.Error,
) {
	manager.config = config
	manager.imageConfig = imageConfig
	manager.allocator = allocator
	manager.dynamicImageMap = Dictionary.create(
		string,
		Image.DynamicImage,
		manager.allocator,
	) or_return
	manager.imageMap = Dictionary.create(
		TFileImageName,
		Image.DynamicImage,
		manager.allocator,
	) or_return
	for imageName, config in manager.imageConfig {
		Dictionary.set(
			&manager.imageMap,
			imageName,
			Image.DynamicImage{nil, config.filePath},
		) or_return
	}
	return
}

@(require_results)
initializeManager :: proc(
	manager: ^Manager($TFileImageName),
	renderer: ^sdl3.Renderer,
) -> (
	error: OdinBasePack.Error,
) {
	manager.renderer = renderer
	return
}
