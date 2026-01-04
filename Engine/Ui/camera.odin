package Ui

import "../../Drawer/Painter"
import "../../Drawer/Renderer"
import "../../EventLoop"
import "../../Math"
import "../../Memory/SpatialGrid"
import "../../Memory/Timer"

Color :: Painter.Color

RenderConfig :: union($TAnimationName: typeid) {
	Painter.AnimationConfig(TAnimationName),
	Renderer.RectangleConfig,
	Renderer.CircleConfig,
}

TileId :: distinct int

HoverBehaviour :: enum {
	CHANGE,
	PULSE,
}

HoverConfig :: struct {
	color: Renderer.ColorDefinition,
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
		hoveredTile: Maybe(CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)),
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
	geometry:        Math.Geometry,
	scaledGeometry:  Math.Geometry,
	originalColor:   Renderer.ColorDefinition,
	offset:          Math.Vector,
}

TileGridEntry :: struct {
	zIndex: Renderer.ZIndex,
	layer:  Renderer.LayerId,
}
TileGridCellMeta :: struct {}

TileGrid :: SpatialGrid.Grid(TileId, TileGridEntry, TileGridCellMeta)
