const std = @import("std");
const math = @import("zalgebra");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("stb/stb_image.h");
});
const Shader = @import("Shader.zig");
const print = std.debug.print;

fn gl_error_callback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("GLFW error {d}: {s}", .{ err, description });
}

fn gl_debug_callback(
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    if (c.glfwInit() == c.GLFW_FALSE) {
        std.log.err("Failed to initialize GLFW", .{});
        return error.Initialization;
    }
    defer c.glfwTerminate();

    _ = c.glfwSetErrorCallback(gl_error_callback);

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    //#ifdef __APPLE__
    //    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GLFW_TRUE);
    //#endif

    const window = c.glfwCreateWindow(800, 600, "Hello, World", null, null) orelse {
        std.log.err("Failed to create window", .{});
        return error.Initialization;
    };

    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);

    c.glfwSwapInterval(1);

    const loadproc: c.GLADloadproc = @ptrCast(&c.glfwGetProcAddress);
    if (c.gladLoadGLLoader(loadproc) == c.GL_FALSE) {
        std.log.err("Failed to load OpenGL", .{});
        return error.Initialization;
    }

    c.glDebugMessageCallback(gl_debug_callback, null);
    c.glEnable(c.GL_DEBUG_OUTPUT);
    c.glEnable(c.GL_DEPTH_TEST);

    var shader = try Shader.init(allocator, "./src/shaders/vertex.glsl", "./src/shaders/fragment.glsl");

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

    const texture1 = try loadTextureFromFile("./src/assets/mario-brick.png", .{});
    const texture2 = try loadTextureFromFile("./src/assets/awesomeface.png", .{});

    //c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    shader.use();
    shader.setInt("texture1", 0);
    shader.setInt("texture2", 1);

    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        var width: c_int = undefined;
        var height: c_int = undefined;
        c.glfwGetFramebufferSize(window, &width, &height);
        c.glViewport(0, 0, width, height);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture1);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, texture2);

        shader.use();

        const time: f32 = @floatCast(c.glfwGetTime());
        var projection = math.Mat4.identity();
        var view = math.Mat4.identity();
        const aspect_ratio: f32 = 800 / 600;
        const projection_deg: f32 = 60.0;
        projection = math.perspective(projection_deg, aspect_ratio, 0.1, 100.0);
        view = math.Mat4.translate(view, math.Vec3.new(1.0, 1.1, -5.0));

        shader.setMat4("projection", projection);
        shader.setMat4("view", view);

        c.glBindVertexArray(VAO);
        for (cube_positions, 0..) |position, i| {
            var model = math.Mat4.identity();
            model = math.Mat4.translate(model, position);
            const i_f: f32 = @floatFromInt(i);
            const angle: f32 = 100.0 * i_f * time;
            print("i: {d}, angle: {d}\n", .{ i, angle });
            model = math.Mat4.rotate(model, math.toRadians(angle), math.Vec3.new(2000.0, 2000.0, 2000.0));

            shader.setMat4("model", model);

            c.glDrawArrays(c.GL_TRIANGLES, 0, 36);
        }

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
fn cStringToSlice(cstr: [*c]const u8) []const u8 {
    const length = std.mem.len(cstr); // Get the length of the C string
    return cstr[0..length]; // Create a slice from the pointer and the length
}

const TextureLoadOptions = struct {
    v_flip: ?bool = false,
};

pub fn loadTextureFromFile(filePath: [*c]const u8, options: TextureLoadOptions) !c_uint {
    const file_path_slice = cStringToSlice(filePath);
    const formati = if (std.mem.endsWith(u8, file_path_slice, ".png")) c.GL_RGBA else c.GL_RGB;
    print("formati: {d}\n", .{formati});
    const formatu: c_uint = @intCast(formati);
    var texture: c_uint = undefined;
    c.glGenTextures(1, &texture);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;

    if (options.v_flip.?) {
        c.stbi_set_flip_vertically_on_load(c.GL_TRUE);
    }

    const data = c.stbi_load(filePath, &width, &height, &channels, 0);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, width, height, 0, formatu, c.GL_UNSIGNED_BYTE, data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);

    return texture;
}
