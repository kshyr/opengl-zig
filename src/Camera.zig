const std = @import("std");
const math = @import("zalgebra");
const glfw = @import("mach-glfw");

const Camera = @This();
view: math.Mat4,
projection: math.Mat4,
direction: math.Vec3,
position: math.Vec3,
target: math.Vec3,
up: math.Vec3,
right: math.Vec3,
front: math.Vec3,
yaw: f32,
pitch: f32,
fov: f32,
speed: f32,
last_x: f32,
last_y: f32,

pub fn new() Camera {
    const view = math.Mat4.identity();
    const projection = math.Mat4.identity();
    const position = math.Vec3.new(0.0, 0.0, 3.0);
    const target = math.Vec3.new(0.0, 0.0, 0.0);
    const direction = math.Vec3.norm(math.Vec3.sub(position, target));
    const up_axis = math.Vec3.new(0.0, 1.0, 0.0);
    const right = math.Vec3.norm(math.Vec3.cross(up_axis, direction));
    const up = math.Vec3.cross(direction, right);
    const front = math.Vec3.new(0.0, 0.0, -1.0);
    const speed = 0.02;
    const last_x = 800.0 / 2.0;
    const last_y = 600.0 / 2.0;
    const yaw = -90.0;
    const pitch = 0.0;
    const fov = 45.0;

    return Camera{
        .view = view,
        .projection = projection,
        .direction = direction,
        .position = position,
        .target = target,
        .up = up,
        .right = right,
        .front = front,
        .speed = speed,
        .last_x = last_x,
        .last_y = last_y,
        .yaw = yaw,
        .pitch = pitch,
        .fov = fov,
    };
}

pub fn update(self: *Camera, delta_time: f32) void {
    self.speed = 2.5 * delta_time;

    const aspect_ratio: f32 = 800 / 600;
    self.projection = math.perspective(self.fov, aspect_ratio, 0.1, 100.0);

    self.view = math.Mat4.lookAt(self.position, math.Vec3.add(self.position, self.front), self.up);
}
