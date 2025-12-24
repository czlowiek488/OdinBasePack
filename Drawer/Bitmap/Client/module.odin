package BitmapClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/Dictionary"
import "../../../Memory/List"
import "../../Bitmap"
import ImageClient "../../Image/Client"
import "base:intrinsics"
import "vendor:sdl3"

Module :: struct(
	$TBitmapName: typeid,
	$TMarkerName: typeid,
) where intrinsics.type_is_enum(TBitmapName) &&
	intrinsics.type_is_enum(TMarkerName)
{
	bitmapMap: [TBitmapName]Bitmap.Bitmap(TMarkerName),
	config:    map[TBitmapName]Bitmap.BitmapConfig(TMarkerName),
	allocator: OdinBasePack.Allocator,
}


@(require_results)
createModule :: proc(
	config: map[$TBitmapName]Bitmap.BitmapConfig($TMarkerName),
	allocator: OdinBasePack.Allocator,
) -> (
	module: Module(TBitmapName, TMarkerName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	module.allocator = allocator
	module.config = config
	return
}

@(require_results)
initializeModule :: proc(
	module: ^Module($TBitmapName, $TMarkerName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for bitmapName, config in module.config {
		module.bitmapMap[bitmapName] = create(module, config) or_return
		loadBitmap(module, &module.bitmapMap[bitmapName]) or_return
	}
	return
}

@(private = "file")
@(require_results)
loadBitmap :: proc(
	module: ^Module($TBitmapName, $TMarkerName),
	bitmap: ^Bitmap.Bitmap(TMarkerName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "filePath = {}", bitmap.config.filePath)
	surface := ImageClient.loadSurface(bitmap.config.filePath) or_return
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
	module: ^Module($TBitmapName, $TMarkerName),
	bitmap: ^Bitmap.Bitmap(TMarkerName),
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
create :: proc(
	module: ^Module($TBitmapName, $TMarkerName),
	config: Bitmap.BitmapConfig(TMarkerName),
) -> (
	bitmap: Bitmap.Bitmap(TMarkerName),
	error: OdinBasePack.Error,
) {
	bitmap.config = config
	bitmap.pixelColorListMap = Dictionary.create(
		TMarkerName,
		Bitmap.PixelColorListMapElement,
		module.allocator,
	) or_return
	return
}

get :: proc(
	module: ^Module($TBitmapName, $TMarkerName),
	name: TBitmapName,
	required: bool,
) -> (
	bitmap: ^Bitmap.Bitmap(TMarkerName),
	present: bool,
	error: OdinBasePack.Error,
) {
	bitmap = &module.bitmapMap[name]
	return
}
