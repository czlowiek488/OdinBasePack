package PainterClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../SparseSet"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
drawAll :: proc(
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
	cameraPosition: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	RendererClient.updateCamera(manager.rendererManager, cameraPosition) or_return
	RendererClient.clearScreen(manager.rendererManager) or_return
	for renderOrder, layerId in RendererClient.getRenderOrder(manager.rendererManager) or_return {
		for &order in SparseSet.list(renderOrder) or_return {
			paint, _ := RendererClient.getPaint(
				manager.rendererManager,
				order.paintId,
				Renderer.PaintData(TShapeName, TAnimationName),
				false,
			) or_return
			switch &paint in cast(^Renderer.PaintUnion(TShapeName, TAnimationName))paint {
			case Renderer.Paint(
				     Renderer.Animation(TShapeName, TAnimationName),
				     TShapeName,
				     TAnimationName,
			     ):
			case Renderer.Paint(Renderer.PieMask, TShapeName, TAnimationName):
				RendererClient.drawPieMask(manager.rendererManager, &paint) or_return
			case Renderer.Paint(Renderer.String, TShapeName, TAnimationName):
				RendererClient.drawString(manager.rendererManager, &paint) or_return
			case Renderer.Paint(Renderer.Rectangle, TShapeName, TAnimationName):
				RendererClient.drawRectangle(manager.rendererManager, &paint) or_return
			case Renderer.Paint(Renderer.Circle, TShapeName, TAnimationName):
				RendererClient.drawCircle(manager.rendererManager, &paint) or_return
			case Renderer.Paint(Renderer.Line, TShapeName, TAnimationName):
				RendererClient.drawLine(manager.rendererManager, &paint) or_return
			case Renderer.Paint(Renderer.Triangle, TShapeName, TAnimationName):
				RendererClient.drawTriangle(manager.rendererManager, &paint) or_return
			case Renderer.Paint(Renderer.Texture(TShapeName), TShapeName, TAnimationName):
				RendererClient.drawTexture(manager.rendererManager, &paint) or_return
			}
		}
	}
	RendererClient.drawScreen(manager.rendererManager) or_return
	return
}
