const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const exe = b.addExecutable(.{
        .name = "opengl-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zalgebra = b.addModule("zalgebra", .{
        .root_source_file = b.path("deps/zalgebra/src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("zalgebra", zalgebra);
    exe.root_module.addImport("mach-glfw", glfw_dep.module("mach-glfw"));

    exe.addIncludePath(b.path("deps"));
    exe.addCSourceFile(.{ .file = b.path("deps/glad/glad.c") });
    exe.addCSourceFile(.{ .file = b.path("deps/stb/stb_image.c") });

    b.installArtifact(exe);
}
