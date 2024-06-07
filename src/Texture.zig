const std = @import("std");
const util = @import("util.zig");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("stb/stb_image.h");
});

const Texture = @This();
id: c.GLuint,

const TextureLoadOptions = struct {
    v_flip: ?bool = false,
};

pub fn new(filePath: [*c]const u8, options: TextureLoadOptions) !Texture {
    const file_path_slice = util.cStringToSlice(filePath);
    const formati = if (std.mem.endsWith(u8, file_path_slice, ".png")) c.GL_RGBA else c.GL_RGB;
    const formatu: c.GLuint = @intCast(formati);
    var id: c.GLuint = undefined;
    c.glGenTextures(1, &id);
    c.glBindTexture(c.GL_TEXTURE_2D, id);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    var width: c.GLint = undefined;
    var height: c.GLint = undefined;
    var channels: c.GLint = undefined;

    if (options.v_flip.?) {
        c.stbi_set_flip_vertically_on_load(c.GL_TRUE);
    }

    const data = c.stbi_load(filePath, &width, &height, &channels, 0);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, width, height, 0, formatu, c.GL_UNSIGNED_BYTE, data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);

    return Texture{
        .id = id,
    };
}
