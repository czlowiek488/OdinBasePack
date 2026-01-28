package Ui

import "../../EventLoop"
import "../../Math"
import "../../Memory/SpatialGrid"
import "../../Memory/Timer"
import "../../Renderer"

Color :: Renderer.Color

RenderConfig :: union {
	Renderer.AnimationConfig,
	Renderer.RectangleConfig,
	Renderer.CircleConfig,
}

TileId :: distinct int

HoverBehaviour :: enum {
	CHANGE,
	PULSE,
}

CameraTileConfig :: struct($TEventLoopTask: typeid, $TEventLoopResult: typeid, $TError: typeid) {
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
		tile: CameraTile(TEventLoopTask, TEventLoopResult, TError),
		hoveredTile: Maybe(CameraTile(TEventLoopTask, TEventLoopResult, TError)),
		event: TileEvent,
	) -> (
		error: TError
	),
	metaConfig:   Renderer.MetaConfig,
	renderConfig: RenderConfig,
}

PainterRenderId :: distinct int


ColorChange :: struct {
	source:    Color,
	target:    Color,
	startedAt: Timer.Time,
}
CameraTile :: struct($TEventLoopTask: typeid, $TEventLoopResult: typeid, $TError: typeid) {
	tileId:          TileId,
	config:          CameraTileConfig(TEventLoopTask, TEventLoopResult, TError),
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
