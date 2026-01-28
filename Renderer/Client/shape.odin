package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/AutoSet"
import "../../Memory/Dictionary"
import "../../Renderer"
import "base:intrinsics"
import "vendor:sdl3"
import "vendor:sdl3/ttf"

@(require_results)
registerShape :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	shapeName: int,
	config: Renderer.ImageShapeConfig(TImageName, TBitmapName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	texture, _ := getImage(module, config.imageFileName, true) or_return
	markerMap := findShapeMarkerMap(module, config.bitmapName, config.bounds) or_return
	if texture == nil {
		error = .ENUM_CONVERSION_FAILED
		return
	}
	Dictionary.set(
		&module.shapeMap,
		shapeName,
		Renderer.Shape(TMarkerName){texture, config.bounds, config.direction, markerMap},
	) or_return
	return
}

@(require_results)
loadDynamicShape :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName),
	dynamicShapeName: string,
	dynamicImageName: string,
	bounds: Math.Rectangle,
	direction: Renderer.ShapeDirection,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	texture, _ := getImage(module, dynamicImageName, true) or_return
	markerMap := findShapeMarkerMap(module, nil, bounds) or_return
	Dictionary.set(
		&module.dynamicShapeMap,
		dynamicShapeName,
		Renderer.Shape(TMarkerName){texture, bounds, direction, markerMap},
	) or_return
	return
}

@(require_results)
getFlipMode :: proc(
	direction: Renderer.ShapeDirection,
) -> (
	flipMode: sdl3.FlipMode,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	switch direction {
	case .LEFT_RIGHT:
		flipMode = .NONE
	case .RIGHT_LEFT:
		flipMode = .HORIZONTAL
	case:
		error = .INVALID_ENUM_VALUE
	}
	return
}

@(require_results)
getShape :: proc(module: ^Module($TImageName, $TBitmapName, $TMarkerName), shapeName: union {
		int,
		string,
	}, required: bool) -> (shape: ^Renderer.Shape(TMarkerName), present: bool, error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	switch value in shapeName {
	case int:
		shape, present = &module.shapeMap[value]
	case string:
		shape, present = &module.dynamicShapeMap[value]
	}
	if !present && required {
		error = .SHAPE_MUST_EXISTS
	}
	return
}

@(require_results)
getMarker :: proc(module: ^Module($TImageName, $TBitmapName, $TMarkerName), shapeName: union {
		int,
		string,
	}, markerName: TMarkerName) -> (vector: Math.Vector, present: bool, error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	shape: ^Renderer.Shape(TMarkerName)
	shape, present = getShape(module, shapeName, false) or_return
	if !present {
		return
	}
	vector, present = shape.markerVectorMap[markerName]
	return
}
