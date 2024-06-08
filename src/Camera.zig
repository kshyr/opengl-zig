const std = @import("std");
const math = @import("zalgebra");
const glfw = @import("mach-glfw");

const YAW: f32 = -70.0;
const PITCH: f32 = 0.0;
const SPEED: f32 = 2.5;
const SENSITIVITY: f32 = 0.1;
const ZOOM: f32 = 45.0;
const CONSTRAIN_PITCH: bool = true;

const MIN_ZOOM: f32 = 1.0;
const MAX_ZOOM: f32 = 45.0;

const CameraMovement = enum {
    forward,
    backward,
    left,
    right,
    up,
    down,
};

const Camera = @This();
position: math.Vec3,
front: math.Vec3,
up: math.Vec3,
right: math.Vec3,
world_up: math.Vec3,
yaw: f32,
pitch: f32,
movement_speed: f32,
mouse_sensitivity: f32,
zoom: f32,

pub fn new() Camera {
    return Camera{
        .position = math.Vec3.new(3.0, 5.0, 10.0),
        .front = math.Vec3.new(2.0, -1.0, -1.0),
        .right = math.Vec3.zero(),
        .up = math.Vec3.new(0.0, 4.0, 0.0),
        .world_up = math.Vec3.new(0.0, 1.0, 0.0),
        .yaw = YAW,
        .pitch = PITCH,
        .movement_speed = SPEED,
        .mouse_sensitivity = SENSITIVITY,
        .zoom = ZOOM,
    };
}

pub fn getViewMatrix(self: Camera) math.Mat4 {
    return math.lookAt(self.position, self.position.add(self.front), self.world_up);
}

pub fn handleKeyboard(self: *Camera, direction: CameraMovement, deltaTime: f32) void {
    const velocity = self.movement_speed * deltaTime;
    if (direction == CameraMovement.forward) {
        self.position = self.position.add(self.front.scale(velocity));
    }
    if (direction == CameraMovement.backward) {
        self.position = self.position.sub(self.front.scale(velocity));
    }
    if (direction == CameraMovement.left) {
        self.position = self.position.sub(self.right.scale(velocity));
    }
    if (direction == CameraMovement.right) {
        self.position = self.position.add(self.right.scale(velocity));
    }
    if (direction == CameraMovement.up) {
        self.position = self.position.add(self.up.scale(velocity));
    }
    if (direction == CameraMovement.down) {
        self.position = self.position.sub(self.up.scale(velocity));
    }
}

pub fn handleMouseMovement(self: *Camera, xoffset: f32, yoffset: f32) void {
    self.yaw += xoffset * self.mouse_sensitivity;
    self.pitch += yoffset * self.mouse_sensitivity;

    if (CONSTRAIN_PITCH) {
        if (self.pitch > 89.0) {
            self.pitch = 89.0;
        }
        if (self.pitch < -89.0) {
            self.pitch = -89.0;
        }
    }

    self.updateCameraVectors();
}

pub fn handleMouseScroll(self: *Camera, yoffset: f32) void {
    self.zoom -= yoffset * 10;

    if (self.zoom < MIN_ZOOM) {
        self.zoom = MIN_ZOOM;
    }
    if (self.zoom > MAX_ZOOM) {
        self.zoom = MAX_ZOOM;
    }
}

fn updateCameraVectors(self: *Camera) void {
    const front_x = std.math.cos(math.toRadians(self.yaw)) * std.math.cos(math.toRadians(self.pitch));
    const front_y = std.math.sin(math.toRadians(self.pitch));
    const front_z = std.math.sin(math.toRadians(self.yaw)) * std.math.cos(math.toRadians(self.pitch));
    const front = math.Vec3.new(front_x, front_y, front_z);
    self.front = front.norm();

    self.right = self.front.cross(self.world_up).norm();
    self.up = self.right.cross(self.front).norm();
}
