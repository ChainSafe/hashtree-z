const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("hashtree", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Add the assembly and C source files
    module.addCSourceFiles(.{
        .root = b.path("hashtree/src"),
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
        .flags = if (target.result.os.tag == .macos) &[_][]const u8{
            "-g",
            "-fpic",
        } else &[_][]const u8{
            "-g",
            "-fPIC",
            "-fno-integrated-as",
        },
    });

    module.addCSourceFile(.{
        .file = b.path("hashtree/src/hashtree.c"),
        .flags = &.{
            "-g",
            "-Wall",
            "-Werror",
        },
    });
    module.addIncludePath(b.path("hashtree/src"));

    const mod_unit_tests = b.addTest(.{
        .root_module = module,
    });
    const run_mod_unit_tests = b.addRunArtifact(mod_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_unit_tests.step);
}
