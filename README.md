# hashtree-z
Zig binding for hashtree

# How to consume at javascript side using Bun FFI:

```typescript
import { dlopen, FFIType, ptr } from "bun:ffi";
const { pointer, usize, void: voidFFI } = FFIType;

const path = `./libhashtree-z.dylib`;

// Load the compiled Zig shared library
const lib = dlopen(path, {
  init: {
      args: [],
      returns: voidFFI
  },
  hash: {
      args: [pointer, pointer, usize],
      returns: voidFFI
  },
});

const chunk = new Uint8Array(64).fill(0xAB);
const out = new Uint8Array(32);


const chunkPtr = ptr(chunk);
const outPtr = ptr(out);

lib.symbols.init();

lib.symbols.hash(outPtr, chunkPtr, 1);

console.log("out", out);

// Close the library when done
lib.close();
```