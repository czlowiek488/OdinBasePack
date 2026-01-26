package Renderer

import "vendor:sdl3"

ImageFileConfig :: struct {
	filePath:  string,
	scaleMode: sdl3.ScaleMode,
}

DynamicImage :: struct {
	texture: ^sdl3.Texture,
	path:    string,
}

AsyncLoad :: struct($TImageName: typeid) {
	data:      []u8,
	key:       union {
		string,
		TImageName,
	},
	asyncFile: ^sdl3.AsyncIO,
	surface:   ^sdl3.Surface,
}

TempAsync :: struct($TImageName: typeid) {
	dynamicKeys:  [dynamic]string,
	keys:         [dynamic]TImageName,
	queue:        ^sdl3.AsyncIOQueue,
	loads:        [dynamic]AsyncLoad(TImageName),
	asyncIoCount: u8,
}
