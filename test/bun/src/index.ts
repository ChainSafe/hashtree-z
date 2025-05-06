import { ptr } from "bun:ffi";
import { binding } from "./binding.js";

export function hash(data: Uint8Array): Uint8Array {
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

export function hashInto(input: Uint8Array, output: Uint8Array): void {
	if (input.length % 64 !== 0) {
		throw new Error("Input length must be a multiple of 64 bytes");
	}

	if (output.length * 2 !== input.length) {
		throw new Error("Output length must be half of input length");
	}

	const numChunks = input.length / 32;
	const res = binding.hash64(
		ptr(output.buffer),
		numChunks / 2,
		ptr(input.buffer),
		numChunks,
	);

	if (res !== 0) {
		throw new Error(`Hashing failed res = ${res}`);
	}
}
