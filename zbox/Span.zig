// Exactly two of the following should be initialized to fully constrain the span:
begin: f64 = values.uninitialized,
end: f64 = values.uninitialized,
mid: f64 = values.uninitialized,
delta: f64 = values.uninitialized,

// usable as dependencies only!
min: f64 = values.uninitialized,
max: f64 = values.uninitialized,
len: f64 = values.uninitialized,

fn countUninitialized(self: Span, include_delta: bool) u8 {
    const begin: u8 = @intFromBool(values.isUninitialized(self.begin));
    const end: u8 = @intFromBool(values.isUninitialized(self.end));
    const mid: u8 = @intFromBool(values.isUninitialized(self.mid));
    const delta: u8 = @intFromBool(include_delta and values.isUninitialized(self.delta));
    return begin + end + mid + delta;
}

pub fn isPositionConstrained(self: Span) bool {
    return self.countUninitialized(false) <= 2;
}

pub fn isFullyConstrained(self: Span) bool {
    return self.countUninitialized(true) <= 2;
}

pub fn isBeginConstrained(self: Span) bool {
    return !values.isUninitialized(self.begin) or self.isFullyConstrained();
}

pub fn isMidConstrained(self: Span) bool {
    return !values.isUninitialized(self.mid) or self.isFullyConstrained();
}

pub fn isEndConstrained(self: Span) bool {
    return !values.isUninitialized(self.end) or self.isFullyConstrained();
}

pub fn isDeltaConstrained(self: Span) bool {
    return !values.isUninitialized(self.delta) or self.isFullyConstrained();
}

pub fn addMissingConstraints(self: *Span, state: *DrawingState, default_mid: f64, default_delta: f64) void {
    if (!values.isUninitialized(self.begin)) {
        if (!values.isUninitialized(self.end)) {
            self.defaultMid(state);
            self.defaultDelta(state);
        } else if (!values.isUninitialized(self.mid)) {
            state.constrainLerp(&self.end, &self.begin, &self.mid, 2, "span end from begin/mid");
            self.defaultDelta(state);
        } else {
            if (values.isUninitialized(self.delta)) self.delta = default_delta;
            state.constrain(&self.end, .{ .sum2 = .{ &self.begin, &self.delta }}, "span end from begin/delta");
            self.defaultMid(state);
        }
    } else if (!values.isUninitialized(self.end)) {
        if (!values.isUninitialized(self.mid)) {
            state.constrainLerp(&self.begin, &self.end, &self.mid, 2, "span begin from end/mid");
            self.defaultDelta(state);
        } else {
            if (values.isUninitialized(self.delta)) self.delta = default_delta;
            state.constrain(&self.begin, .{ .difference = .{ &self.end, &self.delta }}, "span begin from end/delta");
            self.defaultMid(state);
        }
    } else {
        if (values.isUninitialized(self.mid)) self.mid = default_mid;
        if (values.isUninitialized(self.delta)) self.delta = default_delta;
        state.constrainScaledOffset(&self.begin, &self.mid, &self.delta, -0.5, "span begin from mid/delta");
        state.constrainScaledOffset(&self.end, &self.mid, &self.delta, 0.5, "span end from mid/delta");
    }

    state.constrain(&self.min, .{ .min2 = .{ &self.begin, &self.end }}, "span min from begin/end");
    state.constrain(&self.max, .{ .max2 = .{ &self.begin, &self.end }}, "span max from begin/end");
    state.constrain(&self.len, .{ .difference = .{ &self.max, &self.min }}, "span len from max/min");
}

fn defaultDelta(self: *Span, state: *DrawingState) void {
    state.constrain(&self.delta, .{ .difference = .{ &self.end, &self.begin }}, "default span delta");
}

fn defaultMid(self: *Span, state: *DrawingState) void {
    state.constrainMidpoint(&self.mid, &self.begin, &self.end, "default span mid");
}

pub fn debug(self: *Span, writer: anytype) !void {
    try writer.print("begin: {d}   mid: {d}   end: {d}   delta: {d}   min: {d}   max: {d}   len: {d}\n", .{
        self.begin, self.mid, self.end, self.delta,
        self.min, self.max, self.len,
    });
}


const Span = @This();
const DrawingState = @import("DrawingState.zig");
const values = @import("values.zig");
const std = @import("std");
