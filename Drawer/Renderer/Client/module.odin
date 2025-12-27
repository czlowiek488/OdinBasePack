package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/AutoSet"
import "../../../Memory/SparseSet"
import BitmapClient "../../Bitmap/Client"
import ImageClient "../../Image/Client"
import "../../Renderer"
import ShapeClient "../../Shape/Client"
import "base:intrinsics"
import "vendor:sdl3"
import "vendor:sdl3/ttf"

RenderOrder :: struct {
	paintId:       Renderer.PaintId,
	topLeftCorner: Math.Vector,
	zIndex:        int,
}

Module :: struct(
	$TFileImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
)
{
	config:         ImageClient.ModuleConfig,
	allocator:      OdinBasePack.Allocator,
	//
	shapeModule:    ^ShapeClient.Module(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	imageModule:    ^ImageClient.Module(TFileImageName),
	bitmapModule:   ^BitmapClient.Module(TBitmapName, TMarkerName),
	window:         ^sdl3.Window,
	renderer:       ^sdl3.Renderer,
	font:           ^ttf.Font,
	initialized:    bool,
	ttfInitialized: bool,
	created:        bool,
	paintAS:        ^AutoSet.AutoSet(
		Renderer.PaintId,
		Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName),
	),
	renderOrder:    [Renderer.LayerId]^SparseSet.SparseSet(Renderer.PaintId, RenderOrder),
	camera:         Renderer.Camera,
}


@(require_results)
createModule :: proc(
	imageModule: ^ImageClient.Module($TFileImageName),
	bitmapModule: ^BitmapClient.Module($TBitmapName, $TMarkerName),
	shapeModule: ^ShapeClient.Module(TFileImageName, TBitmapName, TMarkerName, $TShapeName),
	config: ImageClient.ModuleConfig,
	allocator: OdinBasePack.Allocator,
) -> (
	module: Module(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	module.allocator = allocator
	module.imageModule = imageModule
	module.config = config
	module.bitmapModule = bitmapModule
	module.shapeModule = shapeModule
	//
	module.paintAS = AutoSet.create(
		Renderer.PaintId,
		Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName),
		module.allocator,
	) or_return
	for _, layerId in module.renderOrder {
		module.renderOrder[layerId] = SparseSet.create(
			Renderer.PaintId,
			RenderOrder,
			module.allocator,
		) or_return
	}
	return
}

@(require_results)
startRendering :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	module.initialized = sdl3.Init(sdl3.INIT_VIDEO)
	if !module.initialized {
		error = .INITIALIZATION_FAILED
		return
	}
	module.window = sdl3.CreateWindow(
		"The Madness",
		i32(module.config.windowSize.x),
		i32(module.config.windowSize.y),
		{},
	)
	if module.window == nil {
		error = .WINDOW_CREATION_FAILED
		return
	}
	module.renderer = sdl3.CreateRenderer(module.window, nil)
	if module.renderer == nil {
		error = .RENDERER_CREATION_FAILED
		return
	}
	module.ttfInitialized = ttf.Init()
	if !module.ttfInitialized {
		error = .PAINTER_TTF_INITIALIZATION_FAILED
		return
	}
	module.font = ttf.OpenFont("Assets/fonts/MonaspaceRadonFrozen-Regular.ttf", 32)
	if module.font == nil {
		error = .RENDERER_TTF_NOT_LOADED
		return
	}
	if !sdl3.SetRenderDrawBlendMode(module.renderer, sdl3.BLENDMODE_BLEND) {
		error = .PAINTER_RENDER_DRAW_BLEND_MODE_SET_FAILED
		return
	}
	if !sdl3.SetRenderScale(module.renderer, module.config.tileScale, module.config.tileScale) {
		error = .PAINTER_RENDER_SET_SCALE_ERROR
		return
	}
	module.created = true
	return
}

destroyRenderer :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) {
	if module.font != nil {
		ttf.CloseFont(module.font)
	}
	if module.ttfInitialized {
		ttf.Quit()
	}
	if module.renderer != nil {
		sdl3.DestroyRenderer(module.renderer)
	}
	if module.window != nil {
		sdl3.DestroyWindow(module.window)
	}
	if module.initialized {
		sdl3.Quit()
	}
}
