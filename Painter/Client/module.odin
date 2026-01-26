package PainterClient


import "../../../OdinBasePack"
import TimeClient "../../Engine/Time/Client"
import "../../EventLoop"
import "../../Math"
import "../../Memory/AutoSet"
import "../../Memory/Dictionary"
import "../../Memory/SparseSet"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"
import "vendor:sdl3"

@(private)
Tracker :: struct {
	position: Math.Vector,
	hooks:    [dynamic]Renderer.PaintId,
}

ModuleConfig :: struct($TAnimationName: typeid, $TShapeName: typeid) {
	animations: map[TAnimationName]Painter.PainterAnimationConfig(TShapeName, TAnimationName),
	windowSize: Math.Vector,
	tileScale:  f32,
	drawFps:    bool,
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
	eventLoop:           ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
	rendererModule:      ^RendererClient.Module(
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
	),
	timeModule:          ^TimeClient.Module,
	allocator:           OdinBasePack.Allocator,
	config:              ModuleConfig(TAnimationName, TShapeName),
	//
	initialized:         bool,
	created:             bool,
	trackedEntities:     ^SparseSet.SparseSet(int, Tracker),
	animationAS:         ^AutoSet.AutoSet(
		Painter.AnimationId,
		Painter.Animation(TShapeName, TAnimationName),
	),
	animationMap:        map[TAnimationName]Painter.PainterAnimation(TShapeName, TAnimationName),
	dynamicAnimationMap: map[string]Painter.PainterAnimation(TShapeName, TAnimationName),
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
	shape: ^Renderer.Shape(TMarkerName),
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
	rendererModule: ^RendererClient.Module(
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
	),
	config: ModuleConfig($TAnimationName, TShapeName),
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
	module.rendererModule = rendererModule
	err: OdinBasePack.Error
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
	module.animationMap, err = Dictionary.create(
		TAnimationName,
		Painter.PainterAnimation(TShapeName, TAnimationName),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.dynamicAnimationMap, err = Dictionary.create(
		string,
		Painter.PainterAnimation(TShapeName, TAnimationName),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
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
	err := RendererClient.registerDynamicImage(module.rendererModule, imageName, path)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
