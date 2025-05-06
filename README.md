# hashtree-z
Zig binding for [hashtree](https://github.com/prysmaticlabs/hashtree)

# How to build
- `zig build`
- locate `zig-out/lib/libhashtree-z.dylib` (could be diffrerent name in other OSs) and continue the test below

# How to consume at javascript side using Bun FFI:

```typescript
import {dlopen} from "bun:ffi";

// Link to shared library path
const path = `.${your_path}/libhashtree-z.dylib`;

// Load the compiled Zig shared library
const lib = dlopen(path, {
  hash: {
      args: ["ptr", "u32", "ptr", "u62"],
      returns: "u32"
  },
});

const chunks = new Uint8Array(64).fill(0xAB);
const out = new Uint8Array(32);

lib.symbols.hash64(out, 1 chunks, 2);
console.log("out", out);

// Close the library when done
lib.close();
```