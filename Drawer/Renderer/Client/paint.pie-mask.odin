package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/List"
import "../../Renderer"
import "../../Shape"
import ShapeClient "../../Shape/Client"
import "core:math"
import "vendor:sdl3"

@(require_results)
createPieMask :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	metaConfig: Renderer.MetaConfig,
	config: Renderer.PieMaskConfig,
) -> (
	pieMaskId: Renderer.PieMaskId,
	paint: ^Renderer.Paint(Renderer.PieMask, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	paintId: Renderer.PaintId
	paintId, paint = createPaint(
		module,
		metaConfig,
		Renderer.PieMask {
			0,
			config,
			List.create(Renderer.Vertex, module.allocator) or_return,
			List.create(u32, module.allocator) or_return,
			config.startingFillPercentage,
		},
	) or_return
	pieMaskId = Renderer.PieMaskId(paintId)
	recalculatePieMask(module, paint) or_return
	return
}

@(require_results)
getPieMask :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	pieMaskId: Renderer.PieMaskId,
	required: bool,
) -> (
	pieMask: ^Renderer.Paint(Renderer.PieMask, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	pieMask, ok = getPaint(module, pieMaskId, Renderer.PieMask, required) or_return
	return
}

@(require_results)
updatePieMask :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	pieMaskId: Renderer.PieMaskId,
	fillPercentage: f32,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	pieMask, _ := getPieMask(module, pieMaskId, true) or_return
	pieMask.element.fillPercentage = fillPercentage
	recalculatePieMask(module, pieMask) or_return
	return
}
@(require_results)
removePieMask :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	pieMaskId: Renderer.PieMaskId,
	location := #caller_location,
) -> (
	paint: Renderer.Paint(Renderer.PieMask, TShapeName),
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "pieMaskId = {} ", pieMaskId)
	pieMask, _ := getPieMask(module, pieMaskId, true) or_return
	List.destroy(pieMask.element.indices, module.allocator) or_return
	List.destroy(pieMask.element.vertices, module.allocator) or_return
	paint = removePaint(module, pieMaskId, Renderer.PieMask) or_return
	return
}

@(require_results)
drawPieMask :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	pieMask: ^Renderer.Paint(Renderer.PieMask, TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	vertexPointers := make([^]sdl3.Vertex, len(pieMask.element.vertices), context.temp_allocator)
	for i in 0 ..< len(pieMask.element.vertices) {
		vertex := pieMask.element.vertices[i]
		destination: Math.Vector
		switch pieMask.config.positionType {
		case .CAMERA:
			destination = vertex.position
		case .MAP:
			destination = vertex.position - module.camera.bounds.position
		}
		vertexPointers[i] = {
			destination,
			sdl3.FColor {
				f32(vertex.color.r),
				f32(vertex.color.g),
				f32(vertex.color.b),
				f32(vertex.color.a),
			},
			vertex.textPosition,
		}
	}

	index_ptrs := make([^]i32, len(pieMask.element.indices), context.temp_allocator)
	for i in 0 ..< len(pieMask.element.indices) {
		index_ptrs[i] = i32(pieMask.element.indices[i])
	}
	shape: ^Shape.Shape(TMarkerName)
	switch v in pieMask.element.config.shapeName {
	case int:
		shape, _ = ShapeClient.get(module.shapeModule, TShapeName(v), true) or_return
	case string:
		shape, _ = ShapeClient.get(module.shapeModule, v, true) or_return
	}

	sdl3.SetTextureBlendMode(shape.texture, sdl3.BLENDMODE_BLEND)
	sdl3.RenderGeometry(
		module.renderer,
		shape.texture,
		vertexPointers,
		i32(len(pieMask.element.vertices)),
		index_ptrs,
		i32(len(pieMask.element.indices)),
	)
	return
}


@(private = "file")
@(require_results)
recalculatePieMask :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	pieMask: ^Renderer.Paint(Renderer.PieMask, TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	clear(&pieMask.element.vertices)
	clear(&pieMask.element.indices)
	if pieMask.element.fillPercentage == 0 {
		return
	}
	generatePieVertices(module, pieMask) or_return
	generateTriangleFanIndicies(pieMask) or_return
	return
}

@(private = "file")
@(require_results)
initPieData :: proc(
	destination: ^Math.Rectangle,
) -> (
	center: Math.Vector,
	uvCenter: Math.Vector,
	corners: [4]Math.Vector,
	uvCorners: [4]Math.Vector,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	center = Math.getRectangleCenter(destination^)
	uvCenter = {.5, .5}
	corners = {
		{destination.position.x, destination.position.y}, // Top-left
		{destination.position.x + destination.size.x, destination.position.y}, // Top-right
		{
			destination.position.x + destination.size.x,
			destination.position.y + destination.size.y,
		}, // Bottom-right
		{destination.position.x, destination.position.y + destination.size.y}, // Bottom-left
	}
	uvCorners = {
		{0, 0}, // Top-left
		{1, 0}, // Top-right
		{1, 1}, // Bottom-right
		{0, 1}, // Bottom-left
	}
	return
}
@(private = "file")
@(require_results)
generatePieVertices :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	pieMask: ^Renderer.Paint(Renderer.PieMask, TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	center, uvCenter, corners, uvCorners := initPieData(&pieMask.element.config.bounds) or_return
	List.push(
		&pieMask.element.vertices,
		Renderer.Vertex{center, Renderer.getColor(pieMask.config.color), uvCenter},
	) or_return
	segments := 64
	max_angle := pieMask.element.fillPercentage * 2.0 * math.PI
	radiansRotation: f32 = 270 * math.PI / 180.0

	for i in 0 ..= segments {
		angle :=
			radiansRotation +
			(-max_angle if pieMask.element.config.clockwise else max_angle) *
				f32(i) /
				f32(segments)
		cos_a := math.cos(angle)
		sin_a := math.sin(angle)
		dir := Math.Vector{cos_a, sin_a}
		max_t := math.INF_F32
		selectedUv := Math.Vector{}

		for j in 0 ..< 4 {
			next_j := (j + 1) % 4
			p1 := corners[j]
			p2 := corners[next_j]
			uv1 := uvCorners[j]
			uv2 := uvCorners[next_j]

			edge_dir := Math.Vector{p2.x - p1.x, p2.y - p1.y}
			denom := dir.x * edge_dir.y - dir.y * edge_dir.x
			if math.abs(denom) > .0001 {
				t := ((p1.x - center.x) * edge_dir.y - (p1.y - center.y) * edge_dir.x) / denom
				s := ((center.y - p1.y) * dir.x - (center.x - p1.x) * dir.y) / denom
				if t >= 0 && s >= 0 && s <= 1 && t < max_t {
					max_t = t
					selectedUv = Math.Vector {
						uv1.x + s * (uv2.x - uv1.x),
						uv1.y + s * (uv2.y - uv1.y),
					}
				}
			}
		}

		if max_t == math.INF_F32 {
			continue
		}
		List.push(
			&pieMask.element.vertices,
			Renderer.Vertex {
				Math.Vector{center.x + max_t * dir.x, center.y + max_t * dir.y},
				Renderer.getColor(pieMask.config.color),
				selectedUv,
			},
		) or_return
	}
	return
}

@(private = "file")
@(require_results)
generateTriangleFanIndicies :: proc(
	pieMask: ^Renderer.Paint(Renderer.PieMask, $TShapeName),
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	for i in 1 ..< len(pieMask.element.vertices) - 1 {
		List.push(&pieMask.element.indices, 0, u32(i), u32(i + 1)) or_return
	}
	return
}
