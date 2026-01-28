package UiClient

import "../../../../OdinBasePack"
import "../../../EventLoop"
import "../../../Math"
import "../../../Memory/AutoSet"
import "../../../Memory/Dictionary"
import "../../../Memory/SparseSet"
import "../../../Memory/SpatialGrid"
import "../../../Memory/Timer"
import RendererClient "../../../Renderer/Client"
import "../../HitBox"
import HitBoxClient "../../HitBox/Client"
import "../../Steer"
import SteerClient "../../Steer/Client"
import "../../Ui"

ASSURE_NO_OVERLAPPING_UI :: #config(ASSURE_NO_OVERLAPPING_UI, false)

HitBoxE :: struct {}

Click :: struct {
	id:     Maybe(union {
			Ui.TileId,
			HitBox.EntityId,
		}),
	move:   Math.Vector,
	button: Maybe(Steer.MouseButtonName),
}

HoveredTile :: struct {
	tileId: Ui.TileId,
	time:   Timer.Time,
}

Module :: struct(
	$TEventLoopTask: typeid,
	$TEventLoopResult: typeid,
	$TError: typeid,
	$TImageName: typeid,
	$TBitmapName: typeid,
	$TEntityHitBoxType: typeid,
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
	rendererModule:  ^RendererClient.Module(TImageName, TBitmapName),
	steerModule:     ^SteerClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TImageName,
		TBitmapName,
	),
	hitBoxModule:    ^HitBoxClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TEntityHitBoxType,
	),
	allocator:       OdinBasePack.Allocator,
	//
	tileAS:          ^AutoSet.AutoSet(
		Ui.TileId,
		Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError),
	),
	tileSS:          ^SparseSet.SparseSet(
		HitBox.EntityId,
		Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
	),
	tileGrid:        Ui.TileGrid,
	hoveredTile:     Maybe(HoveredTile),
	hoveredEntityId: Maybe(HitBox.EntityId),
	click:           Click,
	tileScale:       f32,
	hitBoxes:        map[TEntityHitBoxType]HitBoxE,
}

@(require_results)
createModule :: proc(
	rendererModule: ^RendererClient.Module($TImageName, $TBitmapName),
	steerModule: ^SteerClient.Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		TImageName,
		TBitmapName,
	),
	hitBoxModule: ^HitBoxClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		$TEntityHitBoxType,
	),
	eventLoop: ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
	tileScale: f32,
	allocator: OdinBasePack.Allocator,
) -> (
	module: Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TImageName,
		TBitmapName,
		TEntityHitBoxType,
	),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	module.eventLoop = eventLoop
	module.rendererModule = rendererModule
	module.steerModule = steerModule
	module.hitBoxModule = hitBoxModule
	module.tileScale = tileScale
	module.allocator = allocator
	//
	module.tileAS, err = AutoSet.create(
		Ui.TileId,
		Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.tileSS, err = SparseSet.create(
		HitBox.EntityId,
		Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.tileGrid, err = SpatialGrid.create(Ui.TileGrid, {100, module.allocator})
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.hitBoxes, err = Dictionary.create(TEntityHitBoxType, HitBoxE, module.allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}


@(require_results)
isHovered :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TEntityHitBoxType,
	),
) -> (
	hovered: bool,
	error: TError,
) {
	if _, hovered = module.hoveredTile.?; hovered {
		return
	}
	if _, hovered = module.hoveredEntityId.?; hovered {
		return
	}
	return
}
