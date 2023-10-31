state: *DrawingState,
options: wires.Options,
next: ?*WireV = null,
_y: f64 = values.uninitialized,
_x: Span = .{},

pub fn origin(self: *WireH) PointRef {
    return .{
        .state = self.state,
        ._x = self._x.begin,
        ._y = self._y,
    };
}

pub fn midpoint(self: *WireH) PointRef {
    return .{
        .state = self.state,
        ._x = self._x.mid,
        ._y = self._y,
    };
}

pub fn endpoint(self: *WireH) PointRef {
    return .{
        .state = self.state,
        ._x = self._x.end,
        ._y = self._y,
    };
}

pub fn length(self: *WireH, len: f64) *WireH {
    self.state.removeConstraint(&self._x.delta);
    self._x.delta = len;
    return self;
}
pub fn matchLengthOf(self: *WireH, other: *const WireH) *WireH {
    // TODO bidirectional copy constraints
    self.state.constrain(&self._x.delta, .{ .copy = &other._x.delta });
    return self;
}

// TODO labels, bit markers

pub fn turn(self: *WireH) *WireV {
    if (self.next) |next| return next;

    const item = self.state.createWireV(.{}, self);
    // constrain the y coordinates so that the wire will be continuous:
    // TODO bidirectional copy constraints
    if (values.isConstrained(self._y)) {
        self.state.constrain(&item._y.begin, .{ .copy = &self._y }, "wire turn");
    } else {
        self.state.constrain(&self._y, .{ .copy = &item._y.begin }, "wire turn");
    }
    // Constrain the x coordinates so that the wire will be continuous:
    // TODO bidirectional copy constraints
    if (self._x.isFullyConstrained()) {
        self.state.constrain(&item._x, .{ .copy = &self._x.end }, "wire turn");
    } else {
        self.state.constrain(&self._x.end, .{ .copy = &item._x }, "wire turn");
    }
    return item;
}

pub fn turnAt(self: *WireH, x: XRef) *WireV {
    _ = self.endAt(x);
    return self.turn();
}

pub fn endAt(self: *WireH, x: XRef) *WireH {
    // TODO bidirectional copy constraints
    self.state.constrain(&self._x.end, .{ .copy = x._x }, "wire endAt");
    return self;
}

pub fn endAtPoint(self: *WireH, end: PointRef) *WireH {
    _ = self.endAt(end.x());
    // TODO bidirectional copy constraints
    if (values.isConstrained(self._y)) {
        self.state.constrain(&end._y, .{ .copy = &self._y }, "wire endAtPoint");
    } else {
        self.state.constrain(&self._y, .{ .copy = &end._y }, "wire endAtPoint");
    }
    return self;
}

pub fn turnAndEndAt(self: *WireH, end: PointRef) *WireV {
    return self.turnAt(end.x()).endAt(end.y());
}

pub fn addMissingConstraints(self: *WireH) void {
    if (values.isUninitialized(self._y)) {
        self._y = 0;
    }

    self._x.addMissingConstraints(self.state, 0, self.state.drawing.style.default_wire_length);
}

pub fn debug(self: *WireH, writer: anytype) !void {
    try writer.print("WireH: {s}\n   x: ", .{
        self.class,
    });
    try self._x.debug(writer);
    try writer.print("   y: {d}\n", .{
        self._y,
    });
}

const WireH = @This();
const WireV = @import("WireV.zig");
const PointRef = @import("PointRef.zig");
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const Span = @import("Span.zig");
const DrawingState = @import("DrawingState.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const std = @import("std");
