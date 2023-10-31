// Exactly two of the following should be initialized to fully constrain the span:
begin: f64 = values.uninitialized,
end: f64 = values.uninitialized,
mid: f64 = values.uninitialized,
delta: f64 = values.uninitialized,

// usable as dependencies only!
min: f64 = values.uninitialized,
max: f64 = values.uninitialized,
len: f64 = values.uninitialized,

pub fn isFullyConstrained(self: Span) bool {
    const begin: u8 = @intFromBool(values.isUninitialized(self.begin));
    const end: u8 = @intFromBool(values.isUninitialized(self.end));
    const mid: u8 = @intFromBool(values.isUninitialized(self.mid));
    const delta: u8 = @intFromBool(values.isUninitialized(self.delta));

    const uninitialized_count = begin + end + mid + delta;
    return uninitialized_count <= 2;
}

pub fn addMissingConstraints(self: *Span, drawing: *Drawing, default_mid: f64, default_delta: f64) void {
    if (!values.isUninitialized(self.begin)) {
        if (!values.isUninitialized(self.end)) {
            self.defaultMid(drawing);
            self.defaultDelta(drawing);
        } else if (!values.isUninitialized(self.mid)) {
            drawing.constrain(&self.end, .{ .lerp = .{ .operands = .{ &self.begin, &self.mid }, .k = 2 }}, "span end from begin/mid");
            self.defaultDelta(drawing);
        } else {
            if (values.isUninitialized(self.delta)) self.delta = default_delta;
            drawing.constrain(&self.end, .{ .sum2 = .{ &self.begin, &self.delta }}, "span end from begin/delta");
            self.defaultMid(drawing);
        }
    } else if (!values.isUninitialized(self.end)) {
        if (!values.isUninitialized(self.mid)) {
            drawing.constrain(&self.begin, .{ .lerp = .{ .operands = .{ &self.end, &self.mid }, .k = 2 }}, "span begin from end/mid");
            self.defaultDelta(drawing);
        } else {
            if (values.isUninitialized(self.delta)) self.delta = default_delta;
            drawing.constrain(&self.begin, .{ .difference = .{ &self.end, &self.delta }}, "span begin from end/delta");
            self.defaultMid(drawing);
        }
    } else {
        if (values.isUninitialized(self.mid)) self.mid = default_mid;
        if (values.isUninitialized(self.delta)) self.delta = default_delta;
        drawing.constrain(&self.begin, .{ .scaled_offset = .{ .operands = .{ &self.mid, &self.delta }, .k = -0.5 }}, "span begin from mid/delta");
        drawing.constrain(&self.end, .{ .scaled_offset = .{ .operands = .{ &self.mid, &self.delta }, .k = 0.5 }}, "span end from mid/delta");
    }

    drawing.constrain(&self.min, .{ .min2 = .{ &self.begin, &self.end }}, "span min from begin/end");
    drawing.constrain(&self.max, .{ .max2 = .{ &self.begin, &self.end }}, "span max from begin/end");
    drawing.constrain(&self.len, .{ .difference = .{ &self.max, &self.min }}, "span len from max/min");
}

fn defaultDelta(self: *Span, drawing: *Drawing) void {
    drawing.constrain(&self.delta, .{
        .difference = .{ &self.end, &self.begin },
    }, "default span delta");
}

fn defaultMid(self: *Span, drawing: *Drawing) void {
    drawing.constrain(&self.mid, .{
        .midpoint = .{ &self.begin, &self.end },
    }, "default span mid");
}

pub fn debug(self: *Span, writer: anytype) !void {
    try writer.print("begin: {d}   mid: {d}   end: {d}   delta: {d}   min: {d}   max: {d}   len: {d}\n", .{
        self.begin, self.mid, self.end, self.delta,
        self.min, self.max, self.len,
    });
}


const Span = @This();
const Drawing = @import("Drawing.zig");
const values = @import("values.zig");
const std = @import("std");
