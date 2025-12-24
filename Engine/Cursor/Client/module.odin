package CursorClient

import "../../../Drawer/Painter"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../EventLoop"
import "../../../Math"
import "../../Cursor"
import SteerClient "../../Steer/Client"

ModuleConfig :: struct($TShapeName: typeid) #all_or_none {
	showCursorAxis:          [2]bool,
	windowSize:              Math.Vector,
	showCursorSurfaceBorder: bool,
	tileScale:               f32,
}

Module :: struct(
	$TEventLoopTask: typeid,
	$TEventLoopResult: typeid,
	$TError: typeid,
	$TFileImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
	$TAnimationName: typeid,
)
{
	painterModule: ^PainterClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	eventLoop:     ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
	steerModule:   ^SteerClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	//
	config:        ModuleConfig(TShapeName),
	cursor:        [Cursor.State][Cursor.Shift]Cursor.CursorData(TShapeName),
	state:         Cursor.State,
	shift:         Cursor.Shift,
	showText:      bool,
	customText:    Maybe(string),
	axis:          [2]Painter.LineId,
	textId:        Maybe(Painter.StringId),
	created:       bool,
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
	steerModule: ^SteerClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	config: ModuleConfig(TShapeName),
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
	),
	error: TError,
) {
	module.steerModule = steerModule
	module.painterModule = painterModule
	module.eventLoop = eventLoop
	//
	return
}
