package PainterClient


import "../../../OdinBasePack"
import TimeClient "../../Engine/Time/Client"
import "../../EventLoop"
import "../../Math"
import "../../Memory/AutoSet"
import "../../Memory/Dictionary"
import "../../Memory/SparseSet"
import "../../Memory/Timer"
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
	eventLoop:            ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
	rendererModule:       ^RendererClient.Module(
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
	),
	timeModule:           ^TimeClient.Module,
	allocator:            OdinBasePack.Allocator,
	config:               ModuleConfig(TAnimationName, TShapeName),
	//
	initialized:          bool,
	created:              bool,
	trackedEntities:      ^SparseSet.SparseSet(int, Tracker),
	animationAS:          ^AutoSet.AutoSet(
		Painter.AnimationId,
		Painter.Animation(TShapeName, TAnimationName),
	),
	multiFrameAnimations: map[Painter.AnimationId]Timer.Time,
	animationMap:         map[TAnimationName]Painter.PainterAnimation(TShapeName, TAnimationName),
	dynamicAnimationMap:  map[string]Painter.PainterAnimation(TShapeName, TAnimationName),
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
	error: OdinBasePack.Error,
) {
	shape, ok = RendererClient.getShape(module.rendererModule, name, required) or_return
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
	error: OdinBasePack.Error,
) {
	module.allocator = allocator
	module.eventLoop = eventLoop
	module.config = config
	module.timeModule = timeModule
	module.rendererModule = rendererModule
	module.trackedEntities = SparseSet.create(int, Tracker, module.allocator) or_return
	module.animationAS = AutoSet.create(
		Painter.AnimationId,
		Painter.Animation(TShapeName, TAnimationName),
		module.allocator,
	) or_return
	module.animationMap = Dictionary.create(
		TAnimationName,
		Painter.PainterAnimation(TShapeName, TAnimationName),
		module.allocator,
	) or_return
	module.multiFrameAnimations = Dictionary.create(
		Painter.AnimationId,
		Timer.Time,
		module.allocator,
	) or_return
	module.dynamicAnimationMap = Dictionary.create(
		string,
		Painter.PainterAnimation(TShapeName, TAnimationName),
		module.allocator,
	) or_return
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
	error: OdinBasePack.Error,
) {
	RendererClient.registerDynamicImage(module.rendererModule, imageName, path) or_return
	return
}
