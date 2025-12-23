package SteerClient

import "../../../OdinBasePack"
import "../../Dictionary"
import "../../Drawer/Painter"
import PainterClient "../../Drawer/Painter/Client"
import "../../EventLoop"
import "../../Math"
import "../../Steer"

ManagerConfig :: struct #all_or_none {
	logPressedKey:         bool,
	printMouseCoordinates: bool,
	tileScale:             f32,
	windowSize:            Math.Vector,
}

Manager :: struct(
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
	painterManager:        ^PainterClient.Manager(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	config:                ManagerConfig,
	allocator:             OdinBasePack.Allocator,
	//
	steer:                 Steer.Steer,
	mousePositionStringId: Maybe(Painter.StringId),
	created:               bool,
}

@(require_results)
createManager :: proc(
	painterManager: ^PainterClient.Manager(
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
	config: ManagerConfig,
	allocator: OdinBasePack.Allocator,
) -> (
	manager: Manager(
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
	manager.painterManager = painterManager
	manager.allocator = allocator
	manager.config = config
	//
	manager.steer.keyboard.keyMap, err = Dictionary.create(
		Steer.KeyboardKeyName,
		Steer.SteerButton,
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.steer.mouse.buttonMap, err = Dictionary.create(
		Steer.MouseButtonName,
		Steer.SteerButton,
		manager.allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	manager.created = true
	return
}


@(require_results)
initializeMouseAndKeyboardState :: proc(
	manager: ^Manager(
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
			&manager.steer.mouse.buttonMap,
			buttonName,
			Steer.SteerButton{false, false},
		)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
	}
	for keyName in Steer.KeyboardKeyName {
		err = Dictionary.set(
			&manager.steer.keyboard.keyMap,
			keyName,
			Steer.SteerButton{false, false},
		)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
	}
	err = loadKeyboardMapping(
		manager,
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
			.NUM_0 = 58,
			.SHIFT = 1073742049,
			.CTRL = 1073742048,
		},
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}
