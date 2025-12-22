package PainterClient


import "../../../../OdinBasePack"
import "../../../AutoSet"
import "../../../EventLoop"
import "../../../Heap"
import "../../../Math"
import "../../../SparseSet"
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

Manager :: struct(
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
	eventLoop:        ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
	animationManager: ^AnimationClient.Manager(
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	rendererManager:  ^RendererClient.Manager(
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
	),
	bitmapManager:    ^BitmapClient.Manager(TBitmapName, TMarkerName),
	imageManager:     ^ImageClient.Manager(TFileImageName),
	shapeManager:     ^ShapeClient.Manager(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	allocator:        OdinBasePack.Allocator,
	//
	initialized:      bool,
	created:          bool,
	trackedEntities:  ^SparseSet.SparseSet(int, Tracker),
	animationAS:      ^AutoSet.AutoSet(
		Painter.AnimationId,
		Painter.Animation(TShapeName, TAnimationName),
	),
}

@(require_results)
getShape :: proc(
	manager: ^Manager(
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
	shape, ok, err = RendererClient.getShape(manager.rendererManager, name, required)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
createManager :: proc(
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
	imageConfigMap: map[$TFileImageName]Image.ImageFileConfig,
	bitmapConfigMap: map[$TBitmapName]Bitmap.BitmapConfig($TMarkerName),
	shapeConfigMap: map[$TShapeName]Shape.ImageShapeConfig(TFileImageName, TBitmapName),
	animationConfigMap: map[$TAnimationName]Animation.AnimationConfig(TShapeName, TAnimationName),
	config: ImageClient.ManagerConfig,
	allocator: OdinBasePack.Allocator,
) -> (
	manager: Manager(
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
	manager.allocator = allocator
	manager.eventLoop = eventLoop
	err: OdinBasePack.Error
	manager.rendererManager, err = Heap.allocate(
		RendererClient.Manager(TFileImageName, TBitmapName, TMarkerName, TShapeName),
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.imageManager, err = Heap.allocate(
		ImageClient.Manager(TFileImageName),
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.bitmapManager, err = Heap.allocate(
		BitmapClient.Manager(TBitmapName, TMarkerName),
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.shapeManager, err = Heap.allocate(
		ShapeClient.Manager(TFileImageName, TBitmapName, TMarkerName, TShapeName),
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.animationManager, err = Heap.allocate(
		AnimationClient.Manager(
			TFileImageName,
			TBitmapName,
			TMarkerName,
			TShapeName,
			TAnimationName,
		),
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.rendererManager^, err = RendererClient.createManager(
		manager.imageManager,
		manager.bitmapManager,
		manager.shapeManager,
		config,
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.imageManager^, err = ImageClient.createManager(
		config,
		manager.allocator,
		imageConfigMap,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.bitmapManager^, err = BitmapClient.createManager(bitmapConfigMap, manager.allocator)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.shapeManager^, err = ShapeClient.createManager(
		manager.imageManager,
		manager.bitmapManager,
		manager.allocator,
		shapeConfigMap,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.animationManager^, err = AnimationClient.createManager(
		manager.shapeManager,
		animationConfigMap,
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.trackedEntities, err = SparseSet.create(int, Tracker, manager.allocator)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.animationAS, err = AutoSet.create(
		Painter.AnimationId,
		Painter.Animation(TShapeName, TAnimationName),
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
initializeView :: proc(
	manager: ^Manager(
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
	err := RendererClient.initializeManager(manager.rendererManager)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = ImageClient.initializeManager(manager.imageManager, manager.rendererManager.renderer)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = BitmapClient.initializeManager(manager.bitmapManager)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = ImageClient.loadImages(manager.imageManager)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = ShapeClient.initializeManager(manager.shapeManager)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = AnimationClient.initializeManager(manager.animationManager)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.created = true
	return
}

destroyPainter :: proc(
	manager: ^Manager(
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
	RendererClient.destroyRenderer(manager.rendererManager)
}

@(require_results)
registerDynamicImage :: proc(
	manager: ^Manager(
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
	err := ImageClient.registerDynamicImage(manager.imageManager, imageName, path)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}
