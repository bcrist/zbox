state: *DrawingState,
_y: *f64,
mut: bool = true,

pub fn anchorAt(self: YRef, abs_y: f64) YRef {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.removeConstraint(self._y);
    self._y.* = abs_y;
    return self;
}

pub fn attach(self: YRef, other: YRef) YRef {
    _ = other.attachTo(self);
    return self;
}
pub fn attachTo(self: YRef, target: YRef) YRef {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.constrainEql(self._y, target._y, "YRef attachTo");
    return self;
}
pub fn attachToOffset(self: YRef, target: YRef, offset_y: f64) YRef {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.constrainOffset(self._y, target._y, offset_y, "YRef attachToOffset");
    return self;
}
pub fn attachBetween(self: YRef, a: YRef, b: YRef, f: f64) YRef {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.constrainLerp(self._y, a._y, b._y, f, "YRef attachBetween");
    return self;
}

pub fn intersectionWith(self: YRef, x: XRef) PointRef {
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
pub fn offset(self: YRef, amount: f64) YRef {
    const y = self.state.createValue(values.uninitialized);
    self.state.constrainOffset(y, self._y, amount, "YRef offset");
    return .{
        .state = self.state,
        ._y = y,
    };
}

pub fn wire(self: YRef, options: wires.Options) *WireV {
    const item = self.state.createWireV(options, null);
    self.state.constrainEql(&item._y.begin, self._y, "wire begin y");
    return item;
}

const YRef = @This();
const XRef = @import("XRef.zig");
const PointRef = @import("PointRef.zig");
const WireV = @import("WireV.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const DrawingState = @import("DrawingState.zig");
const std = @import("std");
