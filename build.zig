const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("hashtree", .{});

    const lib = b.addLibrary(.{
        .name = "hashtree",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const assembly_flags_default = &.{ "-g", "-fpic" };
    var assembly_flags = std.ArrayList([]const u8).init(b.allocator);
    assembly_flags.appendSlice(assembly_flags_default) catch unreachable;

    if (!target.result.cpu.arch.isAARCH64()) {
        assembly_flags.append("-fno-integrated-as") catch unreachable;
    }

    // Add the assembly and C source files
    lib.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = if (target.result.cpu.arch.isArm() or target.result.cpu.arch.isAARCH64())
            &[_][]const u8{
                "sha256_armv8_neon_x4.S",
                "sha256_armv8_neon_x1.S",
                "sha256_armv8_crypto.S",
            }
        else
            &[_][]const u8{
                "sha256_shani.S",
                "sha256_avx_x16.S",
                "sha256_avx_x8.S",
                "sha256_avx_x4.S",
                "sha256_avx_x1.S",
                "sha256_sse_x1.S",
            },
        .flags = assembly_flags.items,
    });

    lib.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &[_][]const u8{
            "hashtree.c",
            "sha256_generic.c",
        },
        .flags = &.{
            "-g",
            "-Wall",
            "-Werror",
        },
    });
    lib.addIncludePath(upstream.path("src"));

    lib.installHeader(upstream.path("src/hashtree.h"), "hashtree.h");
    b.installArtifact(lib);

    const module = b.addModule("hashtree", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.linkLibrary(lib);

    const mod_unit_tests = b.addTest(.{
        .root_module = module,
    });
    const run_mod_unit_tests = b.addRunArtifact(mod_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_unit_tests.step);
}
