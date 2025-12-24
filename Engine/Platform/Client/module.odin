package PlatformClient

import "../../../EventLoop"
import "../../Platform"
import SteerClient "../../Steer/Client"
import "vendor:sdl3"

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
	eventLoop:   ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
}

@(require_results)
createModule :: proc(
	steerModule: ^SteerClient.Module(
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
	module.eventLoop = eventLoop
	module.steerModule = steerModule
	return
}

@(require_results)
processBackgroundEvents :: proc(
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
	event: sdl3.Event
	for sdl3.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			module.eventLoop->task(
				.TIMEOUT,
				0,
				Platform.PlatformEvent(Platform.QuitPlatformEvent{}),
			) or_return
		case .MOUSE_MOTION:
			module.eventLoop->task(
				.TIMEOUT,
				0,
				Platform.PlatformEvent(
					Platform.MouseMotionPlatformEvent {
						{event.motion.x, event.motion.y},
						{event.motion.xrel, event.motion.yrel},
					},
				),
			) or_return
		case .MOUSE_BUTTON_DOWN:
			buttonName := SteerClient.buttonIdToButtonName(
				module.steerModule,
				event.button.button,
			) or_return
			module.eventLoop->task(
				.TIMEOUT,
				0,
				Platform.PlatformEvent(Platform.MouseButtonPlatformEvent{buttonName, true}),
			) or_return
		case .MOUSE_BUTTON_UP:
			buttonName := SteerClient.buttonIdToButtonName(
				module.steerModule,
				event.button.button,
			) or_return
			module.eventLoop->task(
				.TIMEOUT,
				0,
				Platform.PlatformEvent(Platform.MouseButtonPlatformEvent{buttonName, false}),
			) or_return
		case .MOUSE_WHEEL:
			if event.wheel.y == 0 {
				return
			}
			module.eventLoop->task(
				.TIMEOUT,
				0,
				Platform.PlatformEvent(Platform.MouseWheelPlatformEvent{event.wheel.y}),
			) or_return

		case .KEY_DOWN:
			steerEvent, found := SteerClient.handleKeyboardSDLEvent(
				module.steerModule,
				event.key.key,
				.PRESSED,
			) or_return
			if !found {
				return
			}
			module.eventLoop->task(
				.TIMEOUT,
				0,
				Platform.PlatformEvent(Platform.KeyboardButtonPlatformEvent{steerEvent, true}),
			) or_return
		case .KEY_UP:
			steerEvent, found := SteerClient.handleKeyboardSDLEvent(
				module.steerModule,
				event.key.key,
				.RELEASED,
			) or_return
			if !found {
				return
			}
			module.eventLoop->task(
				.TIMEOUT,
				0,
				Platform.PlatformEvent(Platform.KeyboardButtonPlatformEvent{steerEvent, false}),
			) or_return
		}
	}
	return
}


@(require_results)
getError :: proc() -> (errorMessage: Maybe(cstring)) {
	sdl3Error := sdl3.GetError()
	if len(sdl3Error) == 0 {
		return
	}
	errorMessage = sdl3Error
	return
}
