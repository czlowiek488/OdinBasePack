package Steer

SteerButton :: struct {
	pressed:  bool,
	released: bool,
}


Steer :: struct {
	mouse:    Mouse,
	keyboard: Keyboard,
}
