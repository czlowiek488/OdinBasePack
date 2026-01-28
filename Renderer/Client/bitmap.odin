package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/Dictionary"
import "../../Memory/List"
import "../../Renderer"
import "base:intrinsics"
import "vendor:sdl3"

@(require_results)
registerBitmap :: proc(
	module: ^Module($TImageName),
	bitmapName: int,
	config: Renderer.BitmapConfig,
) -> (
	error: OdinBasePack.Error,
) {
	module.bitmapMap[bitmapName] = {
		config,
		Dictionary.create(int, Renderer.PixelColorListMapElement, module.allocator) or_return,
	}
	bitmap := &module.bitmapMap[bitmapName]
	defer OdinBasePack.handleError(error, "filePath = {}", bitmap.config.filePath)
	surface := loadSurface(bitmap.config.filePath) or_return
	defer sdl3.DestroySurface(surface)
	mustLock := sdl3.MUSTLOCK(surface)
	if mustLock {
		sdl3.LockSurface(surface)
	}
	formatDetails := sdl3.GetPixelFormatDetails(surface.format)
	colorPallette := sdl3.GetSurfacePalette(surface)
	defer sdl3.DestroyPalette(colorPallette)
	for y in 0 ..< surface.h {
		for x in 0 ..< surface.w {
			pixel_addr: uintptr =
				uintptr(surface.pixels) +
				uintptr(y) * uintptr(surface.pitch) +
				uintptr(x) * uintptr(formatDetails.bytes_per_pixel)
			pixel_value := (cast(^u32)pixel_addr)^
			if pixel_value == 0 {
				continue
			}
			r, g, b, a: u8
			sdl3.GetRGBA(pixel_value, formatDetails, colorPallette, &r, &g, &b, &a)
			loadPixelToBitmap(module, bitmap, {r, g, b, a}, {f32(x), f32(y)}) or_return
		}
	}
	if mustLock {
		sdl3.UnlockSurface(surface)
	}
	return
}


@(private = "file")
@(require_results)
loadPixelToBitmap :: proc(
	module: ^Module($TImageName),
	bitmap: ^Renderer.Bitmap,
	color: sdl3.Color,
	position: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "color = {}, position = {}", color, position)
	enumValue, enumExists := bitmap.config.enumColorMap[color]
	if !enumExists {
		error = .BITMAP_INVALID_COLOR_IN_BITMAP
		return
	}
	_, exists := &bitmap.pixelColorListMap[enumValue]
	if !exists {
		Dictionary.set(
			&bitmap.pixelColorListMap,
			enumValue,
			List.create(Math.Vector, module.allocator) or_return,
		) or_return
	}
	List.push(&bitmap.pixelColorListMap[enumValue], position) or_return
	return
}


get :: proc(
	module: ^Module($TImageName),
	name: int,
	required: bool,
) -> (
	bitmap: ^Renderer.Bitmap,
	present: bool,
	error: OdinBasePack.Error,
) {
	bitmap = &module.bitmapMap[name]
	return
}

@(require_results)
findShapeMarkerMap :: proc(
	module: ^Module($TImageName),
	maybeBitmapName: Maybe(int),
	bounds: Math.Rectangle,
) -> (
	markerVectorMap: map[int]Math.Vector,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	markerVectorMap = Dictionary.create(int, Math.Vector, module.allocator) or_return
	bitmapName, ok := maybeBitmapName.?
	if !ok {
		return
	}
	for id, vectorList in module.bitmapMap[bitmapName].pixelColorListMap {
		for vector in vectorList {
			if Math.isPointCollidingWithRectangle(bounds, vector) {
				_, markerExists := markerVectorMap[id]
				if markerExists {
					error = .BITMAP_DUPLICATED_MARKER
					return
				}
				Dictionary.set(&markerVectorMap, id, vector - bounds.position) or_return
			}
		}
	}
	return
}
