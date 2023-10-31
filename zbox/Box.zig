state: *DrawingState,
class: []const u8,
_x: Span = .{},
_y: Span = .{},
_l: ?*Interface = null,
_r: ?*Interface = null,
_t: ?*Interface = null,
_b: ?*Interface = null,

pub fn left(self: *Box) XRef {
    return .{
        .state = self.state,
        .mut = true,
        ._x = &self._x.begin,
    };
}
pub fn right(self: *Box) XRef {
    return .{
        .state = self.state,
        .mut = true,
        ._x = &self._x.end,
    };
}
pub fn top(self: *Box) YRef {
    return .{
        .state = self.state,
        .mut = true,
        ._y = &self._y.begin,
    };
}
pub fn bottom(self: *Box) YRef {
    return .{
        .state = self.state,
        .mut = true,
        ._y = &self._y.end,
    };
}

pub fn topLeft(self: *Box) PointRef {
    return .{
        .state = self.state,
        .mut_x = true,
        .mut_y = true,
        ._x = &self._x.begin,
        ._y = &self._y.begin,
    };
}
pub fn topCenter(self: *Box) PointRef {
    return .{
        .state = self.state,
        .mut_x = true,
        .mut_y = true,
        ._x = &self._x.mid,
        ._y = &self._y.begin,
    };
}
pub fn topRight(self: *Box) PointRef {
    return .{
        .state = self.state,
        .mut_x = true,
        .mut_y = true,
        ._x = &self._x.end,
        ._y = &self._y.begin,
    };
}
pub fn middleLeft(self: *Box) PointRef {
    return .{
        .state = self.state,
        .mut_x = true,
        .mut_y = true,
        ._x = &self._x.begin,
        ._y = &self._y.mid,
    };
}
pub fn middleCenter(self: *Box) PointRef {
    return .{
        .state = self.state,
        .mut_x = true,
        .mut_y = true,
        ._x = &self._x.mid,
        ._y = &self._y.mid,
    };
}
pub fn middleRight(self: *Box) PointRef {
    return .{
        .state = self.state,
        .mut_x = true,
        .mut_y = true,
        ._x = &self._x.end,
        ._y = &self._y.mid,
    };
}
pub fn bottomLeft(self: *Box) PointRef {
    return .{
        .state = self.state,
        .mut_x = true,
        .mut_y = true,
        ._x = &self._x.begin,
        ._y = &self._y.end,
    };
}
pub fn bottomCenter(self: *Box) PointRef {
    return .{
        .state = self.state,
        .mut_x = true,
        .mut_y = true,
        ._x = &self._x.mid,
        ._y = &self._y.end,
    };
}
pub fn bottomRight(self: *Box) PointRef {
    return .{
        .state = self.state,
        .mut_x = true,
        .mut_y = true,
        ._x = &self._x.end,
        ._y = &self._y.end,
    };
}

pub fn width(self: *Box, w: f64) *Box {
    self.state.removeConstraint(&self._x.delta);
    self._x.delta = w;
    return self;
}
pub fn matchWidthOf(self: *Box, other: *const Box) *Box {
    self.state.constrain(&self._x.delta, .{ .copy = &other._x.delta });
    return self;
}

pub fn height(self: *Box, h: f64) *Box {
    self.state.removeConstraint(&self._y.delta);
    self._y.delta = h;
    return self;
}
pub fn matchHeightOf(self: *Box, other: *const Box) *Box {
    self.state.constrain(&self._y.delta, .{ .copy = &other._y.delta });
    return self;
}

pub fn size(self: *Box, w: f64, h: f64) *Box {
    self.state.removeConstraint(&self._x.delta);
    self.state.removeConstraint(&self._y.delta);
    self._x.delta = w;
    self._y.delta = h;
    return self;
}
pub fn matchSizeOf(self: *Box, other: *const Box) *Box {
    self.state.constrain(&self._x.delta, .{ .copy = &other._x.delta });
    self.state.constrain(&self._y.delta, .{ .copy = &other._y.delta });
    return self;
}

pub fn label(self: *Box, text: []const u8) *Box {
    return self.labelWithClass(self.state.drawing.style.default_box_label_class, text);
}
pub fn labelWithClass(self: *Box, class: []const u8, text: []const u8) *Box {
    const item = self.state.createLabel(text, class, .center, .middle, 0);
    self.constrainLabelX(.center, &item._x);
    self.state.constrain(&item._y, .{ .copy = &self._y.mid }, "box label y from span mid");
    return self;
}

pub fn topLabel(self: *Box, alignment: Label.Alignment, text: []const u8) *Box {
    return self.topLabelWithClass(self.state.drawing.style.default_box_label_class, alignment, text);
}
pub fn topLabelWithClass(self: *Box, class: []const u8, alignment: Label.Alignment, text: []const u8) *Box {
    const item = self.state.createLabel(text, class, alignment, .hanging, 0);
    self.constrainLabelX(alignment, &item._x);
    self.state.constrain(&item._y, .{ .offset_and_scale = .{
        .src = &self._y.begin,
        .offset = self.state.drawing.style.box_padding_y,
        .scale = 1,
    }}, "box label y from span begin");
    return self;
}

pub fn bottomLabel(self: *Box, alignment: Label.Alignment, text: []const u8) *Box {
    return self.bottomLabelWithClass(self.state.drawing.style.default_box_label_class, alignment, text);
}
pub fn bottomLabelWithClass(self: *Box, class: []const u8, alignment: Label.Alignment, text: []const u8) *Box {
    const item = self.state.createLabel(text, class, alignment, .normal, 0);
    self.constrainLabelX(alignment, &item._x);
    self.state.constrain(&item._y, .{ .offset_and_scale = .{
        .src = &self._y.end,
        .offset = -self.state.drawing.style.box_padding_y,
        .scale = 1,
    }}, "box label y from span end");
    return self;
}
fn constrainLabelX(self: *Box, alignment: Label.Alignment, label_x: *f64) void {
    switch (alignment) {
        .left => self.state.constrain(label_x, .{ .offset_and_scale = .{
            .src = &self._x.begin,
            .offset = self.state.drawing.style.box_padding_x,
            .scale = 1,
        }}, "box label x from span begin"),
        .center => self.state.constrain(label_x, .{ .copy = &self._x.mid }, "box label x from span mid"),
        .right => self.state.constrain(label_x, .{ .offset_and_scale = .{
            .src = &self._x.end,
            .offset = -self.state.drawing.style.box_padding_x,
            .scale = 1,
        }}, "box label x from span end"),
    }
}

pub fn leftSide(self: *Box, text: []const u8) PointRef {
    return self.leftSideWithClass(self.state.drawing.style.default_interface_label_class, text);
}
pub fn leftSideWithClass(self: *Box, class: []const u8, text: []const u8) PointRef {
    const y = self.getLeftInterface().push();
    if (text.len > 0) {
        const item = self.state.createLabel(text, class, .left, .middle, 0);
        self.constrainLabelX(.left, &item._x);
        self.state.constrain(&item._y, .{ .copy = y }, "interface label y from interface y");
    }
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = y,
        .mut_x = false,
        .mut_y = false,
    };
}

pub fn rightSide(self: *Box, text: []const u8) PointRef {
    return self.rightSideWithClass(self.state.drawing.style.default_interface_label_class, text);
}
pub fn rightSideWithClass(self: *Box, class: []const u8, text: []const u8) PointRef {
    const y = self.getRightInterface().push();
    if (text.len > 0) {
        const item = self.state.createLabel(text, class, .right, .middle, 0);
        self.constrainLabelX(.right, &item._x);
        self.state.constrain(&item._y, .{ .copy = y }, "interface label y from interface y");
    }
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = y,
        .mut_x = false,
        .mut_y = false,
    };
}

pub fn topSide(self: *Box, text: []const u8) PointRef {
    return self.topSideWithClass(self.state.drawing.style.default_interface_label_class, text);
}
pub fn topSideWithClass(self: *Box, class: []const u8, text: []const u8) PointRef {
    const x = self.getTopInterface().push();
    if (text.len > 0) {
        const item = self.state.createLabel(text, class, .right, .middle, -90);
        self.state.constrain(&item._x, .{ .copy = x }, "interface label x from interface x");
        self.state.constrain(&item._y, .{ .offset_and_scale = .{
            .src = &self._y.begin,
            .offset = self.state.drawing.style.box_padding_x, // since we're rotated we use the x padding in the y direction
            .scale = 1,
        }}, "interface label y from box y span begin");
    }
    return .{
        .state = self.state,
        ._x = x,
        ._y = &self._y.begin,
        .mut_x = false,
        .mut_y = false,
    };
}

pub fn bottomSide(self: *Box, text: []const u8) PointRef {
    return self.bottomSideWithClass(self.state.drawing.style.default_interface_label_class, text);
}
pub fn bottomSideWithClass(self: *Box, class: []const u8, text: []const u8) PointRef {
    const x = self.getBottomInterface().push();
    if (text.len > 0) {
        const item = self.state.createLabel(text, class, .left, .middle, -90);
        self.state.constrain(&item._x, .{ .copy = x }, "interface label x from interface x");
        self.state.constrain(&item._y, .{ .offset_and_scale = .{
            .src = &self._y.end,
            .offset = -self.state.drawing.style.box_padding_x, // since we're rotated we use the x padding in the y direction
            .scale = 1,
        }}, "interface label y from box y span end");
    }
    return .{
        .state = self.state,
        ._x = x,
        ._y = &self._y.end,
        .mut_x = false,
        .mut_y = false,
    };
}

pub fn getLeftInterface(self: *Box) *Interface {
    if (self._l) |interface| return interface;
    const interface = self.state.createInterface();
    self._l = interface;
    return interface;
}

pub fn getRightInterface(self: *Box) *Interface {
    if (self._r) |interface| return interface;
    const interface = self.state.createInterface();
    self._r = interface;
    return interface;
}

pub fn getTopInterface(self: *Box) *Interface {
    if (self._t) |interface| return interface;
    const interface = self.state.createInterface();
    self._t = interface;
    return interface;
}

pub fn getBottomInterface(self: *Box) *Interface {
    if (self._b) |interface| return interface;
    const interface = self.state.createInterface();
    self._b = interface;
    return interface;
}

pub fn addMissingConstraints(self: *Box) void {
    if (self._l) |interface| self.addMissingInterfaceConstraints(interface, &self._y.mid);
    if (self._r) |interface| self.addMissingInterfaceConstraints(interface, &self._y.mid);
    if (self._t) |interface| self.addMissingInterfaceConstraints(interface, &self._x.mid);
    if (self._b) |interface| self.addMissingInterfaceConstraints(interface, &self._x.mid);
    self._x.addMissingConstraints(self.state, 0, self.state.drawing.style.default_box_width);
    self._y.addMissingConstraints(self.state, 0, self.state.drawing.style.default_box_height);
}

fn addMissingInterfaceConstraints(self: *Box, interface: *Interface, default_mid: *const f64) void {
    if (values.isUninitialized(interface.span.begin) and values.isUninitialized(interface.span.mid) and values.isUninitialized(interface.span.end)) {
        self.state.constrain(&interface.span.mid, .{ .copy = default_mid }, "interface span mid matching box mid");
    }
    interface.addMissingConstraints();
}

pub fn debug(self: *Box, writer: anytype) !void {
    try writer.print("Box: {s}\n", .{ self.class });
    try writer.writeAll("   x: ");
    try self._x.debug(writer);
    try writer.writeAll("   y: ");
    try self._y.debug(writer);

    if (self._l) |interface| {
        try writer.writeAll("   l: ");
        try interface.debug(writer);
    }
    if (self._r) |interface| {
        try writer.writeAll("   r: ");
        try interface.debug(writer);
    }
    if (self._t) |interface| {
        try writer.writeAll("   t: ");
        try interface.debug(writer);
    }
    if (self._b) |interface| {
        try writer.writeAll("   b: ");
        try interface.debug(writer);
    }
}

const Box = @This();
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const PointRef = @import("PointRef.zig");
const Label = @import("Label.zig");
const Interface = @import("Interface.zig");
const Span = @import("Span.zig");
const DrawingState = @import("DrawingState.zig");
const values = @import("values.zig");
const std = @import("std");
