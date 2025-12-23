package UiClient

import "../../../OdinBasePack"
import "../../AutoSet"
import "../../Dictionary"
import PainterClient "../../Drawer/Painter/Client"
import "../../EventLoop"
import "../../HitBox"
import HitBoxClient "../../HitBox/Client"
import "../../SparseSet"
import "../../SpatialGrid"
import "../../Steer"
import SteerClient "../../Steer/Client"
import "../../Timer"
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

Manager :: struct(
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
	painterManager:  ^PainterClient.Manager(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	steerManager:    ^SteerClient.Manager(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	hitBoxManager:   ^HitBoxClient.Manager(
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
createManager :: proc(
	painterManager: ^PainterClient.Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	steerManager: ^SteerClient.Manager(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	hitBoxManager: ^HitBoxClient.Manager(
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
	manager: Manager(
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
	manager.eventLoop = eventLoop
	manager.painterManager = painterManager
	manager.steerManager = steerManager
	manager.hitBoxManager = hitBoxManager
	manager.tileScale = tileScale
	manager.allocator = allocator
	//
	manager.tileAS, err = AutoSet.create(
		Ui.TileId,
		Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.tileSS, err = SparseSet.create(
		HitBox.EntityId,
		Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.tileGrid, err = SpatialGrid.create(Ui.TileGrid, {100, manager.allocator})
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.hitBoxes, err = Dictionary.create(TEntityHitBoxType, HitBoxE, manager.allocator)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}


@(require_results)
isHovered :: proc(
	manager: ^Manager(
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
	if _, hovered = manager.hoveredTile.?; hovered {
		return
	}
	if _, hovered = manager.hoveredEntityId.?; hovered {
		return
	}
	return
}
