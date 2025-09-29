state: *Drawing_State,
_y: *f64,
mut: bool = true,

pub fn anchor_at(self: Y_Ref, abs_y: f64) Y_Ref {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.remove_constraint(self._y);
    self._y.* = abs_y;
    return self;
}

pub fn attach(self: Y_Ref, other: Y_Ref) Y_Ref {
    _ = other.attach_to(self);
    return self;
}
pub fn attach_to(self: Y_Ref, target: Y_Ref) Y_Ref {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.constrain_eql(self._y, target._y, "Y_Ref attach_to");
    return self;
}
pub fn attach_to_offset(self: Y_Ref, target: Y_Ref, offset_y: f64) Y_Ref {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.constrain_offset(self._y, target._y, offset_y, "Y_Ref attach_to_offset");
    return self;
}
pub fn attach_between(self: Y_Ref, a: Y_Ref, b: Y_Ref, f: f64) Y_Ref {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.constrain_lerp(self._y, a._y, b._y, f, "Y_Ref attach_between");
    return self;
}

pub fn attach_to_min_offset(self: Y_Ref, targets: []const Y_Ref, offset_y: f64) Y_Ref {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    if (targets.len == 0) return self;
    var dest = self._y;
    if (offset_y != 0) {
        dest = self.state.create_value(0, "(min y)", null);
        self.state.constrain_offset(self._y, dest, offset_y, "Y_Ref attach_to_min offset");
    }
    const temp = self.state.gpa.alloc(*const f64, targets.len) catch @panic("OOM");
    defer self.state.gpa.free(temp);
    for (targets, temp) |target, *y| {
        y.* = target._y;
    }
    self.state.constrain(dest, .{ .min = temp }, "Y_Ref attach_to_min");
    return self;
}

pub fn attach_to_max_offset(self: Y_Ref, targets: []const Y_Ref, offset_y: f64) Y_Ref {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    if (targets.len == 0) return self;
    var dest = self._y;
    if (offset_y != 0) {
        dest = self.state.create_value(0, "(max y)", null);
        self.state.constrain_offset(self._y, dest, offset_y, "Y_Ref attach_to_max offset");
    }
    const temp = self.state.gpa.alloc(*const f64, targets.len) catch @panic("OOM");
    defer self.state.gpa.free(temp);
    for (targets, temp) |target, *y| {
        y.* = target._y;
    }
    self.state.constrain(dest, .{ .max = temp }, "Y_Ref attach_to_max");
    return self;
}

pub fn intersection_with(self: Y_Ref, x: X_Ref) Point_Ref {
    std.debug.assert(self.state == x.state);
    return .{
        .state = self.state,
        ._x = x._x,
        ._y = self._y,
        .mut_x = x.mut,
        .mut_y = self.mut,
    };
}

// Note that this creates a new loose value representing the offset location
pub fn offset(self: Y_Ref, amount: f64) Y_Ref {
    const y = self.state.create_value(values.uninitialized, "(y)", null);
    self.state.constrain_offset(y, self._y, amount, "Y_Ref offset");
    return .{
        .state = self.state,
        ._y = y,
    };
}

pub fn wire(self: Y_Ref, options: wires.Options) *Wire_V {
    const item = self.state.create_wire_v(options, null, null);
    self.state.constrain_eql(&item._y.begin, self._y, "wire begin y");
    return item;
}

const Y_Ref = @This();
const X_Ref = @import("X_Ref.zig");
const Point_Ref = @import("Point_Ref.zig");
const Wire_V = @import("Wire_V.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const Drawing_State = @import("Drawing_State.zig");
const std = @import("std");
