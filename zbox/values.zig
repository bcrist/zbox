pub const uninitialized = reconstructF64(exponent_max + 1, (1 << (mantissa_bits - 1)) | 1);
pub const constrained = reconstructF64(exponent_max + 1, (1 << (mantissa_bits - 1)) | 2);

pub fn isUninitialized(val: f64) bool {
    const val_u64: u64 = @bitCast(val);
    const uninitialized_u64: u64 = @bitCast(uninitialized);
    return val_u64 == uninitialized_u64;
}

pub fn isConstrained(val: f64) bool {
    const val_u64: u64 = @bitCast(val);
    const constrained_u64: u64 = @bitCast(constrained);
    return val_u64 == constrained_u64;
}

pub fn ptrToSlice(val: *const *const f64) []const *const f64 {
    // This can be removed when https://github.com/ziglang/zig/issues/16075 is implemented
    var slice: []const *const f64 = undefined;
    slice.ptr = @ptrCast(val);
    slice.len = 1;
    return slice;
}

inline fn reconstructF64(comptime exponent: comptime_int, comptime mantissa: u64) f64 {
    const biased_exponent: u64 = exponent + exponent_max;
    return @bitCast((biased_exponent << mantissa_bits) | mantissa);
}

const exponent_max = (1 << (exponent_bits - 1)) - 1;
const exponent_bits = 11;
const mantissa_bits = 52;

test {
    try std.testing.expect(std.math.isNan(uninitialized));
    try std.testing.expect(std.math.isNan(constrained));
    try std.testing.expectEqual(@as(u64, 0x7FF8000000000001), @bitCast(uninitialized));
    try std.testing.expectEqual(@as(u64, 0x7FF8000000000002), @bitCast(constrained));
}

const std = @import("std");
