const std = @import("std");
const math = @import("zalgebra");
const glfw = @import("mach-glfw");
const c = @cImport({
    @cInclude("glad/glad.h");
});
const Camera = @import("Camera.zig");
const Shader = @import("Shader.zig");
const Texture = @import("Texture.zig");

const print = std.debug.print;

const SCR_WIDTH = 800;
const SCR_HEIGHT = 600;

var camera = Camera.new();
var first_mouse = true;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    if (!glfw.init(.{})) {
        std.log.err("Failed to initialize GLFW", .{});
        return error.Initialization;
    }
    defer glfw.terminate();

    const hints = glfw.Window.Hints{
        .context_version_major = 3,
        .context_version_minor = 3,
        .opengl_profile = glfw.Window.Hints.OpenGLProfile.opengl_core_profile,
    };

    //#ifdef __APPLE__
    //    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GLFW_TRUE);
    //#endif

    const window: glfw.Window = glfw.Window.create(SCR_WIDTH, SCR_HEIGHT, "Hello, World", null, null, hints) orelse {
        std.log.err("Failed to create window", .{});
        return error.Initialization;
    };

    defer window.destroy();

    glfw.setErrorCallback(errorCallback);
    window.setFramebufferSizeCallback(frameBufferSizeCallback);
    window.setCursorPosCallback(cursorPosCallback);
    window.setScrollCallback(scrollCallback);
    glfw.makeContextCurrent(window);
    glfw.swapInterval(1);

    const loadproc: c.GLADloadproc = @ptrCast(&glfw.getProcAddress);
    if (c.gladLoadGLLoader(loadproc) == c.GL_FALSE) {
        std.log.err("Failed to load OpenGL", .{});
        return error.Initialization;
    }

    c.glDebugMessageCallback(glDebugCallback, null);
    c.glEnable(c.GL_DEBUG_OUTPUT);
    c.glEnable(c.GL_DEPTH_TEST);

    var shader = try Shader.new(allocator, "./src/shaders/vertex.glsl", "./src/shaders/fragment.glsl");
    const texture1 = try Texture.new("./src/assets/mario-brick.png", .{});
    const texture2 = try Texture.new("./src/assets/awesomeface.png", .{});

    // Set up vertex data (and buffer(s)) and attribute pointers

    const vertices = [_]f32{
        -0.5, -0.5, -0.5, 0.0, 0.0,
        0.5,  -0.5, -0.5, 1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        -0.5, 0.5,  -0.5, 0.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 0.0,

        -0.5, -0.5, 0.5,  0.0, 0.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5, 0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,

        -0.5, 0.5,  0.5,  1.0, 0.0,
        -0.5, 0.5,  -0.5, 1.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,
        -0.5, 0.5,  0.5,  1.0, 0.0,

        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, 0.5,  0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, -0.5, 1.0, 1.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,

        -0.5, 0.5,  -0.5, 0.0, 1.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5, 0.5,  0.5,  0.0, 0.0,
        -0.5, 0.5,  -0.5, 0.0, 1.0,
    };
    const cube_positions = [_]math.Vec3{
        math.Vec3.new(0.0, 0.0, 0.0),
        math.Vec3.new(2.0, 5.0, -15.0),
        math.Vec3.new(-1.5, -2.2, -2.5),
        math.Vec3.new(-3.8, -2.0, -12.3),
        math.Vec3.new(2.4, -0.4, -3.5),
        math.Vec3.new(-1.7, 3.0, -7.5),
        math.Vec3.new(1.3, -2.0, -2.5),
        math.Vec3.new(1.5, 2.0, -2.5),
        math.Vec3.new(1.5, 0.2, -1.5),
        math.Vec3.new(-1.3, 1.0, -1.5),
    };

    var VBO: u32 = undefined;
    var VAO: u32 = undefined;

    c.glGenVertexArrays(1, &VAO);
    c.glGenBuffers(1, &VBO);

    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    //c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    shader.use();
    shader.setInt("texture1", 0);
    shader.setInt("texture2", 1);

    var delta_time: f32 = 0.0;
    var last_frame: f32 = 0.0;

    while (!window.shouldClose()) {
        const current_frame: f32 = @floatCast(glfw.getTime());
        delta_time = current_frame - last_frame;
        last_frame = current_frame;

        camera.update(delta_time);

        window.setInputModeCursor(.captured);

        processInput(window);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture1.id);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, texture2.id);

        shader.use();

        shader.setMat4("projection", camera.projection);
        shader.setMat4("view", camera.view);

        c.glBindVertexArray(VAO);
        for (cube_positions, 0..) |position, i| {
            var model = math.Mat4.identity();
            model = math.Mat4.translate(model, position);
            const i_f: f32 = @floatFromInt(i);
            const angle: f32 = 100.0 * i_f * delta_time;
            model = math.Mat4.rotate(model, math.toRadians(angle), math.Vec3.new(2000.0, 2000.0, 2000.0));

            shader.setMat4("model", model);

            c.glDrawArrays(c.GL_TRIANGLES, 0, 36);
        }

        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn processInput(window: glfw.Window) void {
    const mouse_pos = window.getCursorPos();
    const mouse_x: f32 = @floatCast(mouse_pos.xpos);
    const mouse_y: f32 = @floatCast(mouse_pos.ypos);
    print("Mouse position: ({d}, {d})\n", .{ mouse_x, mouse_y });

    if (window.getKey(.w) == .press) {
        camera.position = camera.position.add(camera.front.scale(camera.speed));
    }
    if (window.getKey(.s) == .press) {
        camera.position = camera.position.sub(camera.front.scale(camera.speed));
    }
    if (window.getKey(.a) == .press) {
        camera.position = camera.position.sub(math.Vec3.norm(math.Vec3.cross(camera.front, camera.up)).scale(camera.speed));
    }
    if (window.getKey(.d) == .press) {
        camera.position = camera.position.add(math.Vec3.norm(math.Vec3.cross(camera.front, camera.up)).scale(camera.speed));
    }
    if (window.getKey(.space) == .press) {}
    if (window.getKey(.left_shift) == .press) {}
    if (window.getKey(.escape) == .press) {
        window.setShouldClose(true);
    }
}

fn cursorPosCallback(window: glfw.Window, xpos64: f64, ypos64: f64) void {
    _ = window;
    const xpos: f32 = @floatCast(xpos64);
    const ypos: f32 = @floatCast(ypos64);

    if (first_mouse) {
        camera.last_x = xpos;
        camera.last_y = ypos;
        first_mouse = false;
    }

    var xoffset: f32 = xpos - camera.last_x;
    var yoffset: f32 = camera.last_y - ypos;
    camera.last_x = xpos;
    camera.last_y = ypos;

    const sensitivity: f32 = 0.05;
    xoffset *= sensitivity;
    yoffset *= sensitivity;

    camera.yaw += xoffset;
    camera.pitch += yoffset;

    if (camera.pitch > 89.0) {
        camera.pitch = 89.0;
    }
    if (camera.pitch < -89.0) {
        camera.pitch = -89.0;
    }

    var front = math.Vec3.new(0.0, 0.0, 0.0);
    const front_x_ptr = front.xMut();
    const front_y_ptr = front.yMut();
    const front_z_ptr = front.zMut();

    front_x_ptr.* = std.math.cos(math.toRadians(camera.yaw)) * std.math.cos(math.toRadians(camera.pitch));
    front_y_ptr.* = std.math.sin(math.toRadians(camera.pitch));
    front_z_ptr.* = std.math.sin(math.toRadians(camera.yaw)) * std.math.cos(math.toRadians(camera.pitch));
    camera.front = math.Vec3.norm(front);
}

fn scrollCallback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
    _ = window;
    _ = xoffset;
    const scroll_sensitivity: f32 = 3.0;
    camera.fov -= @floatCast(yoffset * scroll_sensitivity);
    if (camera.fov < 1.0) {
        camera.fov = 1.0;
    }
    if (camera.fov > 45.0) {
        camera.fov = 45.0;
    }
}

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn frameBufferSizeCallback(window: glfw.Window, width: u32, height: u32) void {
    _ = window;
    const gl_width: c_int = @intCast(width);
    const gl_height: c_int = @intCast(height);
    c.glViewport(0, 0, gl_width, gl_height);
}

fn glDebugCallback(
    source: c.GLenum,
    type_: c.GLenum,
    id: c.GLuint,
    severity: c.GLenum,
    length: c.GLsizei,
    message: [*c]const c.GLchar,
    user_param: ?*const anyopaque,
) callconv(.C) void {
    _ = source;
    _ = type_;
    _ = severity;
    _ = length;
    _ = user_param;

    std.log.err("OpenGL error {d}: {s}", .{ id, message });
}
