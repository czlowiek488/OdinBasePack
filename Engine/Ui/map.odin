package Ui


import "../../EventLoop"
import "../HitBox"

MapTileConfig :: struct(
	$TEventLoopTask: typeid,
	$TEventLoopResult: typeid,
	$TError: typeid,
	$TEntityHitBoxType: typeid,
)
{
	entityId: HitBox.EntityId,
	hitBox:   TEntityHitBoxType,
	onEvent:  proc(
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
		tile: MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
		event: TileEvent,
	) -> (
		error: TError
	),
}

MapTile :: struct(
	$TEventLoopTask: typeid,
	$TEventLoopResult: typeid,
	$TError: typeid,
	$TEntityHitBoxType: typeid,
)
{
	config: MapTileConfig(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
}

TileHover :: struct {
	hovered: bool,
}

TileClick :: struct {
	clicked: bool,
}

TileEvent :: union {
	TileHover,
	TileClick,
}
