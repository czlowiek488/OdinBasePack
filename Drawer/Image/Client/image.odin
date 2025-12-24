package ImageClient

import "../../../../OdinBasePack"
import "../../../Memory/Dictionary"
import "../../Image"
import "core:fmt"
import "vendor:sdl3"
import "vendor:sdl3/image"

@(private)
@(require_results)
loadImageMap :: proc(
	module: ^Module($TFileImageName),
) -> (
	imageMap: map[TFileImageName]Image.DynamicImage,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for name, path in imageConfigMap {
		Dictionary.set(&imageMap, name, loadImageFile(module, path) or_return) or_return
	}
	return
}


@(require_results)
loadSurface :: proc(texturePath: string) -> (surface: ^sdl3.Surface, error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	texturePath := fmt.caprintf("{}", texturePath, allocator = context.temp_allocator)
	fileIo := sdl3.IOFromFile(texturePath, "r")
	surface = image.LoadPNG_IO(fileIo)
	if surface == nil {
		error = .FAILED_LOAD_BMP_FILE
		return
	}
	return
}

@(private)
@(require_results)
loadImageFile :: proc(
	module: ^Module,
	config: Image.ImageFileConfig,
) -> (
	image: Image.DynamicImage,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "filePath = {}", config.filePath)
	surface := loadSurface(config.filePath) or_return
	defer sdl3.DestroySurface(surface)
	image.texture = sdl3.CreateTextureFromSurface(module.renderer, surface)
	if image.texture == nil {
		error = .FAILED_CREATION_TEXTURE_FROM_SURFACE
		return
	}
	sdl3.SetTextureScaleMode(image.texture, config.scaleMode)
	image.path = config.filePath
	return
}
