const std = @import("std");
const hashtree = @import("hashtree");
const napi = @import("napi");

comptime {
    napi.module.register(registerModule);
}

fn registerModule(env: napi.Env, value: napi.Value) anyerror!void {
    try value.setNamedProperty("hash", try env.createFunction("hash", 1, void, hash, @constCast(&{})));
    try value.setNamedProperty("hashInto", try env.createFunction("hashInto", 2, void, hashInto, @constCast(&{})));
}

fn hash(env: napi.Env, info: napi.CallbackInfo(void)) napi.Value {
    const input = info.arg(0).getTypedarrayInfo() catch |err| {
        env.throwError(@errorName(err), "Input must be a TypedArray") catch {};
        return napi.Value.nullptr;
    };

    _ = std.math.divExact(usize, input.data.len, 64) catch {
        env.throwError("InvalidInput", "Input length must be a multiple of 64 bytes") catch {};
        return napi.Value.nullptr;
    };

    var out_ptr: [*]u8 = undefined;
    const out_arraybuffer = env.createArrayBuffer(input.data.len / 2, &out_ptr) catch |err| {
        env.throwError(@errorName(err), "Failed to create output ArrayBuffer") catch {};
        return napi.Value.nullptr;
    };
    const out_uint8array = env.createTypedarray(napi.value_types.TypedarrayType.uint8, input.data.len / 2, out_arraybuffer, 0) catch |err| {
        env.throwError(@errorName(err), "Failed to create output Uint8Array") catch {};
        return napi.Value.nullptr;
    };

    hashtree.hash(@ptrCast(out_ptr[0 .. input.data.len / 2]), @ptrCast(input.data)) catch |err| {
        env.throwError(@errorName(err), "Failed to hash input") catch {};
        return napi.Value.nullptr;
    };

    return out_uint8array;
}

fn hashInto(env: napi.Env, info: napi.CallbackInfo(void)) napi.Value {
    const input = info.arg(0).getTypedarrayInfo() catch |err| {
        env.throwError(@errorName(err), "Input must be a TypedArray") catch {};
        return napi.Value.nullptr;
    };

    const output = info.arg(1).getTypedarrayInfo() catch {
        env.throwError("InvalidInput", "Input must be a TypedArray") catch {};
        return napi.Value.nullptr;
    };

    _ = std.math.divExact(usize, input.data.len, 64) catch |err| {
        env.throwError(@errorName(err), "Input length must be a multiple of 64 bytes") catch {};
        return napi.Value.nullptr;
    };

    if (input.data.len != 2 * output.data.len) {
        env.throwError("InvalidInput", "Input length must be twice the output length") catch {};
        return napi.Value.nullptr;
    }

    hashtree.hash(@ptrCast(output.data), @ptrCast(input.data)) catch |err| {
        env.throwError(@errorName(err), "Failed to hash input") catch {};
        return napi.Value.nullptr;
    };

    return napi.Value.nullptr;
}
