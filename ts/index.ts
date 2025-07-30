import { join } from "node:path";
import { requireNapiLibrary } from "@chainsafe/napi-z";

const binding = requireNapiLibrary(join(import.meta.dirname, ".."));

export const hash = binding.hash as (input: Uint8Array) => Uint8Array;
export const hashInto = binding.hashInto as (input: Uint8Array, output: Uint8Array) => void;