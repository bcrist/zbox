state: *Drawing_State,
_x: *f64,
mut: bool = true,

pub fn anchor_at(self: X_Ref, abs_x: f64) X_Ref {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.state.remove_constraint(self._x);
    self._x.* = abs_x;
    return self;
}

pub fn attach(self: X_Ref, other: X_Ref) X_Ref {
    _ = other.attach_to(self);
    return self;
}
pub fn attach_to(self: X_Ref, target: X_Ref) X_Ref {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.state.constrain_eql(self._x, target._x, "X_Ref attach_to");
    return self;
}
pub fn attach_to_offset(self: X_Ref, target: X_Ref, offset_x: f64) X_Ref {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.state.constrain_offset(self._x, target._x, offset_x, "X_Ref attach_to_offset");
    return self;
}
pub fn attach_between(self: X_Ref, a: X_Ref, b: X_Ref, f: f64) X_Ref {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.state.constrain_lerp(self._x, a._x, b._x, f, "X_Ref attach_between");
    return self;
}

pub fn intersection_with(self: X_Ref, y: Y_Ref) Point_Ref {
    std.debug.assert(self.state == y.state);
    return .{
        .state = self.state,
        ._x = self._x,
        ._y = y._y,
        .mut_x = self.mut,
        .mut_y = y.mut,
    };
}

// Note that this creates a new loose value representing the offset location
pub fn offset(self: X_Ref, amount: f64) X_Ref {
    const x = self.state.create_value(values.uninitialized);
    self.state.constrain_offset(x, self._x, amount, "X_Ref offset");
    return .{
        .state = self.state,
        ._x = x,
    };
}

pub fn wire(self: X_Ref, options: wires.Options) *Wire_H {
    const item = self.state.create_wire_h(options, null);
    self.state.constrain_eql(&item._x.begin, self._x, "wire begin x");
    return item;
}

const X_Ref = @This();
const Y_Ref = @import("Y_Ref.zig");
const Point_Ref = @import("Point_Ref.zig");
const Wire_H = @import("Wire_H.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const Drawing_State = @import("Drawing_State.zig");
const std = @import("std");
