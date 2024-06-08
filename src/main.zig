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

const SCR_WIDTH: f32 = 800;
const SCR_HEIGHT: f32 = 600;
const ASPECT_RATIO: f32 = SCR_WIDTH / SCR_HEIGHT;

var camera = Camera.new();
var last_x: f32 = SCR_WIDTH / 2.0;
var last_y: f32 = SCR_HEIGHT / 2.0;
var first_mouse = true;
var delta_time: f32 = 0.0;
var last_frame: f32 = 0.0;

var light_pos = math.Vec3.new(3.2, 1.0, 2.0);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) {
            print("gpa leaked\n", .{});
        }
    }
    const allocator = gpa.allocator();

    if (!glfw.init(.{})) {
        std.log.err("Failed to initialize GLFW", .{});
        return error.Initialization;
    }
    defer glfw.terminate();

    const hints = glfw.Window.Hints{
        .context_version_major = 4,
        .context_version_minor = 6,
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
    window.setInputModeCursor(.disabled);

    const loadproc: c.GLADloadproc = @ptrCast(&glfw.getProcAddress);
    if (c.gladLoadGLLoader(loadproc) == c.GL_FALSE) {
        std.log.err("Failed to load OpenGL", .{});
        return error.Initialization;
    }

    c.glDebugMessageCallback(glDebugCallback, null);
    c.glEnable(c.GL_DEBUG_OUTPUT);
    c.glEnable(c.GL_DEPTH_TEST);

    var lighting_shader = try Shader.new(allocator, "./src/shaders/vertex.glsl", "./src/shaders/fragment.glsl");
    var light_cube_shader = try Shader.new(allocator, "./src/shaders/light_cube_vertex.glsl", "./src/shaders/light_cube_fragment.glsl");
    const texture1 = try Texture.new("./src/assets/wall.jpg", .{});
    _ = texture1; // autofix

    const vertices = [_]f32{
        -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0,
        0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0,
        0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0,
        0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0,
        -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0,
        -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0,

        -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,
        0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,
        0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
        0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
        -0.5, 0.5,  0.5,  0.0,  0.0,  1.0,
        -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,

        -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,
        -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,
        -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,
        -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,
        -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,
        -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,

        0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
        0.5,  0.5,  -0.5, 1.0,  0.0,  0.0,
        0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,
        0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,
        0.5,  -0.5, 0.5,  1.0,  0.0,  0.0,
        0.5,  0.5,  0.5,  1.0,  0.0,  0.0,

        -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,
        0.5,  -0.5, -0.5, 0.0,  -1.0, 0.0,
        0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
        0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
        -0.5, -0.5, 0.5,  0.0,  -1.0, 0.0,
        -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,

        -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,
        0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,
        0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
        0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
        -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,
        -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,
        -3.5, -1.5, -0.5, 0.0,  0.0,  -1.0,
        -3.5, -1.5, -1.5, 0.0,  0.0,  -1.0,
        -3.5, -1.5, -1.5, 0.0,  0.0,  -1.0,
        -3.5, -1.5, -1.5, 0.0,  0.0,  -1.0,
        -3.5, -1.5, -1.5, 0.0,  0.0,  -1.0,
        -3.5, -1.5, -1.5, 0.0,  0.0,  -1.0,

        -3.5, -1.5, 0.4,  0.0,  0.0,  1.0,
        -3.5, -1.5, 0.4,  0.0,  0.0,  1.0,
        -3.5, -1.5, 0.4,  0.0,  0.0,  1.0,
        -3.5, -1.5, 0.4,  0.0,  0.0,  1.0,
        -3.5, -1.5, 0.4,  0.0,  0.0,  1.0,
        -3.5, -1.5, 0.4,  0.0,  0.0,  1.0,

        -3.5, -1.5, 0.4,  -1.0, 0.0,  0.0,
        -3.5, -1.5, -1.5, -1.0, 0.0,  0.0,
        -3.5, -1.5, -1.5, -1.0, 0.0,  0.0,
        -3.5, -1.5, -1.5, -1.0, 0.0,  0.0,
        -3.5, -1.5, 0.4,  -1.0, 0.0,  0.0,
        -3.5, -1.5, 0.4,  -1.0, 0.0,  0.0,

        -3.5, -1.5, 0.4,  1.0,  0.0,  0.0,
        -3.5, -1.5, -1.5, 1.0,  0.0,  0.0,
        -3.5, -1.5, -1.5, 1.0,  0.0,  0.0,
        -3.5, -1.5, -1.5, 1.0,  0.0,  0.0,
        -3.5, -1.5, 0.4,  1.0,  0.0,  0.0,
        -3.5, -1.5, 0.4,  1.0,  0.0,  0.0,

        -3.5, -1.5, -1.5, 0.0,  -1.0, 0.0,
        -3.5, -1.5, -1.5, 0.0,  -1.0, 0.0,
        -3.5, -1.5, 0.4,  0.0,  -1.0, 0.0,
        -3.5, -1.5, 0.4,  0.0,  -1.0, 0.0,
        -3.5, -1.5, 0.4,  0.0,  -1.0, 0.0,
        -3.5, -1.5, -1.5, 0.0,  -1.0, 0.0,

        -3.5, -1.5, -1.5, 0.0,  1.0,  0.0,
        -3.5, -1.5, -1.5, 0.0,  1.0,  0.0,
        -3.5, -1.5, 0.4,  0.0,  1.0,  0.0,
        -3.5, -1.5, 0.4,  0.0,  1.0,  0.0,
        -3.5, -1.5, 0.4,  0.0,  1.0,  0.0,
        -3.5, -1.5, -1.5, 0.0,  1.0,  0.0,
    };

    var vbo: u32 = undefined;
    var cube_vao: u32 = undefined;

    c.glGenVertexArrays(1, &cube_vao);
    c.glGenBuffers(1, &vbo);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    c.glBindVertexArray(cube_vao);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    var light_cube_vao: u32 = undefined;
    c.glGenVertexArrays(1, &light_cube_vao);
    c.glBindVertexArray(light_cube_vao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    // c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    while (!window.shouldClose()) {
        const current_frame: f32 = @floatCast(glfw.getTime());
        delta_time = current_frame - last_frame;
        last_frame = current_frame;

        processInput(window);

        c.glClearColor(0, 0, 0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        lighting_shader.use();
        lighting_shader.setVec3("objectColor", math.Vec3.new(1.0, 0.5, 0.31));
        lighting_shader.setVec3("lightColor", math.Vec3.new(1.0, 1.0, 1.0));
        lighting_shader.setVec3("lightPos", light_pos);

        // make lightPos move in a circle
        const light_pos_x = 1.0 + std.math.sin(current_frame) * 10.0;
        const light_pos_y = 1.0 + std.math.sin(current_frame / 2.0) * 10.0;

        light_pos = math.Vec3.new(light_pos_x, light_pos_y, 2.0);

        const projection = math.Mat4.perspective(camera.zoom, ASPECT_RATIO, 0.001, 1000.0);
        const view = camera.getViewMatrix();
        lighting_shader.setMat4("projection", projection);
        lighting_shader.setMat4("view", view);

        var model = math.Mat4.identity();
        lighting_shader.setMat4("model", model);

        c.glBindVertexArray(cube_vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 72);

        light_cube_shader.use();
        light_cube_shader.setMat4("projection", projection);
        light_cube_shader.setMat4("view", view);
        model = math.Mat4.identity();
        model = math.Mat4.translate(model, light_pos);
        model = math.Mat4.scale(model, math.Vec3.new(0.2, 0.2, 0.2));
        light_cube_shader.setMat4("model", model);

        c.glBindVertexArray(light_cube_vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 36);

        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn processInput(window: glfw.Window) void {
    if (window.getKey(.escape) == .press or window.getKey(.q) == .press) {
        window.setShouldClose(true);
    }

    if (window.getKey(.w) == .press) {
        camera.handleKeyboard(.forward, delta_time);
    }
    if (window.getKey(.s) == .press) {
        camera.handleKeyboard(.backward, delta_time);
    }
    if (window.getKey(.a) == .press) {
        camera.handleKeyboard(.left, delta_time);
    }
    if (window.getKey(.d) == .press) {
        camera.handleKeyboard(.right, delta_time);
    }
    if (window.getKey(.space) == .press) {
        camera.handleKeyboard(.up, delta_time);
    }
    if (window.getKey(.left_shift) == .press) {
        camera.handleKeyboard(.down, delta_time);
    }
}

fn cursorPosCallback(window: glfw.Window, xpos64: f64, ypos64: f64) void {
    _ = window; // autofix
    const xpos: f32 = @floatCast(xpos64);
    const ypos: f32 = @floatCast(ypos64);

    if (first_mouse) {
        last_x = xpos;
        last_y = ypos;
        first_mouse = false;
    }

    const xoffset = xpos - last_x;
    const yoffset = last_y - ypos;

    last_x = xpos;
    last_y = ypos;

    camera.handleMouseMovement(xoffset, yoffset);
}

fn scrollCallback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
    _ = window; // autofix
    _ = xoffset; // autofix
    camera.handleMouseScroll(@floatCast(yoffset));
}

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn frameBufferSizeCallback(window: glfw.Window, width: u32, height: u32) void {
    _ = window; // autofix
    var gl_width: f32 = @floatFromInt(width);
    var gl_height: f32 = @floatFromInt(height);
    const gl_target_height: f32 = gl_height * ASPECT_RATIO;
    _ = gl_target_height; // autofix

    if (gl_width == 0 or gl_height == 0) {
        return;
    }

    if (gl_width <= gl_height * ASPECT_RATIO) {
        gl_width = gl_height * ASPECT_RATIO;
    } else {
        std.debug.print("1gl_width: {d}, gl_height: {d}. {d}\n", .{ gl_width, gl_height, ASPECT_RATIO });
        gl_height = @divTrunc(gl_width, ASPECT_RATIO);
        std.debug.print("2gl_width: {d}, gl_height: {d}. {d}\n", .{ gl_width, gl_height, ASPECT_RATIO });
    }

    const gl_widthi: c_int = @intFromFloat(gl_width);
    const gl_heighti: c_int = @intFromFloat(gl_height);
    c.glViewport(0, 0, gl_widthi, gl_heighti);
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
    _ = severity;
    _ = length;
    _ = user_param;

    std.log.err("{any}... OpenGL error {d}: {s}", .{ type_, id, message });
}
