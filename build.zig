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

    const assembly_flags: []const []const u8 = &.{ "-g", "-fpic" };

    const os = target.result.os.tag;
    const abi = target.result.abi;
    lib.root_module.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = if (target.result.cpu.arch.isArm() or target.result.cpu.arch.isAARCH64())
            &[_][]const u8{
                "sha256_armv8_neon_x4.S",
                "sha256_armv8_neon_x1.S",
                "sha256_armv8_crypto.S",
            }
            // The x86 .S files use ELF-only directives (.section .rodata, byte-count
            // .align, .type %function) that LLVM MC can't translate to Mach-O or
            // COFF-MSVC. Those targets fall through to the generic C implementation.
        else if (target.result.cpu.arch.isX86() and
            os != .macos and
            !(os == .windows and abi == .msvc))
            &[_][]const u8{
                "sha256_shani.S",
                "sha256_avx_x16.S",
                "sha256_avx_x8.S",
                "sha256_avx_x4.S",
                "sha256_avx_x1.S",
                "sha256_sse_x1.S",
            }
        else
            &[_][]const u8{},
        .flags = assembly_flags,
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
