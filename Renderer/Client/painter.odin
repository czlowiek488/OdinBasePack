package RendererClient

import "../../../OdinBasePack"
import "../../Engine/Time"
import "../../Math"
import "../../Memory/SparseSet"
import "../../Renderer"
import "core:fmt"


@(private)
@(require_results)
drawFps :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	fps, potentialFps: Time.Fps,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	@(static) maybeStringId: Maybe(Renderer.StringId)
	fpsText := fmt.aprintf("{} / {}", fps, potentialFps, allocator = context.temp_allocator)
	if stringId, present := maybeStringId.?; present {
		removeString(module, stringId) or_return
	}
	maybeStringId = createString(
		module,
		{.USER_INTERFACE, 100_000, nil, .CAMERA, {.RED, 1, 1, nil}},
		{
			{
				{1, module.config.windowSize.y / module.config.tileScale - 10},
				{f32(len(fpsText)) * 5, 10},
			},
			fpsText,
		},
	) or_return
	return
}


@(require_results)
drawPaints :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	cameraPosition: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	updateCamera(module, cameraPosition) or_return
	clearScreen(module) or_return
	updateAllRenderOrder(module) or_return
	for renderOrder, layerId in getRenderOrder(module) or_return {
		for &order in SparseSet.list(renderOrder) or_return {
			paint, _ := getPaint(
				module,
				order.paintId,
				Renderer.PaintData(TShapeName),
				false,
			) or_return
			switch &paint in cast(^Renderer.PaintUnion(TShapeName))paint {
			case Renderer.Paint(Renderer.PieMask, TShapeName):
				drawPieMask(module, &paint) or_return
			case Renderer.Paint(Renderer.String, TShapeName):
				drawString(module, &paint) or_return
			case Renderer.Paint(Renderer.Rectangle, TShapeName):
				drawRectangle(module, &paint) or_return
			case Renderer.Paint(Renderer.Circle, TShapeName):
				drawCircle(module, &paint) or_return
			case Renderer.Paint(Renderer.Line, TShapeName):
				drawLine(module, &paint) or_return
			case Renderer.Paint(Renderer.Triangle, TShapeName):
				drawTriangle(module, &paint) or_return
			case Renderer.Paint(Renderer.Texture(TShapeName), TShapeName):
				drawTexture(module, &paint) or_return
			}
		}
	}
	return
}

@(require_results)
drawAll :: proc(
	module: ^Module($TImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	cameraPosition: Math.Vector,
	fps, potentialFps: Time.Fps,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	if module.config.drawFps {
		drawFps(module, fps, potentialFps) or_return
	}
	drawPaints(module, cameraPosition) or_return
	drawScreen(module) or_return
	return
}
