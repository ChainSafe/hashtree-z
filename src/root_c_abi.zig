const std = @import("std");
const hash_fn = @import("root.zig").hash;

const ERROR_FAILED_HASH = 2;
const ERROR_INVALID_ARGUMENT = 1;
const SUCCESS = 0;

pub export fn hash64(out_ptr: [*c][32]u8, out_len: u32, chunks_ptr: [*c]const [32]u8, chunks_len: u32) c_uint {
    // Check if the output buffer is large enough
    if (chunks_len == 0 or chunks_len % 2 != 0 or out_len * 2 != chunks_len) {
        std.debug.print("Invalid argument: chunks_len = {}, out_len = {}\n", .{ chunks_len, out_len });
        return ERROR_INVALID_ARGUMENT;
    }

    hash_fn(out_ptr[0..out_len], chunks_ptr[0..chunks_len]) catch return ERROR_FAILED_HASH;
    return SUCCESS;
}

test "hash64" {
    const chunks = [_][32]u8{[_]u8{0xAB} ** 32} ** 2;
    var out = [_][32]u8{[_]u8{0} ** 32};
    const res = hash64(&out[0], out.len, &chunks[0], chunks.len);
    try std.testing.expect(res == SUCCESS);
    try std.testing.expectEqualSlices(u8, &[_]u8{
        0xec, 0x65, 0xc8, 0x79, 0x8e, 0xcf, 0x95, 0x90, 0x24, 0x13, 0xc4, 0x0f, 0x7b, 0x9e,
        0x6d, 0x4b, 0x00, 0x68, 0x88, 0x5f, 0x5f, 0x32, 0x4a, 0xba, 0x1f, 0x9b, 0xa1, 0xc8,
        0xe1, 0x4a, 0xea, 0x61,
    }, &out[0]);
}
