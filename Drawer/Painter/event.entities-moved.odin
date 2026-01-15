package Painter

import "../../EventLoop"
import "../../Math"

EntityMove :: struct {
	entityId:    int,
	newPosition: Math.Vector,
	change:      Math.Vector,
}

EntitiesMovedEvent :: EventLoop.ListCommand(32, EntityMove)
