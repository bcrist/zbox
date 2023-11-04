state: *DrawingState,
options: wires.Options,
bit_mark: ?f64 = null,
next: ?*WireV = null,
_y: f64 = values.uninitialized,
_x: Span = .{},

pub fn y(self: *WireH) YRef {
    return .{
        .state = self.state,
        ._y = &self._y,
    };
}

pub fn origin(self: *WireH) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = &self._y,
    };
}

pub fn midpoint(self: *WireH) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
        ._y = &self._y,
    };
}

pub fn endpoint(self: *WireH) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = &self._y,
    };
}

pub fn length(self: *WireH, len: f64) *WireH {
    self.state.removeConstraint(&self._x.delta);
    self._x.delta = len;
    return self;
}
pub fn matchLengthOf(self: *WireH, other: *const WireH) *WireH {
    self.state.constrainEql(&self._x.delta, &other._x.delta, "wire matchLengthOf");
    return self;
}

pub fn bitMark(self: *WireH) *WireH {
    self.bit_mark = 0.5;
    return self;
}

pub fn bitMarkAt(self: *WireH, f: f64) *WireH {
    self.bit_mark = f;
    return self;
}

pub fn label(self: *WireH, text: []const u8, options: Label.Options) *WireH {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    var options_mut = options;
    options_mut.angle = 0;
    options_mut._class1 = self.options.class;
    options_mut._class2 = if (self.options.bits > 1) "wire-label bus" else "wire-label";

    const item = self.state.createLabel(text, options_mut);

    if (options_mut.baseline == .middle) {
        self.state.constrainEql(&item._y, &self._y, "wire label y");
        switch (options_mut.alignment) {
            .left, .center => self.state.constrainOffset(&item._x, &self._x.max, style.label_padding_cap, "wire label x from max"),
            .right => self.state.constrainOffset(&item._x, &self._x.min, -style.label_padding_cap, "wire label x from min"),
        }
    } else {
        switch (options_mut.baseline) {
            .normal => self.state.constrainOffset(&item._y, &self._y, -style.label_padding_y, "wire label y"),
            .hanging => self.state.constrainOffset(&item._y, &self._y, style.label_padding_y, "wire label y"),
            .middle => unreachable,
        }
        switch (options_mut.alignment) {
            .left => self.state.constrainOffset(&item._x, &self._x.min, style.label_padding_x, "wire label x from min"),
            .center => self.state.constrainEql(&item._x, &self._x.mid, "wire label x from mid"),
            .right => self.state.constrainOffset(&item._x, &self._x.max, -style.label_padding_x, "wire label x from max"),
        }
    }
    return self;
}

pub fn turn(self: *WireH) *WireV {
    if (self.next) |next| return next;
    return self.state.createWireV(self.options, self);
}

pub fn turnAt(self: *WireH, x: XRef) *WireV {
    return self.endAt(x).turn();
}

pub fn turnAtOffset(self: *WireH, x: XRef, offset: f64) *WireV {
    return self.endAtOffset(x, offset).turn();
}

pub fn turnAndEndAt(self: *WireH, end: PointRef) *WireV {
    return self.turnAt(end.x()).endAt(end.y());
}

pub fn continueAt(self: *WireH, x: XRef) *WireH {
    const v_wire = self.turnAt(x);
    self.state.constrainEql(&v_wire._y.end, &self._y, "continueAt y");
    return v_wire.turn();
}

pub fn endAt(self: *WireH, x: XRef) *WireH {
    self.state.constrainEql(&self._x.end, x._x, "wire endAt");
    return self;
}

pub fn endAtOffset(self: *WireH, x: XRef, offset: f64) *WireH {
    self.state.constrainOffset(&self._x.end, x._x, offset, "wire endAtOffset");
    return self;
}

pub fn endAtPoint(self: *WireH, end: PointRef) *WireH {
    if (values.isUninitialized(self._y)) {
        _ = self.endAt(end.x());
        self.state.constrainEql(&self._y, end._y, "wire endAtPoint");
        return self;
    } else {
        if (!self._x.isEndConstrained()) {
            self.state.constrainMidpoint(&self._x.end, &self._x.begin, end._x, "wire endAtPoint midpoint");
        }
        return self.turn().turnAndEndAt(end);
    }
}

pub fn endAtMutablePoint(self: *WireH, end: PointRef) *WireH {
    _ = self.endAt(end.x());
    self.state.constrainEql(end._y, &self._y, "wire endAtMutablePoint");
    return self;
}

pub fn addMissingConstraints(self: *WireH) void {
    if (self.next) |next| {
        if (self._x.isEndConstrained()) {
            self.state.constrainEql(&next._x, &self._x.end, "wire segment connection");
        } else if (!values.isUninitialized(next._x)) {
            self.state.constrainEql(&self._x.end, &next._x, "wire segment connection");
        } else {
            self.state.constrainEql(&next._x, &self._x.end, "wire segment connection");
        }

        if (values.isUninitialized(self._y) and next._y.isBeginConstrained()) {
            self.state.constrainEql(&self._y, &next._y.begin, "wire segment connection");
        } else {
            self.state.constrainEql(&next._y.begin, &self._y, "wire segment connection");
        }

        next.addMissingConstraints();
    }

    if (values.isUninitialized(self._y)) {
        self._y = 0;
    }

    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    self._x.addMissingConstraints(self.state, 0, style.default_length);
}

pub fn debug(self: *WireH, writer: anytype) @TypeOf(writer).Error!void {
    try writer.print("WireH: {?s}\n   x: ", .{
        self.options.class,
    });
    try self._x.debug(writer);
    try writer.print("   y: {d}\n", .{
        self._y,
    });

    if (self.next) |next| {
        try writer.writeAll(" -> ");
        try next.debug(writer);
    }
}

const WireH = @This();
const WireV = @import("WireV.zig");
const PointRef = @import("PointRef.zig");
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const Span = @import("Span.zig");
const Label = @import("Label.zig");
const DrawingState = @import("DrawingState.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const std = @import("std");
