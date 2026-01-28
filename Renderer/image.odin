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

AsyncLoad :: struct {
	data:      []u8,
	key:       union {
		int,
		string,
	},
	asyncFile: ^sdl3.AsyncIO,
	surface:   ^sdl3.Surface,
}

TempAsync :: struct {
	dynamicKeys:  [dynamic]string,
	keys:         [dynamic]int,
	queue:        ^sdl3.AsyncIOQueue,
	loads:        [dynamic]AsyncLoad,
	asyncIoCount: u8,
}
