state: *Drawing_State,
options: wires.Options,
next: ?*Wire_H = null,
bit_mark_location: ?f64 = null,
_x: f64 = values.uninitialized,
_y: Span = .{},

pub fn x(self: *Wire_V) X_Ref {
    return .{
        .state = self.state,
        ._x = &self._x,
    };
}

pub fn origin(self: *Wire_V) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x,
        ._y = &self._y.begin,
    };
}

pub fn midpoint(self: *Wire_V) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x,
        ._y = &self._y.mid,
    };
}

pub fn endpoint(self: *Wire_V) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x,
        ._y = &self._y.end,
    };
}

pub fn length(self: *Wire_V, len: f64) *Wire_V {
    self.state.remove_constraint(&self._y.delta);
    self._y.delta = len;
    return self;
}
pub fn match_length_of(self: *Wire_V, other: *const Wire_V) *Wire_V {
    self.state.constrain_eql(&self._y.delta, &other._y.delta, "wire match_length_of");
    return self;
}

pub fn bit_mark(self: *Wire_V) *Wire_V {
    self.bit_mark_location = 0.5;
    return self;
}

pub fn bit_mark_at(self: *Wire_V, f: f64) *Wire_V {
    self.bit_mark_location = f;
    return self;
}

pub fn label(self: *Wire_V, text: []const u8, options: Label.Options) *Wire_V {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    var options_mut = options;
    options_mut.angle = -90;
    options_mut._class1 = self.options.class;
    options_mut._class2 = if (self.options.bits > 1) "wire-label bus" else "wire-label";

    const item = self.state.create_label(text, options_mut);

    if (options_mut.baseline == .middle) {
        self.state.constrain_eql(&item._x, &self._x, "wire label x");
        switch (options_mut.alignment) {
            .left, .center => self.state.constrain_offset(&item._y, &self._y.min, style.label_padding_cap, "wire label y from min"),
            .right => self.state.constrain_offset(&item._y, &self._y.max, -style.label_padding_cap, "wire label y from max"),
        }
    } else {
        switch (options_mut.baseline) {
            .normal => self.state.constrain_offset(&item._x, &self._x, -style.label_padding_y, "wire label x"),
            .hanging => self.state.constrain_offset(&item._x, &self._x, style.label_padding_y, "wire label x"),
            .middle => unreachable,
        }
        switch (options_mut.alignment) {
            .left => self.state.constrain_offset(&item._y, &self._y.max, -style.label_padding_x, "wire label y from max"),
            .center => self.state.constrain_eql(&item._y, &self._y.mid, "wire label y from mid"),
            .right => self.state.constrain_offset(&item._y, &self._y.min, style.label_padding_x, "wire label y from min"),
        }
    }
    return self;
}

pub fn turn(self: *Wire_V) *Wire_H {
    if (self.next) |next| return next;
    return self.state.create_wire_h(self.options, self);
}

pub fn turn_at(self: *Wire_V, y: Y_Ref) *Wire_H {
    return self.end_at(y).turn();
}

pub fn turn_at_offset(self: *Wire_V, y: Y_Ref, offset: f64) *Wire_H {
    return self.end_at_offset(y, offset).turn();
}

pub fn turn_between(self: *Wire_V, y0: Y_Ref, y1: Y_Ref, f: f64) *Wire_H {
    self.state.constrain_lerp(&self._y.end, y0._y, y1._y, f, "wire turn_between");
    return self.turn();
}

pub fn turn_and_end_at(self: *Wire_V, end: Point_Ref) *Wire_H {
    return self.turn_at(end.y()).end_at(end.x());
}

pub fn segment(self: *Wire_V) *Wire_V {
    const h_wire = self.turn();
    self.state.constrain_eql(&h_wire._x.end, &self._x, "segment x");
    return h_wire.turn();
}

pub fn continue_at(self: *Wire_V, y: Y_Ref) *Wire_V {
    const h_wire = self.turn_at(y);
    self.state.constrain_eql(&h_wire._x.end, &self._x, "continue_at x");
    return h_wire.turn();
}

pub fn end_at(self: *Wire_V, y: Y_Ref) *Wire_V {
    self.state.constrain_eql(&self._y.end, y._y, "wire end_at");
    return self;
}

pub fn end_at_offset(self: *Wire_V, y: Y_Ref, offset: f64) *Wire_V {
    self.state.constrain_offset(&self._y.end, y._y, offset, "wire end_at_offset");
    return self;
}

pub fn end_at_point(self: *Wire_V, end: Point_Ref) *Wire_V {
    if (values.is_uninitialized(self._x)) {
        _ = self.end_at(end.y());
        self.state.constrain_eql(&self._x, end._x, "wire end_at_point");
        return self;
    } else {
        if (!self._y.is_end_constrained()) {
            self.state.constrain_midpoint(&self._y.end, &self._y.begin, end._y, "wire end_at_point midpoint");
        }
        return self.turn().turn_and_end_at(end);
    }
}

pub fn end_at_mutable_point(self: *Wire_V, end: Point_Ref) *Wire_V {
    _ = self.end_at(end.y());
    self.state.constrain_eql(end._x, &self._x, "wire end_at_mutable_point");
    return self;
}

pub fn add_missing_constraints(self: *Wire_V) void {
    if (self.next) |next| {
        if (self._y.is_end_constrained()) {
            self.state.constrain_eql(&next._y, &self._y.end, "wire segment connection");
        } else if (!values.is_uninitialized(next._y)) {
            self.state.constrain_eql(&self._y.end, &next._y, "wire segment connection");
        } else {
            self.state.constrain_eql(&next._y, &self._y.end, "wire segment connection");
        }

        if (values.is_uninitialized(self._x) and next._x.is_begin_constrained()) {
            self.state.constrain_eql(&self._x, &next._x.begin, "wire segment connection");
        } else {
            self.state.constrain_eql(&next._x.begin, &self._x, "wire segment connection");
        }

        next.add_missing_constraints();
    }

    if (values.is_uninitialized(self._x)) {
        self._x = 0;
    }

    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    self._y.add_missing_constraints(self.state, 0, style.default_length);
}

pub fn debug(self: *Wire_V, writer: anytype) @TypeOf(writer).Error!void {
    try writer.print("Wire_V: {?s}\n   x: {d}\n   y: ", .{
        self.options.class,
        self._x,
    });
    try self._y.debug(writer);

    if (self.next) |next| {
        try writer.writeAll(" -> ");
        try next.debug(writer);
    }
}

const Wire_V = @This();
const Wire_H = @import("Wire_H.zig");
const Point_Ref = @import("Point_Ref.zig");
const X_Ref = @import("X_Ref.zig");
const Y_Ref = @import("Y_Ref.zig");
const Span = @import("Span.zig");
const Label = @import("Label.zig");
const Drawing_State = @import("Drawing_State.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const std = @import("std");
