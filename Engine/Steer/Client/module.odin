package SteerClient

import "../../../../OdinBasePack"
import "../../../Drawer/Painter"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../EventLoop"
import "../../../Math"
import "../../../Memory/Dictionary"
import "../../Steer"

ModuleConfig :: struct #all_or_none {
	tileScale:  f32,
	windowSize: Math.Vector,
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
	eventLoop:             ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
	painterModule:         ^PainterClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	config:                ModuleConfig,
	allocator:             OdinBasePack.Allocator,
	//
	steer:                 Steer.Steer,
	mousePositionStringId: Maybe(Painter.StringId),
	created:               bool,
	printMouseCoordinates: bool,
	keyboard:              bool,
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
	config: ModuleConfig,
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
	),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	module.painterModule = painterModule
	module.allocator = allocator
	module.config = config
	//
	module.steer.keyboard.keyMap, err = Dictionary.create(
		Steer.KeyboardKeyName,
		Steer.SteerButton,
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.steer.mouse.buttonMap, err = Dictionary.create(
		Steer.MouseButtonName,
		Steer.SteerButton,
		module.allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	module.created = true
	return
}

@(require_results)
setMousePositionVisibility :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	visible: bool,
) -> (
	error: TError,
) {
	module.printMouseCoordinates = visible
	return
}

@(require_results)
setKeyboardLogging :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	visible: bool,
) -> (
	error: TError,
) {
	module.keyboard = visible
	return
}


@(require_results)
initializeMouseAndKeyboardState :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	for buttonName in Steer.MouseButtonName {
		err = Dictionary.set(
			&module.steer.mouse.buttonMap,
			buttonName,
			Steer.SteerButton{false, false},
		)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
	}
	for keyName in Steer.KeyboardKeyName {
		err = Dictionary.set(
			&module.steer.keyboard.keyMap,
			keyName,
			Steer.SteerButton{false, false},
		)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
	}
	err = loadKeyboardMapping(
		module,
		{
			.W = 119,
			.S = 115,
			.A = 100,
			.D = 97,
			.Q = 113,
			.E = 101,
			.I = 105,
			.U = 117,
			.F1 = 1073741882,
			.F2 = 1073741883,
			.ESC = 27,
			.NUM_1 = 49,
			.NUM_2 = 50,
			.NUM_3 = 51,
			.NUM_4 = 52,
			.NUM_5 = 53,
			.NUM_6 = 54,
			.NUM_7 = 55,
			.NUM_8 = 56,
			.NUM_9 = 57,
			.NUM_0 = 48,
			.SHIFT = 1073742049,
			.CTRL = 1073742048,
		},
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
