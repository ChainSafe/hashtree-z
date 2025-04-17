const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("hashtree.h");
});

pub fn hash(out: [][32]u8, chunks: []const [32]u8) void {
    // Cast the slices to raw pointers and call the external function
    c.hashtree_hash(@ptrCast(out.ptr), @ptrCast(chunks.ptr), out.len);
}

test {
    const chunks: [2][32]u8 = [_][32]u8{[_]u8{0xAB} ** 32} ** 2;
    var out: [1][32]u8 = [_][32]u8{[_]u8{0} ** 32};
    hash(&out, &chunks);
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
    hash(&out, &chunks);
    hash(chunks[0..25], &chunks);

    try std.testing.expectEqualSlices([32]u8, &out, chunks[0..25][0..]);
}
