package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../SparseSet"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
drawAll :: proc(
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
	cameraPosition: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	RendererClient.updateCamera(module.rendererModule, cameraPosition) or_return
	RendererClient.clearScreen(module.rendererModule) or_return
	for renderOrder, layerId in RendererClient.getRenderOrder(module.rendererModule) or_return {
		for &order in SparseSet.list(renderOrder) or_return {
			paint, _ := RendererClient.getPaint(
				module.rendererModule,
				order.paintId,
				Renderer.PaintData(TShapeName),
				false,
			) or_return
			switch &paint in cast(^Renderer.PaintUnion(TShapeName))paint {
			case Renderer.Paint(Renderer.PieMask, TShapeName):
				RendererClient.drawPieMask(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.String, TShapeName):
				RendererClient.drawString(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Rectangle, TShapeName):
				RendererClient.drawRectangle(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Circle, TShapeName):
				RendererClient.drawCircle(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Line, TShapeName):
				RendererClient.drawLine(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Triangle, TShapeName):
				RendererClient.drawTriangle(module.rendererModule, &paint) or_return
			case Renderer.Paint(Renderer.Texture(TShapeName), TShapeName):
				RendererClient.drawTexture(module.rendererModule, &paint) or_return
			}
		}
	}
	RendererClient.drawScreen(module.rendererModule) or_return
	return
}
