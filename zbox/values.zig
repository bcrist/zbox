pub const uninitialized: f64 = @bitCast(@as(u64, 0x7FF8_0000_0000_0001));
pub const constrained: f64 = @bitCast(@as(u64, 0x7FF8_0000_0000_0002));

pub fn is_uninitialized(value: f64) bool {
    const uvalue: u64 = @bitCast(value);
    const ucheck: u64 = @bitCast(uninitialized);
    return uvalue == ucheck;
}

pub fn is_constrained(value: f64) bool {
    const uvalue: u64 = @bitCast(value);
    const ucheck: u64 = @bitCast(constrained);
    return uvalue == ucheck;
}

const std = @import("std");
