package PainterClient


import "../../../../OdinBasePack"
import TimeClient "../../../Engine/Time/Client"
import "../../../EventLoop"
import "../../../Math"
import "../../../Memory/AutoSet"
import "../../../Memory/Heap"
import "../../../Memory/SparseSet"
import "../../Animation"
import AnimationClient "../../Animation/Client"
import "../../Bitmap"
import BitmapClient "../../Bitmap/Client"
import "../../Image"
import ImageClient "../../Image/Client"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "../../Shape"
import ShapeClient "../../Shape/Client"
import "vendor:sdl3"

@(private)
RenderOrder :: struct {
	paintId: Renderer.PaintId,
}

@(private)
Tracker :: struct {
	position: Math.Vector,
	hooks:    [dynamic]Renderer.PaintId,
}

ModuleConfig :: struct {
	drawFps:     bool,
	imageConfig: ImageClient.ModuleConfig,
}

Module :: struct(
	$TEventLoopTask: typeid,
	$TEventLoopResult: typeid,
	$TError: typeid,
	$TFileImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
	$TAnimationName: typeid,
)
{
	eventLoop:       ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
	animationModule: ^AnimationClient.Module(
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	rendererModule:  ^RendererClient.Module(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	bitmapModule:    ^BitmapClient.Module(TBitmapName, TMarkerName),
	imageModule:     ^ImageClient.Module(TFileImageName),
	shapeModule:     ^ShapeClient.Module(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	timeModule:      ^TimeClient.Module,
	allocator:       OdinBasePack.Allocator,
	config:          ModuleConfig,
	//
	initialized:     bool,
	created:         bool,
	trackedEntities: ^SparseSet.SparseSet(int, Tracker),
	animationAS:     ^AutoSet.AutoSet(
		Painter.AnimationId,
		Painter.Animation(TShapeName, TAnimationName),
	),
}

@(require_results)
getShape :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	name: union {
		TShapeName,
		string,
	},
	required: bool,
) -> (
	shape: ^Shape.Shape(TMarkerName),
	ok: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	shape, ok, err = RendererClient.getShape(module.rendererModule, name, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
createModule :: proc(
	eventLoop: ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		$TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		$TEventLoopResult,
		$TError,
	),
	timeModule: ^TimeClient.Module,
	imageConfigMap: map[$TFileImageName]Image.ImageFileConfig,
	bitmapConfigMap: map[$TBitmapName]Bitmap.BitmapConfig($TMarkerName),
	shapeConfigMap: map[$TShapeName]Shape.ImageShapeConfig(TFileImageName, TBitmapName),
	animationConfigMap: map[$TAnimationName]Animation.AnimationConfig(TShapeName, TAnimationName),
	config: ModuleConfig,
	allocator: OdinBasePack.Allocator,
) -> (
	module: Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	error: TError,
) {
	module.allocator = allocator
	module.eventLoop = eventLoop
	module.config = config
	module.timeModule = timeModule
	err: OdinBasePack.Error
	module.rendererModule, err = Heap.allocate(
		RendererClient.Module(TFileImageName, TBitmapName, TMarkerName, TShapeName),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.imageModule, err = Heap.allocate(ImageClient.Module(TFileImageName), module.allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.bitmapModule, err = Heap.allocate(
		BitmapClient.Module(TBitmapName, TMarkerName),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.shapeModule, err = Heap.allocate(
		ShapeClient.Module(TFileImageName, TBitmapName, TMarkerName, TShapeName),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.animationModule, err = Heap.allocate(
		AnimationClient.Module(
			TFileImageName,
			TBitmapName,
			TMarkerName,
			TShapeName,
			TAnimationName,
		),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.rendererModule^, err = RendererClient.createModule(
		module.imageModule,
		module.bitmapModule,
		module.shapeModule,
		config.imageConfig,
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.imageModule^, err = ImageClient.createModule(
		config.imageConfig,
		module.allocator,
		imageConfigMap,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.bitmapModule^, err = BitmapClient.createModule(bitmapConfigMap, module.allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.shapeModule^, err = ShapeClient.createModule(
		module.imageModule,
		module.bitmapModule,
		module.allocator,
		shapeConfigMap,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.animationModule^, err = AnimationClient.createModule(
		module.shapeModule,
		animationConfigMap,
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.trackedEntities, err = SparseSet.create(int, Tracker, module.allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.animationAS, err = AutoSet.create(
		Painter.AnimationId,
		Painter.Animation(TShapeName, TAnimationName),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
initializeView :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
) -> (
	error: TError,
) {
	err := RendererClient.initializeModule(module.rendererModule)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = ImageClient.initializeModule(module.imageModule, module.rendererModule.renderer)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = BitmapClient.initializeModule(module.bitmapModule)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = ImageClient.loadImages(module.imageModule)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = ShapeClient.initializeModule(module.shapeModule)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = AnimationClient.initializeModule(module.animationModule)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.created = true
	return
}

destroyPainter :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
) {
	RendererClient.destroyRenderer(module.rendererModule)
}

@(require_results)
registerDynamicImage :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	imageName: string,
	path: string,
) -> (
	error: TError,
) {
	err := ImageClient.registerDynamicImage(module.imageModule, imageName, path)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
