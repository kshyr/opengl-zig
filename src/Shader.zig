const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const print = std.debug.print;

id: c.GLuint,

const Shader = @This();

pub fn init(
    allocator: Allocator,
    vert_path: []const u8,
    frag_path: []const u8,
) !Shader {
    const vertex_shader_source = try read_shader_file(allocator, vert_path);
    const fragment_shader_source = try read_shader_file(allocator, frag_path);

    std.debug.print("Compiling vertex shader: {s} \n", .{vertex_shader_source});

    var vertex_shader: c.GLuint = undefined;
    var fragment_shader: c.GLuint = undefined;

    vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    const vertex_shader_source_ptr: [*c]const c.GLchar = vertex_shader_source.ptr;
    c.glShaderSource(vertex_shader, 1, &vertex_shader_source_ptr, null);
    c.glCompileShader(vertex_shader);

    fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    const fragment_shader_source_ptr: [*c]const c.GLchar = fragment_shader_source.ptr;
    c.glShaderSource(fragment_shader, 1, &fragment_shader_source_ptr, null);
    c.glCompileShader(fragment_shader);

    const shader_program = c.glCreateProgram();
    c.glAttachShader(shader_program, vertex_shader);
    c.glAttachShader(shader_program, fragment_shader);
    c.glLinkProgram(shader_program);

    c.glDeleteShader(vertex_shader);
    c.glDeleteShader(fragment_shader);

    return Shader{
        .id = shader_program,
    };
}

pub fn use(self: *Shader) void {
    std.debug.print("Using shader {d}\n", .{self.id});
    c.glUseProgram(self.id);
}

pub fn setBool(self: *Shader, name: []const u8, value: bool) void {
    const location = c.glGetUniformLocation(self.id, name);
    c.glUniform1i(location, @intFromBool(value));
}

pub fn setInt(self: *Shader, name: []const u8, value: c.GLint) void {
    const location = c.glGetUniformLocation(self.id, name);
    c.glUniform1i(location, @intFromBool(value));
}

pub fn setFloat(self: *Shader, name: []const u8, value: c.GLfloat) void {
    const location = c.glGetUniformLocation(self.id, name);
    c.glUniform1f(location, value);
}

fn read_shader_file(allocator: Allocator, path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    var buffer = try allocator.alloc(u8, file_size + 1);
    const read_size = try file.readAll(buffer[0..file_size]);

    if (read_size != file_size) {
        allocator.free(buffer);
        return error.FileReadMismatch;
    }

    buffer[file_size] = 0;

    return buffer;
}
