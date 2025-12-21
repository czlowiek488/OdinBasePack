package RendererImage

import "vendor:sdl3"

ImageFileConfig :: struct {
	filePath:  string,
	scaleMode: sdl3.ScaleMode,
}

DynamicImage :: struct {
	texture: ^sdl3.Texture,
	path:    string,
}

AsyncLoad :: struct($TFileImageName: typeid) {
	data:      []u8,
	key:       union {
		string,
		TFileImageName,
	},
	asyncFile: ^sdl3.AsyncIO,
	surface:   ^sdl3.Surface,
}

TempAsync :: struct($TFileImageName: typeid) {
	dynamicKeys:  [dynamic]string,
	keys:         [dynamic]TFileImageName,
	queue:        ^sdl3.AsyncIOQueue,
	loads:        [dynamic]AsyncLoad(TFileImageName),
	asyncIoCount: u8,
}
