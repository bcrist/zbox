state: *Drawing_State,
options: wires.Options,
bit_mark_location: ?f64 = null,
next: ?*Wire_V = null,
_label: ?*Label = null,
_y: f64 = values.uninitialized,
_x: Span = .{},

pub fn ref(self: *Wire_H) wires.Wire_Ref {
    return .{ .H = self };
}

pub fn iterator(self: *Wire_H) wires.Iterator {
    return .{ .wire = self.ref() };
}

pub fn y(self: *Wire_H) Y_Ref {
    return .{
        .state = self.state,
        ._y = &self._y,
    };
}

pub fn origin(self: *Wire_H) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = &self._y,
    };
}

pub fn midpoint(self: *Wire_H) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
        ._y = &self._y,
    };
}

pub fn endpoint(self: *Wire_H) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = &self._y,
    };
}

pub fn length(self: *Wire_H, len: f64) *Wire_H {
    self.state.remove_constraint(&self._x.delta);
    self._x.delta = len;
    return self;
}
pub fn match_length_of(self: *Wire_H, other: *const Wire_H) *Wire_H {
    self.state.constrain_eql(&self._x.delta, &other._x.delta, "wire match_length_of");
    return self;
}

pub fn bit_mark(self: *Wire_H) *Wire_H {
    self.bit_mark_location = 0.5;
    return self;
}

pub fn bit_mark_at(self: *Wire_H, f: f64) *Wire_H {
    self.bit_mark_location = f;
    return self;
}

pub fn change_options(self: *Wire_H, options: wires.Options) *Wire_H {
    self.options = options;
    return self;
}

pub fn change_class(self: *Wire_H, new_class: []const u8) *Wire_H {
    self.options.class = new_class;
    return self;
}

pub fn change_bits(self: *Wire_H, new_bits: usize) *Wire_H {
    self.options.bits = new_bits;
    return self;
}

pub fn label(self: *Wire_H, text: []const u8, options: Label.Options) *Wire_H {
    if (text.len == 0) {
        self._label = null;
        return self;
    }

    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    var options_mut = options;
    options_mut.angle = 0;
    options_mut._class1 = self.options.class;
    options_mut._class2 = if (self.options.bits > 1) "wire-label bus" else "wire-label";

    const item = self.state.create_label(text, options_mut, self);
    self._label = item;

    if (options_mut.baseline == .middle) {
        self.state.constrain_eql(&item._y, &self._y, "wire label y");
        switch (options_mut.alignment) {
            .left, .center => self.state.constrain_offset(&item._x, &self._x.max, style.label_padding_cap, "wire label x from max"),
            .right => self.state.constrain_offset(&item._x, &self._x.min, -style.label_padding_cap, "wire label x from min"),
        }
    } else {
        switch (options_mut.baseline) {
            .normal => self.state.constrain_offset(&item._y, &self._y, -style.label_padding_y, "wire label y"),
            .hanging => self.state.constrain_offset(&item._y, &self._y, style.label_padding_y, "wire label y"),
            .middle => unreachable,
        }
        switch (options_mut.alignment) {
            .left => self.state.constrain_offset(&item._x, &self._x.min, style.label_padding_x, "wire label x from min"),
            .center => self.state.constrain_eql(&item._x, &self._x.mid, "wire label x from mid"),
            .right => self.state.constrain_offset(&item._x, &self._x.max, -style.label_padding_x, "wire label x from max"),
        }
    }
    return self;
}

pub fn fmt_label(self: *Wire_H, comptime fmt: []const u8, args: anytype, options: Label.Options) *Wire_H {
    return self.label(self.state.print(fmt, args), options);
}

pub fn turn(self: *Wire_H) *Wire_V {
    if (self.next) |next| return next;
    return self.state.create_wire_v(self.options, self, null);
}

pub fn turn_at(self: *Wire_H, x: X_Ref) *Wire_V {
    return self.end_at(x).turn();
}

pub fn turn_at_offset(self: *Wire_H, x: X_Ref, offset: f64) *Wire_V {
    return self.end_at_offset(x, offset).turn();
}

pub fn turn_between(self: *Wire_H, x0: X_Ref, x1: X_Ref, f: f64) *Wire_V {
    self.state.constrain_lerp(&self._x.end, x0._x, x1._x, f, "wire turn_between");
    return self.turn();
}

pub fn turn_and_end_at(self: *Wire_H, end: Point_Ref) *Wire_V {
    return self.turn_at(end.x()).end_at(end.y());
}

pub fn segment(self: *Wire_H) *Wire_H {
    const v_wire = self.turn();
    self.state.constrain_eql(&v_wire._y.end, &self._y, "segment y");
    return v_wire.turn();
}

pub fn continue_at(self: *Wire_H, x: X_Ref) *Wire_H {
    const v_wire = self.turn_at(x);
    self.state.constrain_eql(&v_wire._y.end, &self._y, "continue_at y");
    return v_wire.turn();
}

pub fn continue_at_offset(self: *Wire_H, x: X_Ref, offset: f64) *Wire_H {
    const v_wire = self.turn_at_offset(x, offset);
    self.state.constrain_eql(&v_wire._y.end, &self._y, "continue_at y");
    return v_wire.turn();
}

pub fn small_box(self: *Wire_H, text: []const u8, direction: Direction) *Wire_H {
    const box = self.state.create_box(.{ .shape = .small, .label = text }, self);
    if (text.len > 3) {
        _ = box.width(@floatFromInt(text.len * 6 + 10));
    }
    switch (direction) {
        .left => _ = box.middle_right().attach_to(self.endpoint()),
        .right => _ = box.middle_left().attach_to(self.endpoint()),
    }

    var new_wire_options = self.options;
    new_wire_options.dir = .init(.none, self.options.dir.end());
    self.options.dir = .init(self.options.dir.begin(), .none);

    return switch (direction) {
        .left => box.left_side("").wire_h(new_wire_options),
        .right => box.right_side("").wire_h(new_wire_options),
    };
}

pub fn small_box_at(self: *Wire_H, x: X_Ref, text: []const u8, direction: Direction) *Wire_H {
    return self.end_at(x).small_box(text, direction);
}

pub fn small_box_at_offset(self: *Wire_H, x: X_Ref, offset: f64, text: []const u8, direction: Direction) *Wire_H {
    return self.end_at_offset(x, offset).small_box(text, direction);
}

pub fn end_at(self: *Wire_H, x: X_Ref) *Wire_H {
    self.state.constrain_eql(&self._x.end, x._x, "wire end_at");
    return self;
}

pub fn end_at_offset(self: *Wire_H, x: X_Ref, offset: f64) *Wire_H {
    self.state.constrain_offset(&self._x.end, x._x, offset, "wire end_at_offset");
    return self;
}

pub fn end_at_point(self: *Wire_H, end: Point_Ref) *Wire_H {
    if (values.is_uninitialized(self._y)) {
        _ = self.end_at(end.x());
        self.state.constrain_eql(&self._y, end._y, "wire end_at_point");
        return self;
    } else {
        if (!self._x.is_end_constrained()) {
            self.state.constrain_midpoint(&self._x.end, &self._x.begin, end._x, "wire end_at_point midpoint");
        }
        return self.turn().turn_and_end_at(end);
    }
}

pub fn end_at_mutable_point(self: *Wire_H, end: Point_Ref) *Wire_H {
    _ = self.end_at(end.x());
    self.state.constrain_eql(end._y, &self._y, "wire end_at_mutable_point");
    return self;
}

pub fn add_missing_constraints(self: *Wire_H) void {
    if (self._label) |l| {
        l.set_debug_name("_label", self);
    }
    if (self.next) |next| {
        next.set_debug_name("", self);

        if (self._x.is_end_constrained()) {
            self.state.constrain_eql(&next._x, &self._x.end, "wire segment connection");
        } else if (!values.is_uninitialized(next._x)) {
            self.state.constrain_eql(&self._x.end, &next._x, "wire segment connection");
        } else {
            self.state.constrain_eql(&next._x, &self._x.end, "wire segment connection");
        }

        if (values.is_uninitialized(self._y) and next._y.is_begin_constrained()) {
            self.state.constrain_eql(&self._y, &next._y.begin, "wire segment connection");
        } else {
            self.state.constrain_eql(&next._y.begin, &self._y, "wire segment connection");
        }

        next.add_missing_constraints();
    }

    if (values.is_uninitialized(self._y)) {
        self._y = 0;
    }

    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    self._x.add_missing_constraints(self.state, 0, style.default_length);
}

/// N.B. this only works once constraints have been evaluated
pub fn contains_point(self: *Wire_H, px: f64, py: f64) bool {
    if (std.math.approxEqAbs(f64, self._y, py, 0.5)) {
        if (self._x.min - 0.5 <= px and self._x.max + 0.5 >= px) return true;
    }
    if (self.next) |next| {
        return next.contains_point(px, py);
    }
    return false;
}

pub fn format(self: *Wire_H, writer: *std.io.Writer) error{WriteFailed}!void {
    try writer.print("Wire_H: {s}\n   x: ", .{
        self.options.class,
    });
    try self._x.format(writer);
    try writer.print("   y: {d}\n", .{
        self._y,
    });

    if (self.next) |next| {
        try writer.writeAll(" -> ");
        try next.format(writer);
    }
}

pub fn set_debug_name(self: *Wire_H, debug_name: []const u8, parent: ?*const anyopaque) void {
    self.state.add_debug_value_name(self, debug_name, parent);
    self.state.add_debug_value_name(&self._y, "_y", self);
    self._x.set_debug_name(self.state, "_x", self);
}

const Direction = enum {
    left,
    right,
};

const Wire_H = @This();
const Wire_V = @import("Wire_V.zig");
const Point_Ref = @import("Point_Ref.zig");
const X_Ref = @import("X_Ref.zig");
const Y_Ref = @import("Y_Ref.zig");
const Span = @import("Span.zig");
const Label = @import("Label.zig");
const Drawing_State = @import("Drawing_State.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const std = @import("std");
