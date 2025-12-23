package Ui

import "../Drawer/Painter"
import "../Drawer/Renderer"
import "../EventLoop"
import "../Math"
import "../SpatialGrid"
import "../Timer"
import "vendor:sdl3"

RenderConfig :: union($TAnimationName: typeid) {
	Painter.AnimationConfig(TAnimationName),
	Renderer.RectangleConfig,
}

TileId :: distinct int

HoverBehaviour :: enum {
	CHANGE,
	PULSE,
}

Color :: sdl3.Color

HoverConfig :: struct {
	color: Color,
}

CameraTileConfig :: struct(
	$TEventLoopTask: typeid,
	$TEventLoopResult: typeid,
	$TError: typeid,
	$TAnimationName: typeid,
)
{
	customId:     int,
	layer:        Renderer.LayerId,
	onEvent:      proc(
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
		tile: CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
		event: TileEvent,
	) -> (
		error: TError
	),
	metaConfig:   Renderer.MetaConfig,
	renderConfig: RenderConfig(TAnimationName),
	hoverConfig:  Maybe(HoverConfig),
}

PainterRenderId :: distinct int


ColorChange :: struct {
	source:    Color,
	target:    Color,
	startedAt: Timer.Time,
}
CameraTile :: struct(
	$TEventLoopTask: typeid,
	$TEventLoopResult: typeid,
	$TError: typeid,
	$TAnimationName: typeid,
)
{
	tileId:          TileId,
	config:          CameraTileConfig(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
	painterRenderId: PainterRenderId,
	bounds:          Math.Rectangle,
	scaledBounds:    Math.Rectangle,
	originalColor:   Color,
}

TileGridEntry :: struct {}
TileGridCellMeta :: struct {}

TileGrid :: SpatialGrid.Grid(TileId, TileGridEntry, TileGridCellMeta)
