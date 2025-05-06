import { dlopen } from "bun:ffi";
import { getBinaryName, getPrebuiltBinaryPath } from "../utils/index.js";

const binaryName = getBinaryName();
const binaryPath = getPrebuiltBinaryPath(binaryName);

// Load the compiled Zig shared library
const lib = dlopen(binaryPath, {
	hash64: {
		args: ["ptr", "u32", "ptr", "u32"],
		returns: "u32",
	},
});

export const binding = lib.symbols;
