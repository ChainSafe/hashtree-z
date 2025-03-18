const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("hashtree.h");
});

pub export fn hash(out: *u8, chunks: *const u8, count: usize) void {
    // Cast the slices to raw pointers and call the external function
    c.hashtree_hash(out, chunks, count);
}

test "test_hash" {
    const chunks: [64]u8 = [_]u8{0xAB} ** 64;
    var out: [32]u8 = [_]u8{0} ** 32;
    hash(&out[0], &chunks[0], 1);
    const expected_hash: [32]u8 = [_]u8{
        0xec, 0x65, 0xc8, 0x79, 0x8e, 0xcf, 0x95, 0x90, 0x24, 0x13, 0xc4, 0x0f, 0x7b, 0x9e,
        0x6d, 0x4b, 0x00, 0x68, 0x88, 0x5f, 0x5f, 0x32, 0x4a, 0xba, 0x1f, 0x9b, 0xa1, 0xc8,
        0xe1, 0x4a, 0xea, 0x61,
    };

    try std.testing.expectEqualSlices(u8, expected_hash[0..], out[0..]);
}
