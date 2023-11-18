// Exactly two of the following should be initialized to fully constrain the span:
begin: f64 = values.uninitialized,
end: f64 = values.uninitialized,
mid: f64 = values.uninitialized,
delta: f64 = values.uninitialized,

// usable as dependencies only!
min: f64 = values.uninitialized,
max: f64 = values.uninitialized,
len: f64 = values.uninitialized,

fn count_uninitialized(self: Span, include_delta: bool) u8 {
    const begin: u8 = @intFromBool(values.is_uninitialized(self.begin));
    const end: u8 = @intFromBool(values.is_uninitialized(self.end));
    const mid: u8 = @intFromBool(values.is_uninitialized(self.mid));
    const delta: u8 = @intFromBool(include_delta and values.is_uninitialized(self.delta));
    return begin + end + mid + delta;
}

pub fn is_position_constrained(self: Span) bool {
    return self.count_uninitialized(false) <= 2;
}

pub fn is_fully_constrained(self: Span) bool {
    return self.count_uninitialized(true) <= 2;
}

pub fn is_begin_constrained(self: Span) bool {
    return !values.is_uninitialized(self.begin) or self.is_fully_constrained();
}

pub fn is_mid_constrained(self: Span) bool {
    return !values.is_uninitialized(self.mid) or self.is_fully_constrained();
}

pub fn is_end_constrained(self: Span) bool {
    return !values.is_uninitialized(self.end) or self.is_fully_constrained();
}

pub fn is_delta_constrained(self: Span) bool {
    return !values.is_uninitialized(self.delta) or self.is_fully_constrained();
}

pub fn add_missing_constraints(self: *Span, state: *Drawing_State, mid: f64, delta: f64) void {
    if (!values.is_uninitialized(self.begin)) {
        if (!values.is_uninitialized(self.end)) {
            self.default_mid(state);
            self.default_delta(state);
        } else if (!values.is_uninitialized(self.mid)) {
            state.constrain_lerp(&self.end, &self.begin, &self.mid, 2, "span end from begin/mid");
            self.default_delta(state);
        } else {
            if (values.is_uninitialized(self.delta)) self.delta = delta;
            state.constrain(&self.end, .{ .sum2 = .{ &self.begin, &self.delta }}, "span end from begin/delta");
            self.default_mid(state);
        }
    } else if (!values.is_uninitialized(self.end)) {
        if (!values.is_uninitialized(self.mid)) {
            state.constrain_lerp(&self.begin, &self.end, &self.mid, 2, "span begin from end/mid");
            self.default_delta(state);
        } else {
            if (values.is_uninitialized(self.delta)) self.delta = delta;
            state.constrain(&self.begin, .{ .difference = .{ &self.end, &self.delta }}, "span begin from end/delta");
            self.default_mid(state);
        }
    } else {
        if (values.is_uninitialized(self.mid)) self.mid = mid;
        if (values.is_uninitialized(self.delta)) self.delta = delta;
        state.constrain_scaled_offset(&self.begin, &self.mid, &self.delta, -0.5, "span begin from mid/delta");
        state.constrain_scaled_offset(&self.end, &self.mid, &self.delta, 0.5, "span end from mid/delta");
    }

    state.constrain(&self.min, .{ .min2 = .{ &self.begin, &self.end }}, "span min from begin/end");
    state.constrain(&self.max, .{ .max2 = .{ &self.begin, &self.end }}, "span max from begin/end");
    state.constrain(&self.len, .{ .difference = .{ &self.max, &self.min }}, "span len from max/min");
}

fn default_delta(self: *Span, state: *Drawing_State) void {
    state.constrain(&self.delta, .{ .difference = .{ &self.end, &self.begin }}, "default span delta");
}

fn default_mid(self: *Span, state: *Drawing_State) void {
    state.constrain_midpoint(&self.mid, &self.begin, &self.end, "default span mid");
}

pub fn debug(self: *Span, writer: anytype) !void {
    try writer.print("begin: {d}   mid: {d}   end: {d}   delta: {d}   min: {d}   max: {d}   len: {d}\n", .{
        self.begin, self.mid, self.end, self.delta,
        self.min, self.max, self.len,
    });
}

const Span = @This();
const Drawing_State = @import("Drawing_State.zig");
const values = @import("values.zig");
const std = @import("std");
