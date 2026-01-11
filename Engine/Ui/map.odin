package Ui


import "../../EventLoop"
import "../../Math"
import "../../Memory/Timer"
import "../HitBox"
import "../Steer"

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
	time:    Timer.Time,
}

TileClick :: struct {
	clicked: bool,
	time:    Timer.Time,
	button:  Steer.MouseButtonName,
}

TileMoved :: struct {
	move:   Math.Vector,
	change: Math.Vector,
}

TileEvent :: union {
	TileHover,
	TileClick,
	TileMoved,
}
