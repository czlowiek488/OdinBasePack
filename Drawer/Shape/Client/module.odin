package ShapeClient

import "../../../../OdinBasePack"
import "../../../Dictionary"
import "../../../Math"
import BitmapClient "../../Bitmap/Client"
import ImageClient "../../Image/Client"
import "../../Shape"
import "base:intrinsics"
import "vendor:sdl3"

Module :: struct(
	$TFileImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
) where intrinsics.type_is_enum(TShapeName) &&
	intrinsics.type_is_enum(TMarkerName) &&
	intrinsics.type_is_enum(TFileImageName)
{
	imageModule:     ^ImageClient.Module(TFileImageName),
	bitmapModule:    ^BitmapClient.Module(TBitmapName, TMarkerName),
	shapeConfigMap:  map[TShapeName]Shape.ImageShapeConfig(TFileImageName, TBitmapName),
	allocator:       OdinBasePack.Allocator,
	//
	shapeMap:        map[TShapeName]Shape.Shape(TMarkerName),
	dynamicShapeMap: map[string]Shape.Shape(TMarkerName),
	created:         bool,
}

@(require_results)
createModule :: proc(
	imageModule: ^ImageClient.Module($TFileImageName),
	bitmapModule: ^BitmapClient.Module($TBitmapName, $TMarkerName),
	allocator: OdinBasePack.Allocator,
	shapeConfigMap: map[$TShapeName]Shape.ImageShapeConfig(TFileImageName, TBitmapName),
) -> (
	module: Module(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	module.imageModule = imageModule
	module.bitmapModule = bitmapModule
	module.allocator = allocator
	module.shapeConfigMap = shapeConfigMap
	//
	module.shapeMap = Dictionary.create(
		TShapeName,
		Shape.Shape(TMarkerName),
		module.allocator,
	) or_return
	module.dynamicShapeMap = Dictionary.create(
		string,
		Shape.Shape(TMarkerName),
		module.allocator,
	) or_return
	return
}

@(require_results)
initializeModule :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for shapeName, config in module.shapeConfigMap {
		texture, _ := ImageClient.get(module.imageModule, config.imageFileName, true) or_return
		markerMap := BitmapClient.findShapeMarkerMap(
			module.bitmapModule,
			config.bitmapName,
			config.bounds,
		) or_return
		if texture == nil {
			error = .ENUM_CONVERSION_FAILED
			return
		}
		Dictionary.set(
			&module.shapeMap,
			shapeName,
			Shape.Shape(TMarkerName){texture, config.bounds, config.direction, markerMap},
		) or_return
	}
	module.created = true
	return
}

@(require_results)
loadDynamicShape :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	dynamicShapeName: string,
	dynamicImageName: string,
	bounds: Math.Rectangle,
	direction: Shape.ShapeDirection,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	texture, _ := ImageClient.get(module.imageModule, dynamicImageName, true) or_return
	markerMap := BitmapClient.findShapeMarkerMap(module.bitmapModule, nil, bounds) or_return
	Dictionary.set(
		&module.dynamicShapeMap,
		dynamicShapeName,
		Shape.Shape(TMarkerName){texture, bounds, direction, markerMap},
	) or_return
	return
}

@(require_results)
getFlipMode :: proc(
	direction: Shape.ShapeDirection,
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
get :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	shapeName: union {
		TShapeName,
		string,
	},
	required: bool,
) -> (
	shape: ^Shape.Shape(TMarkerName),
	present: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	switch value in shapeName {
	case TShapeName:
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
getMarker :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	shapeName: union {
		TShapeName,
		string,
	},
	markerName: TMarkerName,
) -> (
	vector: Math.Vector,
	present: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	shape: ^Shape.Shape(TMarkerName)
	shape, present = get(module, shapeName, false) or_return
	if !present {
		return
	}
	vector, present = shape.markerVectorMap[markerName]
	return
}
