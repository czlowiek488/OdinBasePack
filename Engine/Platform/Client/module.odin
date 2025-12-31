package PlatformClient

import "../../../EventLoop"
import CursorClient "../../Cursor/Client"
import "../../Platform"
import SteerClient "../../Steer/Client"
import UiClient "../../Ui/Client"
import "core:log"
import "vendor:sdl3"

ModuleConfig :: struct {
	logAllSdlEvents:       bool,
	logUnhandledSdlEvents: bool,
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
	$TEntityHitBoxType: typeid,
)
{
	config:       ModuleConfig,
	steerModule:  ^SteerClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	cursorModule: ^CursorClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	uiModule:     ^UiClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
		TEntityHitBoxType,
	),
	eventLoop:    ^EventLoop.EventLoop(
		64,
		.SPSC_MUTEX,
		TEventLoopTask,
		TEventLoopTask,
		64,
		.SPSC_MUTEX,
		TEventLoopResult,
		TError,
	),
	clickTarget:  Platform.ClickTarget,
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
	cursorModule: ^CursorClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
	),
	uiModule: ^UiClient.Module(
		TEventLoopTask,
		TEventLoopResult,
		TError,
		TFileImageName,
		TBitmapName,
		TMarkerName,
		TShapeName,
		TAnimationName,
		$TEntityHitBoxType,
	),
	config: ModuleConfig,
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
		TEntityHitBoxType,
	),
	error: TError,
) {
	module.eventLoop = eventLoop
	module.config = config
	module.steerModule = steerModule
	module.uiModule = uiModule
	module.cursorModule = cursorModule
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
		$TEntityHitBoxType,
	),
) -> (
	error: TError,
) {
	event: sdl3.Event
	if module.config.logAllSdlEvents {
		log.infof("sdl3Event = {}", event)
	}
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
			CursorClient.handleMouseClick(module.cursorModule, buttonName, .PRESSED) or_return
			UiClient.mouseButtonDown(module.uiModule, buttonName) or_return
			if UiClient.isHovered(module.uiModule) or_return {
				module.clickTarget = .UI
				return
			}
			module.clickTarget = .MAP
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
			CursorClient.handleMouseClick(module.cursorModule, buttonName, .RELEASED) or_return
			switch module.clickTarget {
			case .MAP:
				if UiClient.isHovered(module.uiModule) or_return {
					return
				}
				module.eventLoop->task(
					.TIMEOUT,
					0,
					Platform.PlatformEvent(Platform.MouseButtonPlatformEvent{buttonName, false}),
				) or_return
			case .UI:
				if !(UiClient.isHovered(module.uiModule) or_return) {
					module.eventLoop->task(
						.TIMEOUT,
						0,
						Platform.PlatformEvent(
							Platform.MouseButtonPlatformEvent{buttonName, false},
						),
					) or_return
				}
				UiClient.mouseButtonUp(module.uiModule, buttonName) or_return
			}
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
		case:
			if module.config.logUnhandledSdlEvents {
				log.infof("unhandled sdl3Event = {}", event)
			}
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
