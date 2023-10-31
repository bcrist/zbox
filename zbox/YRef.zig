state: *DrawingState,
_y: *f64,
mut: bool,

pub fn anchorAt(self: YRef, abs_y: f64) YRef {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.removeConstraint(self._y);
    self._y.* = abs_y;
    return self;
}

pub fn attach(self: YRef, other: YRef) YRef {
    other.attachTo(self);
    return self;
}
pub fn attachTo(self: YRef, target: YRef) YRef {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    // TODO bidirectional copy constraints
    self.state.constrain(self._y, .{ .copy = target._y });
    return self;
}
pub fn attachToOffset(self: YRef, target: YRef, offset_y: f64) YRef {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.constrain(self._y, .{ .offset_and_scale = .{
        .src = target._y,
        .offset = offset_y,
        .scale = 1,
    }});
    return self;
}
pub fn attachBetween(self: YRef, a: YRef, b: YRef, f: f64) YRef {
    if (!self.mut) {
        @panic("This y coordinate is not mutable");
    }
    self.state.constrain(self._y, .{ .lerp = .{
        .operands = .{ a._y, b._y },
        .k = f,
    }}, "YRef attachBetween");
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

pub fn wire(self: YRef, options: wires.Options) *WireV {
    const item = self.state.createWireV(options, null);
    // TODO bidirectional copy constraints
    self.state.constrain(&item._y.begin, .{ .copy = self._y }, "wire begin y");
    return item;
}

const YRef = @This();
const XRef = @import("XRef.zig");
const PointRef = @import("PointRef.zig");
const WireV = @import("WireV.zig");
const wires = @import("wires.zig");
const DrawingState = @import("DrawingState.zig");
const std = @import("std");
