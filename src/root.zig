const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("hashtree.h");
});

pub fn init() void {
    // TODO: handle result
    _ = c.hashtree_init(null);
}

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 1);
}

test "init" {
    init();
}
