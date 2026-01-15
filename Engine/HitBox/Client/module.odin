package HitBoxClient

import PainterClient "../../../../../Packages/OdinBasePack/Drawer/Painter/Client"
import "../../../../OdinBasePack"
import "../../../EventLoop"
import "../../../Memory/IdPicker"
import "../../../Memory/SparseSet"
import "../../../Memory/SpatialGrid"
import "../../HitBox"
import "base:intrinsics"

Module :: struct(
	$TEventLoopTask: typeid,
	$TEventLoopResult: typeid,
	$TError: typeid,
	$TEntityHitBoxType: typeid,
) where intrinsics.type_is_enum(TEntityHitBoxType)
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
	allocator:      OdinBasePack.Allocator,
	//
	gridTypeSlice:  [TEntityHitBoxType]SpatialGrid.Grid(
		HitBox.HitBoxId,
		HitBox.HitBoxEntry(TEntityHitBoxType),
		HitBox.HitBoxCellMeta,
	),
	hitBoxIdPicker: ^IdPicker.IdPicker(HitBox.HitBoxId),
	entityHitBoxSS: ^SparseSet.SparseSet(HitBox.EntityId, HitBox.EntityHitBox(TEntityHitBoxType)),
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
	$TEntityHitBoxType: typeid,
	allocator: OdinBasePack.Allocator,
) -> (
	module: Module(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
	error: TError,
) where intrinsics.type_is_enum(TEntityHitBoxType) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	module.eventLoop = eventLoop
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
	module.hitBoxIdPicker, err = IdPicker.create(HitBox.HitBoxId, module.allocator)
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
	return
}
