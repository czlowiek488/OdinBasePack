package RendererClient

import "../../../../OdinBasePack"
import "../../../AutoSet"
import "../../../SparseSet"
import BitmapClient "../../Bitmap/Client"
import ImageClient "../../Image/Client"
import "../../Renderer"
import ShapeClient "../../Shape/Client"
import "base:intrinsics"
import "vendor:sdl3"
import "vendor:sdl3/ttf"

RenderOrder :: struct {
	paintId: Renderer.PaintId,
}

Manager :: struct(
	$TFileImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
)
{
	config:         ImageClient.ManagerConfig,
	allocator:      OdinBasePack.Allocator,
	//
	shapeManager:   ^ShapeClient.Manager(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	imageManager:   ^ImageClient.Manager(TFileImageName),
	bitmapManager:  ^BitmapClient.Manager(TBitmapName, TMarkerName),
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
createManager :: proc(
	imageManager: ^ImageClient.Manager($TFileImageName),
	bitmapManager: ^BitmapClient.Manager($TBitmapName, $TMarkerName),
	shapeManager: ^ShapeClient.Manager(TFileImageName, TBitmapName, TMarkerName, $TShapeName),
	config: ImageClient.ManagerConfig,
	allocator: OdinBasePack.Allocator,
) -> (
	manager: Manager(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	manager.allocator = allocator
	manager.imageManager = imageManager
	manager.config = config
	manager.bitmapManager = bitmapManager
	manager.shapeManager = shapeManager
	//
	manager.paintAS = AutoSet.create(
		Renderer.PaintId,
		Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName),
		manager.allocator,
	) or_return
	for _, layerId in manager.renderOrder {
		manager.renderOrder[layerId] = SparseSet.create(
			Renderer.PaintId,
			RenderOrder,
			manager.allocator,
		) or_return
	}
	return
}

@(require_results)
initializeManager :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	manager.initialized = sdl3.Init(sdl3.INIT_VIDEO)
	if !manager.initialized {
		error = .INITIALIZATION_FAILED
		return
	}
	manager.window = sdl3.CreateWindow(
		"The Madness",
		i32(manager.config.windowSize.x),
		i32(manager.config.windowSize.y),
		{},
	)
	if manager.window == nil {
		error = .WINDOW_CREATION_FAILED
		return
	}
	manager.renderer = sdl3.CreateRenderer(manager.window, nil)
	if manager.renderer == nil {
		error = .RENDERER_CREATION_FAILED
		return
	}
	manager.ttfInitialized = ttf.Init()
	if !manager.ttfInitialized {
		error = .PAINTER_TTF_INITIALIZATION_FAILED
		return
	}
	manager.font = ttf.OpenFont("Assets/fonts/MonaspaceRadonFrozen-Regular.ttf", 32)
	if manager.font == nil {
		error = .RENDERER_TTF_NOT_LOADED
		return
	}
	if !sdl3.SetRenderDrawBlendMode(manager.renderer, sdl3.BLENDMODE_BLEND) {
		error = .PAINTER_RENDER_DRAW_BLEND_MODE_SET_FAILED
		return
	}
	if !sdl3.SetRenderScale(manager.renderer, manager.config.tileScale, manager.config.tileScale) {
		error = .PAINTER_RENDER_SET_SCALE_ERROR
		return
	}
	manager.created = true
	return
}

destroyRenderer :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) {
	if manager.font != nil {
		ttf.CloseFont(manager.font)
	}
	if manager.ttfInitialized {
		ttf.Quit()
	}
	if manager.renderer != nil {
		sdl3.DestroyRenderer(manager.renderer)
	}
	if manager.window != nil {
		sdl3.DestroyWindow(manager.window)
	}
	if manager.initialized {
		sdl3.Quit()
	}
}
