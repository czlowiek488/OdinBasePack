package SteerClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Renderer"
import RendererClient "../../../Renderer/Client"
import "../../Steer"
import "core:fmt"

@(require_results)
buttonIdToButtonName :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	buttonId: u8,
) -> (
	buttonName: Steer.MouseButtonName,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	switch buttonId {
	case 1:
		buttonName = .LEFT
	case 3:
		buttonName = .RIGHT
	case:
		error = .INVALID_ENUM_VALUE
	}
	return
}

@(require_results)
updateMousePosition :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
	positionOnScreen, positionOnMap, delta: Math.Vector,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	module.steer.mouse.positionOnScreen = positionOnScreen
	module.steer.mouse.positionOnMap = positionOnMap
	module.steer.mouse.delta = delta
	module.steer.mouse.inWindow = Math.isPointCollidingWithRectangle(
		{{0, 0}, module.config.windowSize},
		positionOnMap + delta,
	)
	if stringId, present := module.mousePositionStringId.?; present {
		err := RendererClient.removeString(module.rendererModule, stringId)
		module.eventLoop.mapper(err) or_return
		module.mousePositionStringId = nil
	}
	if !module.printMouseCoordinates {
		return
	}
	text := fmt.aprintf(
		"{}:{}",
		int(positionOnMap.x / module.config.tileScale),
		int(positionOnMap.y / module.config.tileScale),
		allocator = context.temp_allocator,
	)
	module.mousePositionStringId, err = RendererClient.createString(
		module.rendererModule,
		{.USER_INTERFACE, 0, nil, .CAMERA, {.WHITE, 1, 1, nil}},
		{{{1, 1}, {30, 4}}, text},
	)
	module.eventLoop.mapper(err) or_return
	return
}

@(require_results)
getMousePositionOnMap :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
) -> (
	mousePosition: Math.Vector,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	mousePosition = module.steer.mouse.positionOnMap / module.config.tileScale
	return
}

@(require_results)
getMousePositionOnScreen :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
) -> (
	mousePosition: Math.Vector,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	mousePosition = module.steer.mouse.positionOnScreen
	return
}

@(require_results)
getMouseDelta :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
) -> (
	delta: Math.Vector,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	delta = module.steer.mouse.delta
	return
}


@(require_results)
isMouseInWindow :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
) -> (
	isInWindow: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	isInWindow = module.steer.mouse.inWindow
	return
}
