package SteerClient

import "../../../../OdinBasePack"
import "../../../Drawer/Painter"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../EventLoop"
import "../../../Math"
import "../../../Memory/Dictionary"
import "../../Steer"
import "vendor:sdl3"

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
			.W = sdl3.K_W,
			.S = sdl3.K_S,
			.D = sdl3.K_A,
			.A = sdl3.K_D,
			.Q = sdl3.K_Q,
			.E = sdl3.K_E,
			.I = sdl3.K_I,
			.U = sdl3.K_U,
			.F1 = sdl3.K_F1,
			.F2 = sdl3.K_F2,
			.ESC = sdl3.K_ESCAPE,
			.NUM_1 = sdl3.K_1,
			.NUM_2 = sdl3.K_2,
			.NUM_3 = sdl3.K_3,
			.NUM_4 = sdl3.K_4,
			.NUM_5 = sdl3.K_5,
			.NUM_6 = sdl3.K_6,
			.NUM_7 = sdl3.K_7,
			.NUM_8 = sdl3.K_8,
			.NUM_9 = sdl3.K_9,
			.NUM_0 = sdl3.K_0,
			.SHIFT = sdl3.K_LSHIFT,
			.CTRL = sdl3.K_LCTRL,
		},
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	return
}
