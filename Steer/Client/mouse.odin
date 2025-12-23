package SteerClient

import "../../../OdinBasePack"
import "../../Drawer/Painter"
import PainterClient "../../Drawer/Painter/Client"
import "../../Math"
import "../../Steer"
import "core:fmt"

@(require_results)
buttonIdToButtonName :: proc(
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
	positionOnScreen, positionOnMap, delta: Math.Vector,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	manager.steer.mouse.positionOnScreen = positionOnScreen
	manager.steer.mouse.positionOnMap = positionOnMap
	manager.steer.mouse.delta = delta
	manager.steer.mouse.inWindow = Math.isPointCollidingWithRectangle(
		{{0, 0}, manager.config.windowSize},
		positionOnMap + delta,
	)
	if stringId, present := manager.mousePositionStringId.?; present {
		PainterClient.removeString(manager.painterManager, stringId) or_return
	}
	if manager.config.printMouseCoordinates {
		text := fmt.aprintf(
			"{}:{}",
			int(positionOnMap.x / manager.config.tileScale),
			int(positionOnMap.y / manager.config.tileScale),
			allocator = context.temp_allocator,
		)
		manager.mousePositionStringId = PainterClient.createString(
			manager.painterManager,
			{.PANEL_17, nil, .CAMERA, Painter.getColorFromName(.WHITE)},
			{{{1, 1}, {30, 4}}, text},
		) or_return
	}
	return
}

@(require_results)
getMousePositionOnMap :: proc(
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
	mousePosition: Math.Vector,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	mousePosition = manager.steer.mouse.positionOnMap / manager.config.tileScale
	return
}

@(require_results)
getMousePositionOnScreen :: proc(
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
	mousePosition: Math.Vector,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	mousePosition = manager.steer.mouse.positionOnScreen
	return
}

@(require_results)
getMouseDelta :: proc(
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
	delta: Math.Vector,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	delta = manager.steer.mouse.delta
	return
}


@(require_results)
isMouseInWindow :: proc(
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
	isInWindow: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	isInWindow = manager.steer.mouse.inWindow
	return
}
