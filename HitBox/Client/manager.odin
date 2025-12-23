package HitBoxClient

import PainterClient "../../../../Packages/OdinBasePack/Drawer/Painter/Client"
import "../../../OdinBasePack"
import "../../EventLoop"
import "../../HitBox"
import "../../IdPicker"
import "../../SparseSet"
import "../../SpatialGrid"

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
	eventLoop:      ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
	painterManager: ^PainterClient.Manager(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	allocator:      OdinBasePack.Allocator,
	//
	gridTypeSlice:  [TEntityHitBoxType]SpatialGrid.Grid(
		HitBox.HitBoxId,
		HitBox.HitBoxEntry(TEntityHitBoxType),
		HitBox.HitBoxCellMeta,
	),
	hitBoxIdPicker: IdPicker.IdPicker(HitBox.HitBoxId),
	entityHitBoxSS: ^SparseSet.SparseSet(HitBox.EntityId, HitBox.EntityHitBox(TEntityHitBoxType)),
	hitBoxGridDraw: map[TEntityHitBoxType]HitBox.HitBoxGridDrawConfig,
	created:        bool,
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
	$TEntityHitBoxType: typeid,
	hitBoxGridDraw: map[TEntityHitBoxType]HitBox.HitBoxGridDrawConfig,
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
	manager.painterManager = painterManager
	manager.eventLoop = eventLoop
	manager.hitBoxGridDraw = hitBoxGridDraw
	manager.allocator = allocator
	for &grid in manager.gridTypeSlice {
		grid, err = SpatialGrid.create(
			SpatialGrid.Grid(
				HitBox.HitBoxId,
				HitBox.HitBoxEntry(TEntityHitBoxType),
				HitBox.HitBoxCellMeta,
			),
			{100, manager.allocator},
		)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
	}
	err = IdPicker.create(&manager.hitBoxIdPicker, manager.allocator)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.entityHitBoxSS, err = SparseSet.create(
		HitBox.EntityId,
		HitBox.EntityHitBox(TEntityHitBoxType),
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.created = true
	return
}
