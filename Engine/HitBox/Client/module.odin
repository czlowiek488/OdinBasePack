package HitBoxClient

import PainterClient "../../../../../Packages/OdinBasePack/Drawer/Painter/Client"
import "../../../../OdinBasePack"
import "../../../EventLoop"
import "../../../Memory/IdPicker"
import "../../../Memory/SparseSet"
import "../../../Memory/SpatialGrid"
import "../../HitBox"

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
	painterModule:  ^PainterClient.Module(
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
	module.painterModule = painterModule
	module.eventLoop = eventLoop
	module.hitBoxGridDraw = hitBoxGridDraw
	module.allocator = allocator
	for &grid in module.gridTypeSlice {
		grid, err = SpatialGrid.create(
			SpatialGrid.Grid(
				HitBox.HitBoxId,
				HitBox.HitBoxEntry(TEntityHitBoxType),
				HitBox.HitBoxCellMeta,
			),
			{100, module.allocator},
		)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
	}
	err = IdPicker.create(&module.hitBoxIdPicker, module.allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.entityHitBoxSS, err = SparseSet.create(
		HitBox.EntityId,
		HitBox.EntityHitBox(TEntityHitBoxType),
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.created = true
	return
}
