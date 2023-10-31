drawing: *Drawing,
_x: *f64,
_y: *f64,
mut_x: bool,
mut_y: bool,

pub fn anchorAt(self: PointRef, abs_x: f64, abs_y: f64) PointRef {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.drawing.removeConstraint(self._x);
    self.drawing.removeConstraint(self._y);
    self._x.* = abs_x;
    self._y.* = abs_y;
    return self;
}

pub fn attach(self: PointRef, other: PointRef) PointRef {
    other.attachTo(self);
    return self;
}
pub fn attachTo(self: PointRef, target: PointRef) PointRef {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    // TODO bidirectional copy constraints
    self.drawing.constrain(self._x, .{ .copy = target._x });
    self.drawing.constrain(self._y, .{ .copy = target._y });
    return self;
}
pub fn attachToOffset(self: PointRef, target: PointRef, offset_x: f64, offset_y: f64) PointRef {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.drawing.constrain(self._x, .{ .offset_and_scale = .{
        .src = target._x,
        .offset = offset_x,
        .scale = 1,
    }});
    self.drawing.constrain(self._y, .{ .offset_and_scale = .{
        .src = target._y,
        .offset = offset_y,
        .scale = 1,
    }});
    return self;
}
pub fn attachBetween(self: PointRef, a: PointRef, b: PointRef, f: f64) PointRef {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.drawing.constrain(self._x, .{ .lerp = .{
        .operands = .{ a._x, b._x },
        .k = f,
    }}, "PointRef x attachBetween");
    self.drawing.constrain(self._y, .{ .lerp = .{
        .operands = .{ a._y, b._y },
        .k = f,
    }}, "PointRef y attachBetween");
    return self;
}

pub fn x(self: PointRef) XRef {
    return .{
        .drawing = self.drawing,
        ._x = self._x,
        .mut = self.mut_x,
    };
}
pub fn y(self: PointRef) YRef {
    return .{
        .drawing = self.drawing,
        ._y = self._y,
        .mut = self.mut_y,
    };
}

pub fn wireH(self: PointRef, options: wires.Options) *WireH {
    const arena = self.drawing.arena.allocator();
    const item = arena.create(WireH) catch @panic("OOM");
    item.* = .{
        .drawing = self.drawing,
        .options = options,
    };
    self.drawing.wires_h.append(self.drawing.gpa, item) catch @panic("OOM");
    // TODO bidirectional copy constraints
    self.drawing.constrain(&item._x.begin, .{ .copy = self._x }, "wire begin x");
    self.drawing.constrain(&item._y, .{ .copy = self._y }, "wire y");
    return item;
}

pub fn wireV(self: PointRef, options: wires.Options) *WireV {
    const arena = self.drawing.arena.allocator();
    const item = arena.create(WireV) catch @panic("OOM");
    item.* = .{
        .drawing = self.drawing,
        .options = options,
    };
    self.drawing.wires_v.append(self.drawing.gpa, item) catch @panic("OOM");
    // TODO bidirectional copy constraints
    self.drawing.constrain(&item._x, .{ .copy = self._x }, "wire x");
    self.drawing.constrain(&item._y.begin, .{ .copy = self._y }, "wire begin y");
    return item;
}

const PointRef = @This();
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const WireH = @import("WireH.zig");
const WireV = @import("WireV.zig");
const wires = @import("wires.zig");
const Drawing = @import("Drawing.zig");
const std = @import("std");
