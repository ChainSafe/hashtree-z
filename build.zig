const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addStaticLibrary(.{
        .name = "hashtree-z",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add the C source file
    // exe.addCSourceFile("hashtree/src/hashtree.c", &.{}); // Path to your C source
    exe.addCSourceFile(.{ .file = b.path("hashtree/src/hashtree.c"), .flags = &.{"-std=c99"} });

    // Add include paths if needed
    exe.addIncludePath(b.path("hashtree/src"));
    // TODO: build hashtree using make
    // for now, do it manually
    // Add the static library
    exe.addObjectFile(b.path("hashtree/build/lib/libhashtree.a"));

    b.installArtifact(exe);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.linkLibrary(exe);
    lib_unit_tests.addIncludePath(b.path("hashtree/src"));
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
