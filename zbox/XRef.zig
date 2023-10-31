drawing: *Drawing,
_x: *f64,
mut: bool,

pub fn anchorAt(self: XRef, abs_x: f64) XRef {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.drawing.removeConstraint(self._x);
    self._x.* = abs_x;
    return self;
}

pub fn attach(self: XRef, other: XRef) XRef {
    other.attachTo(self);
    return self;
}
pub fn attachTo(self: XRef, target: XRef) XRef {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    // TODO bidirectional copy constraints
    self.drawing.constrain(self._x, .{ .copy = target._x }, "XRef attachTo");
    return self;
}
pub fn attachToOffset(self: XRef, target: XRef, offset_x: f64) XRef {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.drawing.constrain(self._x, .{ .offset_and_scale = .{
        .src = target._x,
        .offset = offset_x,
        .scale = 1,
    }}, "XRef attachToOffset");
    return self;
}
pub fn attachBetween(self: XRef, a: XRef, b: XRef, f: f64) XRef {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.drawing.constrain(self._x, .{ .lerp = .{
        .operands = .{ a._x, b._x },
        .k = f,
    }}, "XRef attachBetween");
    return self;
}

pub fn intersectionWith(self: XRef, y: YRef) PointRef {
    std.debug.assert(self.drawing == y.drawing);
    return .{
        .drawing = self.drawing,
        ._x = self._x,
        ._y = y._y,
        .mut_x = self.mut,
        .mut_y = y.mut,
    };
}

pub fn wire(self: XRef, options: wires.Options) *WireH {
    const arena = self.drawing.arena.allocator();
    const item = arena.create(WireH) catch @panic("OOM");
    item.* = .{
        .drawing = self.drawing,
        .options = options,
    };
    self.drawing.wires_h.append(self.drawing.gpa, item) catch @panic("OOM");
    // TODO bidirectional copy constraints
    self.drawing.constrain(&item._x.begin, .{ .copy = self._x }, "wire begin x");
    return item;
}

const XRef = @This();
const YRef = @import("YRef.zig");
const PointRef = @import("PointRef.zig");
const WireH = @import("WireH.zig");
const wires = @import("wires.zig");
const Drawing = @import("Drawing.zig");
const std = @import("std");
