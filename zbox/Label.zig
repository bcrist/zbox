state: *Drawing_State,
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
    size: f64 = 0, // 0 = default
    debug: []const u8 = "",
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

pub fn anchor_point(self: *Label) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x,
        ._y = &self._y,
    };
}

pub fn add_missing_constraints(self: *Label) void {
    if (values.is_uninitialized(self._x)) {
        self._x = 0;
    }
    if (values.is_uninitialized(self._y)) {
        self._y = 0;
    }
}

pub fn format(self: *Label, writer: *std.io.Writer) error{WriteFailed}!void {
    try writer.print("Label: {s} {t} {t} {s}\n", .{
        self.options.class,
        self.options.alignment,
        self.options.baseline,
        self.text,
    });
    try writer.print("   x: {d}\n", .{ self._x });
    try writer.print("   y: {d}\n", .{ self._y });
}

pub fn set_debug_name(self: *Label, debug_name: []const u8, parent: ?*const anyopaque) void {
    self.state.add_debug_value_name(self, debug_name, parent);
    self.state.add_debug_value_name(&self._x, "_x", self);
    self.state.add_debug_value_name(&self._y, "_y", self);
}

const Label = @This();
const Point_Ref = @import("Point_Ref.zig");
const Drawing_State = @import("Drawing_State.zig");
const values = @import("values.zig");
const std = @import("std");
