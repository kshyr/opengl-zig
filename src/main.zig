const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("GLFW error {d}: {s}", .{ err, description });
}

pub fn main() !void {
    if (c.glfwInit() == c.GLFW_FALSE) {
        std.log.err("Failed to initialize GLFW", .{});
        return error.Initialization;
    }

    defer c.glfwTerminate();

    _ = c.glfwSetErrorCallback(errorCallback);

    const window = c.glfwCreateWindow(800, 600, "Hello, World", null, null) orelse {
        std.log.err("Failed to create window", .{});
        return error.Initialization;
    };

    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);

    const loadproc: c.GLADloadproc = @ptrCast(&c.glfwGetProcAddress);
    if (c.gladLoadGLLoader(loadproc) == c.GL_FALSE) {
        std.log.err("Failed to load OpenGL", .{});
        return error.Initialization;
    }

    c.glfwSwapInterval(1);

    const vertex_shader_source: [*c]const u8 =
        \\#version 330 core
        \\void main()
        \\{
        \\  const vec4 vertices[3] = vec4[](
        \\    vec4( 0.0,  0.5, 1.0, 1.0),
        \\    vec4(-0.5, -0.5, 1.0, 1.0),
        \\    vec4( 0.5, -0.5, 1.0, 1.0)
        \\  );
        \\  gl_Position = vertices[gl_VertexID];
        \\} 
    ;

    const fragment_shader_source: [*c]const u8 =
        \\#version 330 core
        \\out vec4 fragment;
        \\void main()
        \\{
        \\  fragment = vec4(1.0, 0.5, 0.2, 1.0);
        \\}
    ;

    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, &vertex_shader_source, null);
    c.glCompileShader(vertex_shader);

    const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, &fragment_shader_source, null);
    c.glCompileShader(fragment_shader);

    const shader_program = c.glCreateProgram();
    c.glAttachShader(shader_program, vertex_shader);
    c.glAttachShader(shader_program, fragment_shader);
    c.glLinkProgram(shader_program);

    c.glDeleteShader(vertex_shader);
    c.glDeleteShader(fragment_shader);

    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        var width: c_int = 0;
        var height: c_int = 0;
        c.glfwGetFramebufferSize(window, &width, &height);
        c.glViewport(0, 0, width, height);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(shader_program);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
