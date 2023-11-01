state: *DrawingState,
options: wires.Options,
next: ?*WireH = null,
bit_mark: ?f64 = null,
_x: f64 = values.uninitialized,
_y: Span = .{},

pub fn x(self: *WireH) YRef {
    return .{
        .state = self.state,
        ._x = &self._x,
    };
}

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
    self.state.constrainEql(&self._y.delta, &other._y.delta, "wire matchLengthOf");
    return self;
}

pub fn bitMark(self: *WireV) *WireV {
    self.bit_mark = 0.5;
    return self;
}

pub fn bitMarkAt(self: *WireV, f: f64) *WireV {
    self.bit_mark = f;
    return self;
}

pub fn labelLeft(self: *WireV, alignment: Label.Alignment, text: []const u8) *WireV {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    return self.labelLeftWithClass(style.default_label_class, alignment, text);
}
pub fn labelLeftWithClass(self: *WireV, class: []const u8, alignment: Label.Alignment, text: []const u8) *WireV {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    const item = self.state.createLabel(text, class, alignment, .normal, -90);
    self.state.constrainOffset(&item._x, &self._x, -style.label_padding_y, "wire label x");
    switch (alignment) {
        .right => self.state.constrainOffset(&item._y, &self._y.min, style.label_padding_x, "wire label y from min"),
        .center => self.state.constrainEql(&item._y, &self._y.mid, "wire label y from mid"),
        .left => self.state.constrainOffset(&item._y, &self._y.max, -style.label_padding_x, "wire label y from max"),
    }
    return self;
}

pub fn labelRight(self: *WireV, alignment: Label.Alignment, text: []const u8) *WireV {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    return self.labelRightWithClass(style.default_label_class, alignment, text);
}
pub fn labelRightWithClass(self: *WireV, class: []const u8, alignment: Label.Alignment, text: []const u8) *WireV {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    const item = self.state.createLabel(text, class, alignment, .hanging, -90);
    self.state.constrainOffset(&item._x, &self._x, style.label_padding_y, "wire label y");
    switch (alignment) {
        .right => self.state.constrainOffset(&item._y, &self._y.min, style.label_padding_x, "wire label y from min"),
        .center => self.state.constrainEql(&item._y, &self._y.mid, "wire label y from mid"),
        .left => self.state.constrainOffset(&item._y, &self._y.max, -style.label_padding_x, "wire label y from max"),
    }
    return self;
}

pub fn labelTop(self: *WireV, text: []const u8) *WireV {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    return self.labelTopWithClass(style.default_label_class, text);
}
pub fn labelTopWithClass(self: *WireV, class: []const u8, text: []const u8) *WireV {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    const item = self.state.createLabel(text, class, .right, .middle, 0);
    self.state.constrainEql(&item._y, &self._y, "wire label y");
    self.state.constrainOffset(&item._x, &self._x.min, -style.label_padding_cap, "wire label x from min");
    return self;
}

pub fn labelBottom(self: *WireV, text: []const u8) *WireV {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    return self.labelBottomWithClass(style.default_label_class, text);
}
pub fn labelBottomWithClass(self: *WireV, class: []const u8, text: []const u8) *WireV {
    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    const item = self.state.createLabel(text, class, .left, .middle, 0);
    self.state.constrainEql(&item._y, &self._y, "wire label y");
    self.state.constrainOffset(&item._x, &self._x.max, style.label_padding_cap, "wire label x from max");
    return self;
}

pub fn turn(self: *WireV) *WireH {
    if (self.next) |next| return next;
    return self.state.createWireH(self.options, self);
}

pub fn turnAt(self: *WireV, y: YRef) *WireH {
    return self.endAt(y).turn();
}

pub fn turnAtOffset(self: *WireV, y: YRef, offset: f64) *WireH {
    return self.endAtOffset(y, offset).turn();
}

pub fn turnAndEndAt(self: *WireV, end: PointRef) *WireH {
    return self.turnAt(end.y()).endAt(end.x());
}

pub fn endAt(self: *WireV, y: YRef) *WireV {
    self.state.constrainEql(&self._y.end, y._y, "wire endAt");
    return self;
}

pub fn endAtOffset(self: *WireV, y: YRef, offset: f64) *WireV {
    self.state.constrainOffset(&self._y.end, y._y, offset, "wire endAtOffset");
    return self;
}

pub fn endAtPoint(self: *WireV, end: PointRef) *WireV {
    if (values.isUninitialized(self._x)) {
        _ = self.endAt(end.y());
        self.state.constrainEql(&self._x, end._x, "wire endAtPoint");
        return self;
    } else {
        if (!self._y.isEndConstrained()) {
            self.state.constrainMidpoint(&self._y.end, &self._y.begin, end._y, "wire endAtPoint midpoint");
        }
        return self.turn().turnAndEndAt(end);
    }
}

pub fn endAtMutablePoint(self: *WireV, end: PointRef) *WireV {
    _ = self.endAt(end.y());
    self.state.constrainEql(end._x, &self._x, "wire endAtMutablePoint");
    return self;
}

pub fn addMissingConstraints(self: *WireV) void {
    if (self.next) |next| {
        if (self._y.isEndConstrained()) {
            self.state.constrainEql(&next._y, &self._y.end, "wire segment connection");
        } else if (!values.isUninitialized(next._y)) {
            self.state.constrainEql(&self._y.end, &next._y, "wire segment connection");
        } else {
            self.state.constrainEql(&next._y, &self._y.end, "wire segment connection");
        }

        if (values.isUninitialized(self._x) and next._x.isBeginConstrained()) {
            self.state.constrainEql(&self._x, &next._x.begin, "wire segment connection");
        } else {
            self.state.constrainEql(&next._x.begin, &self._x, "wire segment connection");
        }

        next.addMissingConstraints();
    }

    if (values.isUninitialized(self._x)) {
        self._x = 0;
    }

    const style = if (self.options.bits > 1) self.state.drawing.style.bus_style else self.state.drawing.style.wire_style;
    self._y.addMissingConstraints(self.state, 0, style.default_length);
}

pub fn debug(self: *WireV, writer: anytype) @TypeOf(writer).Error!void {
    try writer.print("WireV: {?s}\n   x: {d}\n   y: ", .{
        self.options.class,
        self._x,
    });
    try self._y.debug(writer);

    if (self.next) |next| {
        try writer.writeAll(" -> ");
        try next.debug(writer);
    }
}

const WireV = @This();
const WireH = @import("WireH.zig");
const PointRef = @import("PointRef.zig");
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const Span = @import("Span.zig");
const Label = @import("Label.zig");
const DrawingState = @import("DrawingState.zig");
const wires = @import("wires.zig");
const values = @import("values.zig");
const std = @import("std");
