const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });

    const exe = b.addExecutable(.{
        .name = "opengl-zig",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.addIncludePath(.{ .path = "include" });
    exe.addCSourceFile(.{ .file = .{ .path = ("include/glad/glad.c") } });
    exe.addCSourceFile(.{ .file = .{ .path = ("include/stb/stb_image.c") } });
    exe.linkSystemLibrary("glfw3");

    b.installArtifact(exe);
}
