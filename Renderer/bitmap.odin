package Renderer

import "../Math"
import "base:intrinsics"
import "vendor:sdl3"

PixelColorListMapElement :: [dynamic]Math.Vector

BitmapConfig :: struct {
	filePath:     string,
	enumColorMap: map[sdl3.Color]int,
}

Bitmap :: struct {
	config:            BitmapConfig,
	pixelColorListMap: map[int]PixelColorListMapElement,
}
