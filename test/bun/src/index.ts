import { ptr } from "bun:ffi";
import { binding } from "./binding.js";

export function hash64(data: Uint8Array): Uint8Array {
	if (data.length % 64 !== 0) {
		throw new Error("Input length must be a multiple of 64 bytes");
	}

	const numChunks = data.length / 32;
	const out = new Uint8Array((numChunks * 32) / 2);
	const res = binding.hash64(
		ptr(out.buffer),
		numChunks / 2,
		ptr(data.buffer),
		numChunks,
	);

	if (res !== 0) {
		throw new Error(`Hashing failed res = ${res}`);
	}

	return out;
}
