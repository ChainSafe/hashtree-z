# hashtree-z
Zig binding for [hashtree](https://github.com/prysmaticlabs/hashtree)

## Quickstart
- `zig fetch --save=hashtree git+https://github.com/chainsafe/hashtree-z`
- In build.zig:
```zig
const hashtree = b.dependency("hashtree", .{});
const hashtree_mod = hashtree.module("hashtree");
const hashtree_lib = hashtree.artifact("hashtree");
```
- Module usage:
```zig
const hashtree = @import("hashtree");

const chunks: [2][32]u8 = [_][32]u8{[_]u8{0xAB} ** 32} ** 2;
var out: [1][32]u8 = undefined;
try hashtree.hash(&out, &chunks);
```

## License

MIT
