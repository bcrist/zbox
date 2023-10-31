state: *DrawingState,
options: wires.Options,
next: ?*WireH = null,
_x: f64 = values.uninitialized,
_y: Span = .{},

pub fn origin(self: *WireV) PointRef {
    return .{
        .state = self.state,
        ._x = self._x,
        ._y = self._y.begin,
    };
}

pub fn midpoint(self: *WireV) PointRef {
    return .{
        .state = self.state,
        ._x = self._x,
        ._y = self._y.mid,
    };
}

pub fn endpoint(self: *WireV) PointRef {
    return .{
        .state = self.state,
        ._x = self._x,
        ._y = self._y.end,
    };
}

pub fn length(self: *WireV, len: f64) *WireV {
    self.state.removeConstraint(&self._y.delta);
    self._y.delta = len;
    return self;
}
pub fn matchLengthOf(self: *WireV, other: *const WireV) *WireV {
    // TODO bidirectional copy constraints
    self.state.constrain(&self._y.delta, .{ .copy = &other._y.delta });
    return self;
}

// TODO labels, bit markers

pub fn turn(self: *WireV) *WireH {
    if (self.next) |next| return next;

    const item = self.state.createWireH(.{}, self);
    // constrain the x coordinates so that the wire will be continuous:
    // TODO bidirectional copy constraints
    if (values.isConstrained(self._x)) {
        self.state.constrain(&item._x.begin, .{ .copy = &self._x }, "wire turn");
    } else {
        self.state.constrain(&self._x, .{ .copy = &item._x.begin }, "wire turn");
    }
    // Constrain the y coordinates so that the wire will be continuous:
    // TODO bidirectional copy constraints
    if (self._y.isFullyConstrained()) {
        self.state.constrain(&item._y, .{ .copy = &self._y.end }, "wire turn");
    } else {
        self.state.constrain(&self._y.end, .{ .copy = &item._y }, "wire turn");
    }
    return item;
}

pub fn turnAt(self: *WireV, y: YRef) *WireH {
    _ = self.endAt(y);
    return self.turn();
}

pub fn endAt(self: *WireV, y: YRef) *WireV {
    // TODO bidirectional copy constraints
    self.state.constrain(&self._y.end, .{ .copy = y._y }, "wire endAt");
    return self;
}

pub fn endAtPoint(self: *WireV, end: PointRef) *WireV {
    _ = self.endAt(end.y());
    // TODO bidirectional copy constraints
    if (values.isConstrained(self._x)) {
        self.state.constrain(&end._x, .{ .copy = &self._x }, "wire endAtPoint");
    } else {
        self.state.constrain(&self._x, .{ .copy = &end._x }, "wire endAtPoint");
    }
    return self;
}

pub fn turnAndEndAt(self: *WireV, end: PointRef) *WireH {
    return self.turnAt(end.y()).endAt(end.x());
}

pub fn addMissingConstraints(self: *WireV) void {
    if (values.isUninitialized(self._x)) {
        self._x = 0;
    }

    self._y.addMissingConstraints(self.state, 0, self.state.drawing.style.default_wire_length);
}

pub fn debug(self: *WireV, writer: anytype) !void {
    try writer.print("WireV: {s}\n   x: {d}\n   y: ", .{
        self.class,
        self._x,
    });
    try self._y.debug(writer);
}

const WireV = @This();
const WireH = @import("WireH.zig");
const PointRef = @import("PointRef.zig");
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const Span = @import("Span.zig");
const DrawingState = @import("DrawingState.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const std = @import("std");
