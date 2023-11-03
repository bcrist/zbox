state: *DrawingState,
_x: *f64,
mut: bool = true,

pub fn anchorAt(self: XRef, abs_x: f64) XRef {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.state.removeConstraint(self._x);
    self._x.* = abs_x;
    return self;
}

pub fn attach(self: XRef, other: XRef) XRef {
    _ = other.attachTo(self);
    return self;
}
pub fn attachTo(self: XRef, target: XRef) XRef {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.state.constrainEql(self._x, target._x, "XRef attachTo");
    return self;
}
pub fn attachToOffset(self: XRef, target: XRef, offset_x: f64) XRef {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.state.constrainOffset(self._x, target._x, offset_x, "XRef attachToOffset");
    return self;
}
pub fn attachBetween(self: XRef, a: XRef, b: XRef, f: f64) XRef {
    if (!self.mut) {
        @panic("This x coordinate is not mutable");
    }
    self.state.constrainLerp(self._x, a._x, b._x, f, "XRef attachBetween");
    return self;
}

pub fn intersectionWith(self: XRef, y: YRef) PointRef {
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
pub fn offset(self: XRef, amount: f64) XRef {
    const x = self.state.createValue(values.uninitialized);
    self.state.constrainOffset(x, self._x, amount, "XRef offset");
    return .{
        .state = self.state,
        ._x = x,
    };
}

pub fn wire(self: XRef, options: wires.Options) *WireH {
    const item = self.state.createWireH(options, null);
    self.state.constrainEql(&item._x.begin, self._x, "wire begin x");
    return item;
}

const XRef = @This();
const YRef = @import("YRef.zig");
const PointRef = @import("PointRef.zig");
const WireH = @import("WireH.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const DrawingState = @import("DrawingState.zig");
const std = @import("std");
