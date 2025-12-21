package ShapeClient

import "../../../../OdinBasePack"
import "../../../Dictionary"
import "../../../Math"
import BitmapClient "../../Bitmap/Client"
import ImageClient "../../Image/Client"
import "../../Shape"
import "base:intrinsics"
import "vendor:sdl3"

Manager :: struct(
	$TFileImageName: typeid,
	$TBitmapName: typeid,
	$TMarkerName: typeid,
	$TShapeName: typeid,
) where intrinsics.type_is_enum(TShapeName) &&
	intrinsics.type_is_enum(TMarkerName) &&
	intrinsics.type_is_enum(TFileImageName)
{
	imageManager:    ^ImageClient.Manager(TFileImageName),
	bitmapManager:   ^BitmapClient.Manager(TBitmapName, TMarkerName),
	shapeConfigMap:  map[TShapeName]Shape.ImageShapeConfig(TFileImageName, TBitmapName),
	allocator:       OdinBasePack.Allocator,
	//
	shapeMap:        map[TShapeName]Shape.Shape(TMarkerName),
	dynamicShapeMap: map[string]Shape.Shape(TMarkerName),
	created:         bool,
}

@(require_results)
createManager :: proc(
	imageManager: ^ImageClient.Manager($TFileImageName),
	bitmapManager: ^BitmapClient.Manager($TBitmapName, $TMarkerName),
	allocator: OdinBasePack.Allocator,
	shapeConfigMap: map[$TShapeName]Shape.ImageShapeConfig(TFileImageName, TBitmapName),
) -> (
	manager: Manager(TFileImageName, TBitmapName, TMarkerName, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	manager.imageManager = imageManager
	manager.bitmapManager = bitmapManager
	manager.allocator = allocator
	manager.shapeConfigMap = shapeConfigMap
	//
	manager.shapeMap = Dictionary.create(
		TShapeName,
		Shape.Shape(TMarkerName),
		manager.allocator,
	) or_return
	manager.dynamicShapeMap = Dictionary.create(
		string,
		Shape.Shape(TMarkerName),
		manager.allocator,
	) or_return
	return
}

@(require_results)
initializeManager :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for shapeName, config in manager.shapeConfigMap {
		texture, _ := ImageClient.get(manager.imageManager, config.imageFileName, true) or_return
		markerMap := BitmapClient.findShapeMarkerMap(
			manager.bitmapManager,
			config.bitmapName,
			config.bounds,
		) or_return
		if texture == nil {
			error = .ENUM_CONVERSION_FAILED
			return
		}
		Dictionary.set(
			&manager.shapeMap,
			shapeName,
			Shape.Shape(TMarkerName){texture, config.bounds, config.direction, markerMap},
		) or_return
	}
	manager.created = true
	return
}

@(require_results)
loadDynamicShape :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	dynamicShapeName: string,
	dynamicImageName: string,
	bounds: Math.Rectangle,
	direction: Shape.ShapeDirection,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	texture, _ := ImageClient.get(manager.imageManager, dynamicImageName, true) or_return
	markerMap := BitmapClient.findShapeMarkerMap(manager.bitmapManager, nil, bounds) or_return
	Dictionary.set(
		&manager.dynamicShapeMap,
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
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
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
		shape, present = &manager.shapeMap[value]
	case string:
		shape, present = &manager.dynamicShapeMap[value]
	}
	if !present && required {
		error = .SHAPE_MUST_EXISTS
	}
	return
}

@(require_results)
getMarker :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
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
	shape, present = get(manager, shapeName, false) or_return
	if !present {
		return
	}
	vector, present = shape.markerVectorMap[markerName]
	return
}
