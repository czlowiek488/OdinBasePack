package HitBox3Client2

import "../../../../OdinBasePack"
import EventLoop "../../../EventLoop2"
import "../../../Memory/IdPicker"
import "../../../Memory/SparseSet"
import "../../../Memory/SpatialGrid"
import HitBox "../../HitBox2"
import "base:intrinsics"

Module :: struct(
	$TEventLoopTask: typeid,
	$TEventLoopResult: typeid,
	$TEntityHitBoxType: typeid,
) where intrinsics.type_is_enum(TEntityHitBoxType) {
	eventLoop:      ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
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
	),
	$TEntityHitBoxType: typeid,
	allocator: OdinBasePack.Allocator,
) -> (
	module: Module(TEventLoopTask, TEventLoopResult, TEntityHitBoxType),
	error: OdinBasePack.Error,
) where intrinsics.type_is_enum(TEntityHitBoxType) {
	module.eventLoop = eventLoop
	module.allocator = allocator
	for &grid in module.gridTypeSlice {
		grid = SpatialGrid.create(
			SpatialGrid.Grid(
				HitBox.HitBoxId,
				HitBox.HitBoxEntry(TEntityHitBoxType),
				HitBox.HitBoxCellMeta,
			),
			{100, module.allocator},
		) or_return
	}
	module.hitBoxIdPicker = IdPicker.create(HitBox.HitBoxId, module.allocator) or_return
	module.entityHitBoxSS = SparseSet.create(
		HitBox.EntityId,
		HitBox.EntityHitBox(TEntityHitBoxType),
		module.allocator,
	) or_return
	return
}
