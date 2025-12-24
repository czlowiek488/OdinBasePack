package UiClient

import "../../../OdinBasePack"
import PainterClient "../../Drawer/Painter/Client"
import "../../EventLoop"
import "../../HitBox"
import HitBoxClient "../../HitBox/Client"
import "../../Memory/AutoSet"
import "../../Memory/Dictionary"
import "../../Memory/SparseSet"
import "../../Memory/SpatialGrid"
import "../../Memory/Timer"
import "../../Steer"
import SteerClient "../../Steer/Client"
import "../../Ui"

HitBoxE :: struct {}

Click :: struct {
	id:     Maybe(union {
			Ui.TileId,
			HitBox.EntityId,
		}),
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
	$TFileImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
	$TAnimationName: typeid,
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
	painterModule:   ^PainterClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	steerModule:     ^SteerClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	hitBoxModule:    ^HitBoxClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
		TEntityHitBoxType,
	),
	allocator:       OdinBasePack.Allocator,
	//
	tileAS:          ^AutoSet.AutoSet(
		Ui.TileId,
		Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
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
	painterModule: ^PainterClient.Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	steerModule: ^SteerClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	hitBoxModule: ^HitBoxClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
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
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
		TEntityHitBoxType,
	),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	module.eventLoop = eventLoop
	module.painterModule = painterModule
	module.steerModule = steerModule
	module.hitBoxModule = hitBoxModule
	module.tileScale = tileScale
	module.allocator = allocator
	//
	module.tileAS, err = AutoSet.create(
		Ui.TileId,
		Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
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
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
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
