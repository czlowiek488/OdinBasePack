package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/AutoSet"
import "../../Memory/Dictionary"
import "../../Memory/SparseSet"
import "../../Memory/Timer"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "base:intrinsics"
import "vendor:sdl3"
import "vendor:sdl3/ttf"

RenderOrder :: struct {
	paintId:        Renderer.PaintId,
	onMapYPosition: Maybe(f32),
	zIndex:         Renderer.ZIndex,
	position:       u128,
}

@(private)
Tracker :: struct {
	position: Math.Vector,
	hooks:    [dynamic]Renderer.PaintId,
}

ModuleConfig :: struct(
	$TImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
) where intrinsics.type_is_enum(TShapeName) &&
	intrinsics.type_is_enum(TBitmapName) &&
	intrinsics.type_is_enum(TImageName)
{
	shapes:         map[TShapeName]Renderer.ImageShapeConfig(TImageName, TBitmapName),
	imageConfig:    map[TImageName]Renderer.ImageFileConfig,
	bitmaps:        map[TBitmapName]Renderer.BitmapConfig(TMarkerName),
	measureLoading: bool,
	tileScale:      f32,
	tileSize:       Math.Vector,
	windowSize:     Math.Vector,
	drawFps:        bool,
}

Module :: struct(
	$TImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
)
{
	config:               ModuleConfig(TImageName, TBitmapName, TMarkerName, TShapeName),
	allocator:            OdinBasePack.Allocator,
	//
	window:               ^sdl3.Window,
	renderer:             ^sdl3.Renderer,
	font:                 ^ttf.Font,
	initialized:          bool,
	ttfInitialized:       bool,
	created:              bool,
	paintAS:              ^AutoSet.AutoSet(
		Renderer.PaintId,
		Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName),
	),
	renderOrder:          [Renderer.LayerId]^SparseSet.SparseSet(Renderer.PaintId, RenderOrder),
	camera:               Renderer.Camera,
	shapeMap:             map[TShapeName]Renderer.Shape(TMarkerName),
	dynamicShapeMap:      map[string]Renderer.Shape(TMarkerName),
	imageMap:             map[TImageName]Renderer.DynamicImage,
	dynamicImageMap:      map[string]Renderer.DynamicImage,
	bitmapMap:            [TBitmapName]Renderer.Bitmap(TMarkerName),
	trackedEntities:      ^SparseSet.SparseSet(int, Tracker),
	animationAS:          ^AutoSet.AutoSet(Renderer.AnimationId, Renderer.Animation(TShapeName)),
	multiFrameAnimations: map[Renderer.AnimationId]Timer.Time,
	animationMap:         map[int]Renderer.PainterAnimation(TShapeName),
	dynamicAnimationMap:  map[string]Renderer.PainterAnimation(TShapeName),
}


@(require_results)
createModule :: proc(
	config: ModuleConfig($TImageName, $TBitmapName, $TMarkerName, $TShapeName),
	allocator: OdinBasePack.Allocator,
) -> (
	module: Module(TImageName, TBitmapName, TMarkerName, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	module.allocator = allocator
	module.config = config
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
	module.shapeMap = Dictionary.create(
		TShapeName,
		Renderer.Shape(TMarkerName),
		module.allocator,
	) or_return
	module.dynamicShapeMap = Dictionary.create(
		string,
		Renderer.Shape(TMarkerName),
		module.allocator,
	) or_return
	module.dynamicImageMap = Dictionary.create(
		string,
		Renderer.DynamicImage,
		module.allocator,
	) or_return
	module.imageMap = Dictionary.create(
		TImageName,
		Renderer.DynamicImage,
		module.allocator,
	) or_return
	for imageName, config in module.config.imageConfig {
		Dictionary.set(
			&module.imageMap,
			imageName,
			Renderer.DynamicImage{nil, config.filePath},
		) or_return
	}
	module.trackedEntities = SparseSet.create(int, Tracker, module.allocator) or_return
	module.animationAS = AutoSet.create(
		Renderer.AnimationId,
		Renderer.Animation(TShapeName),
		module.allocator,
	) or_return
	module.animationMap = Dictionary.create(
		int,
		Renderer.PainterAnimation(TShapeName),
		module.allocator,
	) or_return
	module.multiFrameAnimations = Dictionary.create(
		Renderer.AnimationId,
		Timer.Time,
		module.allocator,
	) or_return
	module.dynamicAnimationMap = Dictionary.create(
		string,
		Renderer.PainterAnimation(TShapeName),
		module.allocator,
	) or_return
	return
}

@(require_results)
startRendering :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName),
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

destroyRenderer :: proc(module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName)) {
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


@(require_results)
attachRenderer :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName),
	renderer: ^sdl3.Renderer,
) -> (
	error: OdinBasePack.Error,
) {
	module.renderer = renderer
	return
}
