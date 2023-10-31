text: []const u8,
class: []const u8,
alignment: Alignment,
baseline: enum {
    normal,
    middle,
    hanging,
},
angle: f64 = 0,
_x: f64 = values.uninitialized,
_y: f64 = values.uninitialized,

pub const Alignment = enum {
    left,
    center,
    right,
};

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
const values = @import("values.zig");
const std = @import("std");
