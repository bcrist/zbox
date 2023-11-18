state: *Drawing_State,
_x: *f64,
_y: *f64,
mut_x: bool = true,
mut_y: bool = true,

pub fn anchor_at(self: Point_Ref, abs_x: f64, abs_y: f64) Point_Ref {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.state.remove_constraint(self._x);
    self.state.remove_constraint(self._y);
    self._x.* = abs_x;
    self._y.* = abs_y;
    return self;
}

pub fn attach(self: Point_Ref, other: Point_Ref) Point_Ref {
    _ = other.attach_to(self);
    return self;
}
pub fn attach_to(self: Point_Ref, target: Point_Ref) Point_Ref {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.state.constrain_eql(self._x, target._x, "Point_Ref attach_to x");
    self.state.constrain_eql(self._y, target._y, "Point_Ref attach_to y");
    return self;
}
pub fn attach_to_offset(self: Point_Ref, target: Point_Ref, offset_x: f64, offset_y: f64) Point_Ref {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.state.constrain_offset(self._x, target._x, offset_x, "Point_Ref attach_to_offset x");
    self.state.constrain_offset(self._y, target._y, offset_y, "Point_Ref attach_to_offset y");
    return self;
}
pub fn attach_between(self: Point_Ref, a: Point_Ref, b: Point_Ref, f: f64) Point_Ref {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.state.constrain_lerp(self._x, a._x, b._x, f, "Point_Ref x attach_between");
    self.state.constrain_lerp(self._y, a._y, b._y, f, "Point_Ref y attach_between");
    return self;
}

pub fn x(self: Point_Ref) X_Ref {
    return .{
        .state = self.state,
        ._x = self._x,
        .mut = self.mut_x,
    };
}
pub fn y(self: Point_Ref) Y_Ref {
    return .{
        .state = self.state,
        ._y = self._y,
        .mut = self.mut_y,
    };
}

pub fn offset(self: Point_Ref, x_offset: f64, y_offset: f64) Point_Ref {
    const xv = self.state.create_value(values.uninitialized);
    const yv = self.state.create_value(values.uninitialized);
    self.state.constrain_offset(xv, self._x, x_offset, "Point_Ref x offset");
    self.state.constrain_offset(yv, self._y, y_offset, "Point_Ref y offset");
    return .{
        .state = self.state,
        ._x = xv,
        ._y = yv,
    };
}

pub fn label(self: Point_Ref, class: []const u8, alignment: Label.Alignment, baseline: Label.Baseline, text: []const u8) *Label {
    const item = self.state.create_label(text, class, alignment, baseline, 0);
    self.state.constrain_eql(&item._x, self._x, "label x");
    self.state.constrain_eql(&item._y, self._y, "label y");
    return item;
}
pub fn label_v(self: Point_Ref, class: []const u8, alignment: Label.Alignment, baseline: Label.Baseline, text: []const u8) *Label {
    const item = self.state.create_label(text, class, alignment, baseline, -90);
    self.state.constrain_eql(&item._x, self._x, "label x");
    self.state.constrain_eql(&item._y, self._y, "label y");
    return item;
}

pub fn wire_h(self: Point_Ref, options: wires.Options) *Wire_H {
    const item = self.state.create_wire_h(options, null);
    self.state.constrain_eql(&item._x.begin, self._x, "wire begin x");
    self.state.constrain_eql(&item._y, self._y, "wire y");
    return item;
}

pub fn wire_v(self: Point_Ref, options: wires.Options) *Wire_V {
    const item = self.state.create_wire_v(options, null);
    self.state.constrain_eql(&item._x, self._x, "wire x");
    self.state.constrain_eql(&item._y.begin, self._y, "wire begin y");
    return item;
}

const Point_Ref = @This();
const X_Ref = @import("X_Ref.zig");
const Y_Ref = @import("Y_Ref.zig");
const Label = @import("Label.zig");
const Wire_H = @import("Wire_H.zig");
const Wire_V = @import("Wire_V.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const Drawing_State = @import("Drawing_State.zig");
const std = @import("std");
