package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/Dictionary"
import "../../Memory/List"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "base:intrinsics"
import "vendor:sdl3"


@(require_results)
loadBitmaps :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for bitmapName, config in module.config.bitmaps {
		module.bitmapMap[bitmapName] = createBitMap(module, config) or_return
		loadBitmap(module, &module.bitmapMap[bitmapName]) or_return
	}
	return
}

@(private = "file")
@(require_results)
loadBitmap :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	bitmap: ^Renderer.Bitmap(TMarkerName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "filePath = {}", bitmap.config.filePath)
	surface := RendererClient.loadSurface(bitmap.config.filePath) or_return
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
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	bitmap: ^Renderer.Bitmap(TMarkerName),
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


@(private)
@(require_results)
createBitMap :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	config: Renderer.BitmapConfig(TMarkerName),
) -> (
	bitmap: Renderer.Bitmap(TMarkerName),
	error: OdinBasePack.Error,
) {
	bitmap.config = config
	bitmap.pixelColorListMap = Dictionary.create(
		TMarkerName,
		Renderer.PixelColorListMapElement,
		module.allocator,
	) or_return
	return
}

get :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	name: TBitmapName,
	required: bool,
) -> (
	bitmap: ^Renderer.Bitmap(TMarkerName),
	present: bool,
	error: OdinBasePack.Error,
) {
	bitmap = &module.bitmapMap[name]
	return
}

@(require_results)
findShapeMarkerMap :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	maybeBitmapName: Maybe(TBitmapName),
	bounds: Math.Rectangle,
) -> (
	markerVectorMap: map[TMarkerName]Math.Vector,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	markerVectorMap = Dictionary.create(TMarkerName, Math.Vector, module.allocator) or_return
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
