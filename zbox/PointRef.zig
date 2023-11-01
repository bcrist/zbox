state: *DrawingState,
_x: *f64,
_y: *f64,
mut_x: bool,
mut_y: bool,

pub fn anchorAt(self: PointRef, abs_x: f64, abs_y: f64) PointRef {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.state.removeConstraint(self._x);
    self.state.removeConstraint(self._y);
    self._x.* = abs_x;
    self._y.* = abs_y;
    return self;
}

pub fn attach(self: PointRef, other: PointRef) PointRef {
    _ = other.attachTo(self);
    return self;
}
pub fn attachTo(self: PointRef, target: PointRef) PointRef {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.state.constrainEql(self._x, target._x, "PointRef attachTo x");
    self.state.constrainEql(self._y, target._y, "PointRef attachTo y");
    return self;
}
pub fn attachToOffset(self: PointRef, target: PointRef, offset_x: f64, offset_y: f64) PointRef {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.state.constrainOffset(self._x, target._x, offset_x, "PointRef attachToOffset x");
    self.state.constrainOffset(self._y, target._y, offset_y, "PointRef attachToOffset y");
    return self;
}
pub fn attachBetween(self: PointRef, a: PointRef, b: PointRef, f: f64) PointRef {
    if (!self.mut_x or !self.mut_y) {
        @panic("This point is not mutable");
    }
    self.state.constrainLerp(self._x, a._x, b._x, f, "PointRef x attachBetween");
    self.state.constrainLerp(self._y, a._y, b._y, f, "PointRef y attachBetween");
    return self;
}

pub fn x(self: PointRef) XRef {
    return .{
        .state = self.state,
        ._x = self._x,
        .mut = self.mut_x,
    };
}
pub fn y(self: PointRef) YRef {
    return .{
        .state = self.state,
        ._y = self._y,
        .mut = self.mut_y,
    };
}

pub fn wireH(self: PointRef, options: wires.Options) *WireH {
    const item = self.state.createWireH(options, null);
    self.state.constrainEql(&item._x.begin, self._x, "wire begin x");
    self.state.constrainEql(&item._y, self._y, "wire y");
    return item;
}

pub fn wireV(self: PointRef, options: wires.Options) *WireV {
    const item = self.state.createWireV(options, null);
    self.state.constrainEql(&item._x, self._x, "wire x");
    self.state.constrainEql(&item._y.begin, self._y, "wire begin y");
    return item;
}

const PointRef = @This();
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const WireH = @import("WireH.zig");
const WireV = @import("WireV.zig");
const wires = @import("wires.zig");
const DrawingState = @import("DrawingState.zig");
const std = @import("std");
