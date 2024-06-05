const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("stb/stb_image.h");
});
const glm = @import("ziglm");
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

    var shader = try Shader.init(allocator, "./src/shaders/vertex.glsl", "./src/shaders/fragment.glsl");

    // Set up vertex data (and buffer(s)) and attribute pointers

    const vertices = [_]f32{
        0.5,  0.5,  0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
        0.5,  -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0,
        -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
        -0.5, 0.5,  0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
    };
    const indices = [_]u32{
        0, 1, 3,
        1, 2, 3,
    };
    var VBO: u32 = undefined;
    var VAO: u32 = undefined;
    var EBO: u32 = undefined;

    c.glGenVertexArrays(1, &VAO);
    c.glGenBuffers(1, &VBO);
    c.glGenBuffers(1, &EBO);

    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, EBO);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(6 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(2);

    const texture1 = try loadTextureFromFile("./src/assets/61uWMZtvquL._AC_UF894,1000_QL80_.jpg", .{ .v_flip = true });
    const texture2 = try loadTextureFromFile("./src/assets/awesomeface.png", .{ .v_flip = true });

    //c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    shader.use();
    c.glUniform1i(c.glGetUniformLocation(shader.id, "texture1"), 0);
    c.glUniform1i(c.glGetUniformLocation(shader.id, "texture2"), 1);
    shader.setInt("texture2", 1);

    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        var width: c_int = undefined;
        var height: c_int = undefined;
        c.glfwGetFramebufferSize(window, &width, &height);
        c.glViewport(0, 0, width, height);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture1);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, texture2);

        shader.use();
        c.glBindVertexArray(VAO);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);

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
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, formati, width, height, 0, formatu, c.GL_UNSIGNED_BYTE, data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);

    return texture;
}
