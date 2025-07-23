import { hash, hashInto } from "../../src/index.js";

const data = new Uint8Array(64).fill(0xab);

let start = Date.now();
const times = 1_000_000;

for (let i = 0; i < times; i++) {
  hash(data);
}
const end = Date.now();
console.log(`hashtree-z: Hashing ${times} times took ${end - start} ms`);

start = Date.now();
const out = new Uint8Array(32);
for (let i = 0; i < times; i++) {
  hashInto(data, out);
}

const end2 = Date.now();
console.log(`hashtree-z: HashInto ${times} times took ${end2 - start} ms`);
