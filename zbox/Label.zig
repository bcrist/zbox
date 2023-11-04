state: *DrawingState,
text: []const u8,
options: Options,
_x: f64 = values.uninitialized,
_y: f64 = values.uninitialized,

pub const Options = struct {
    class: []const u8 = "",
    _class1: []const u8 = "", // reserved
    _class2: []const u8 = "", // reserved
    alignment: Alignment = .left,
    baseline: Baseline = .normal,
    angle: f64 = 0,
};

pub const Alignment = enum {
    left,
    center,
    right,
};

pub const Baseline = enum {
    normal,
    middle,
    hanging,
};

pub fn anchorPoint(self: *Label) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x,
        ._y = &self._y,
    };
}

pub fn addMissingConstraints(self: *Label) void {
    if (values.isUninitialized(self._x)) {
        self._x = 0;
    }
    if (values.isUninitialized(self._y)) {
        self._y = 0;
    }
}

pub fn debug(self: *Label, writer: anytype) !void {
    try writer.print("Label: {s} {s} {s} {s}\n", .{
        self.class,
        @tagName(self.alignment),
        @tagName(self.baseline),
        self.text,
    });
    try writer.print("   x: {d}\n", .{ self._x });
    try writer.print("   y: {d}\n", .{ self._y });
}

const Label = @This();
const PointRef = @import("PointRef.zig");
const DrawingState = @import("DrawingState.zig");
const values = @import("values.zig");
const std = @import("std");
