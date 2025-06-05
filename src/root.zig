const std = @import("std");
const builtin = @import("builtin");

const c = @cImport({
    @cInclude("hashtree.h");
});

/// If hashtree is not supported, fallback to using the (cross-platform) std lib
fn fallback(out: [][32]u8, in: []const [32]u8) void {
    for (0..in.len / 2) |i| {
        std.crypto.hash.sha2.Sha256.hash(
            @ptrCast(in[i * 2 .. i * 2 + 2]),
            &out[i],
            .{},
        );
    }
}

fn isSupported() bool {
    if (builtin.cpu.arch.isAARCH64()) {
        return true;
    }

    if (builtin.cpu.arch == .x86_64 and (std.Target.x86.featureSetHasAll(builtin.cpu.features, .{ .avx512f, .avx512vl }) or
        std.Target.x86.featureSetHasAll(builtin.cpu.features, .{ .avx2, .bmi2 }) or
        std.Target.x86.featureSetHasAll(builtin.cpu.features, .{ .sha, .avx })))
    {
        return true;
    }

    return false;
}

pub const Error = error{
    InvalidInput,
};

pub fn hash(out: [][32]u8, in: []const [32]u8) Error!void {
    if (in.len != 2 * out.len) {
        return error.InvalidInput;
    }

    if (comptime isSupported()) {
        c.hashtree_hash(
            @ptrCast(out.ptr),
            @ptrCast(in.ptr),
            out.len,
        );
    } else fallback(out, in);
}

test {
    const chunks: [2][32]u8 = [_][32]u8{[_]u8{0xAB} ** 32} ** 2;
    var out: [1][32]u8 = [_][32]u8{[_]u8{0} ** 32};
    try hash(&out, &chunks);
    const expected_hash: [32]u8 = [_]u8{
        0xec, 0x65, 0xc8, 0x79, 0x8e, 0xcf, 0x95, 0x90, 0x24, 0x13, 0xc4, 0x0f, 0x7b, 0x9e,
        0x6d, 0x4b, 0x00, 0x68, 0x88, 0x5f, 0x5f, 0x32, 0x4a, 0xba, 0x1f, 0x9b, 0xa1, 0xc8,
        0xe1, 0x4a, 0xea, 0x61,
    };

    try std.testing.expectEqualSlices(u8, expected_hash[0..], out[0][0..]);
}

test "overlapping memory" {
    var chunks: [50][32]u8 = [_][32]u8{[_]u8{0xAB} ** 32} ** 50;
    var out: [25][32]u8 = undefined;
    try hash(&out, &chunks);
    try hash(chunks[0..25], &chunks);

    try std.testing.expectEqualSlices([32]u8, &out, chunks[0..25][0..]);
}
