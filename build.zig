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
            .pic = true,
        }),
    });

    const base_asm_flags: []const []const u8 = &.{ "-g", "-fpic" };

    // The x86 .S files use GAS-specific constructs (`.equiv` register aliases
    // in Intel syntax) that LLVM's integrated assembler doesn't parse the same
    // way binutils `as` does. Force the clang driver to delegate to an external
    // `as` so the files assemble. Requires binutils in the host environment —
    // this drops hermetic cross-compilation for the x86 asm path, but matches
    // what upstream's Makefile relies on.
    const x86_asm_flags: []const []const u8 = base_asm_flags ++ &[_][]const u8{
        "-fno-integrated-as",
    };

    const os = target.result.os.tag;
    const abi = target.result.abi;
    if (target.result.cpu.arch.isArm() or target.result.cpu.arch.isAARCH64()) {
        lib.root_module.addCSourceFiles(.{
            .root = upstream.path("src"),
            .files = &[_][]const u8{
                "sha256_armv8_neon_x4.S",
                "sha256_armv8_neon_x1.S",
                "sha256_armv8_crypto.S",
            },
            .flags = base_asm_flags,
        });
        // The x86 .S files use ELF-only directives (.section .rodata, byte-count
        // .align, .type %function) that LLVM MC can't translate to Mach-O or
        // COFF-MSVC. Those targets fall through to the generic C implementation.
    } else if (target.result.cpu.arch.isX86() and
        os != .macos and
        !(os == .windows and abi == .msvc))
    {
        lib.root_module.addCSourceFiles(.{
            .root = upstream.path("src"),
            .files = &[_][]const u8{
                "sha256_shani.S",
                "sha256_avx_x16.S",
                "sha256_avx_x8.S",
                "sha256_avx_x4.S",
                "sha256_avx_x1.S",
                "sha256_sse_x1.S",
            },
            .flags = x86_asm_flags,
        });
    }

    lib.root_module.addCSourceFiles(.{
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
    lib.root_module.addIncludePath(upstream.path("src"));

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
