state: *DrawingState,
options: Options,
_x: Span = .{},
_y: Span = .{},
_l: ?*Interface = null,
_r: ?*Interface = null,
_t: ?*Interface = null,
_b: ?*Interface = null,

pub const Options = struct {
    shape: Shape = .block,
    class: []const u8 = "",
    label: []const u8 = "",
    label_class: []const u8 = "",
};

pub const Shape = enum {
    block,
    small,
    mux,
    demux,
};

pub fn left(self: *Box) XRef {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
    };
}
pub fn right(self: *Box) XRef {
    return .{
        .state = self.state,
        ._x = &self._x.end,
    };
}
pub fn top(self: *Box) YRef {
    return .{
        .state = self.state,
        ._y = &self._y.begin,
    };
}
pub fn bottom(self: *Box) YRef {
    return .{
        .state = self.state,
        ._y = &self._y.end,
    };
}

pub fn x(self: *Box) XRef {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
    };
}
pub fn y(self: *Box) YRef {
    return .{
        .state = self.state,
        ._y = &self._y.mid,
    };
}

pub fn topLeft(self: *Box) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = &self._y.begin,
    };
}
pub fn topCenter(self: *Box) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
        ._y = &self._y.begin,
    };
}
pub fn topRight(self: *Box) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = &self._y.begin,
    };
}
pub fn middleLeft(self: *Box) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = &self._y.mid,
    };
}
pub fn middleCenter(self: *Box) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
        ._y = &self._y.mid,
    };
}
pub fn middleRight(self: *Box) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = &self._y.mid,
    };
}
pub fn bottomLeft(self: *Box) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = &self._y.end,
    };
}
pub fn bottomCenter(self: *Box) PointRef {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
        ._y = &self._y.end,
    };
}
pub fn bottomRight(self: *Box) PointRef {
    return .{
        .state = self.state,
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
    self.state.constrainEql(&self._x.delta, &other._x.delta, "box width");
    return self;
}

pub fn height(self: *Box, h: f64) *Box {
    self.state.removeConstraint(&self._y.delta);
    self._y.delta = h;
    return self;
}
pub fn matchHeightOf(self: *Box, other: *const Box) *Box {
    self.state.constrainEql(&self._y.delta, &other._y.delta, "box height");
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
    self.state.constrainEql(&self._x.delta, &other._x.delta, "box width");
    self.state.constrainEql(&self._y.delta, &other._y.delta, "box height");
    return self;
}

pub fn topLabel(self: *Box, alignment: Label.Alignment, text: []const u8) *Box {
    return self.topLabelWithClass("", alignment, text);
}
pub fn topLabelWithClass(self: *Box, extra_class: []const u8, alignment: Label.Alignment, text: []const u8) *Box {
    const item = self.state.createLabel(text, .{
        .class = extra_class,
        ._class1 = @tagName(self.options.shape),
        ._class2 = "box-label top",
        .alignment = alignment,
        .baseline = .hanging,
    });
    self.constrainLabelX(alignment, &item._x);
    self.state.constrainOffset(&item._y, &self._y.begin, self.state.drawing.style.box_padding_y, "box label y from span begin");
    return self;
}

pub fn bottomLabel(self: *Box, alignment: Label.Alignment, text: []const u8) *Box {
    return self.bottomLabelWithClass("", alignment, text);
}
pub fn bottomLabelWithClass(self: *Box, extra_class: []const u8, alignment: Label.Alignment, text: []const u8) *Box {
    const item = self.state.createLabel(text, .{
        .class = extra_class,
        ._class1 = @tagName(self.options.shape),
        ._class2 = "box-label bottom",
        .alignment = alignment,
        .baseline = .normal,
    });
    self.constrainLabelX(alignment, &item._x);
    self.state.constrainOffset(&item._y, &self._y.end, -self.state.drawing.style.box_padding_y, "box label y from span end");
    return self;
}
fn constrainLabelX(self: *Box, alignment: Label.Alignment, label_x: *f64) void {
    switch (alignment) {
        .left => self.state.constrainOffset(label_x, &self._x.begin, self.state.drawing.style.box_padding_x, "box label x from span begin"),
        .center => self.state.constrainEql(label_x, &self._x.mid, "box label x from span mid"),
        .right => self.state.constrainOffset(label_x, &self._x.end, -self.state.drawing.style.box_padding_x, "box label x from span end"),
    }
}

pub fn leftSide(self: *Box, text: []const u8) PointRef {
    return self.leftSideWithClass("", text);
}
pub fn leftSideWithClass(self: *Box, extra_class: []const u8, text: []const u8) PointRef {
    const iy = self.getLeftInterface().push();
    if (text.len > 0) {
        const item = self.state.createLabel(text, .{
            .class = extra_class,
            ._class1 = @tagName(self.options.shape),
            ._class2 = "box-label interface left",
            .alignment = .left,
            .baseline = .middle,
        });
        self.constrainLabelX(.left, &item._x);
        self.state.constrainEql(&item._y, iy, "interface label y from interface y");
    }
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = iy,
    };
}

pub fn rightSide(self: *Box, text: []const u8) PointRef {
    return self.rightSideWithClass("", text);
}
pub fn rightSideWithClass(self: *Box, extra_class: []const u8, text: []const u8) PointRef {
    const iy = self.getRightInterface().push();
    if (text.len > 0) {
        const item = self.state.createLabel(text, .{
            .class = extra_class,
            ._class1 = @tagName(self.options.shape),
            ._class2 = "box-label interface right",
            .alignment = .right,
            .baseline = .middle,
        });
        self.constrainLabelX(.right, &item._x);
        self.state.constrainEql(&item._y, iy, "interface label y from interface y");
    }
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = iy,
    };
}

pub fn topSide(self: *Box, text: []const u8) PointRef {
    return self.topSideWithClass("", text);
}
pub fn topSideWithClass(self: *Box, extra_class: []const u8, text: []const u8) PointRef {
    const ix = self.getTopInterface().push();
    if (text.len > 0) {
        const item = self.state.createLabel(text, .{
            .class = extra_class,
            ._class1 = @tagName(self.options.shape),
            ._class2 = "box-label interface top",
            .alignment = .right,
            .baseline = .middle,
            .angle = -90,
        });
        self.state.constrainEql(&item._x, ix, "interface label x from interface x");
        // since we're rotated we use the x padding in the y direction:
        self.state.constrainOffset(&item._y, &self._y.begin, self.state.drawing.style.box_padding_x, "interface label y from box y span begin");
    }
    return .{
        .state = self.state,
        ._x = ix,
        ._y = &self._y.begin,
    };
}

pub fn bottomSide(self: *Box, text: []const u8) PointRef {
    return self.bottomSideWithClass("", text);
}
pub fn bottomSideWithClass(self: *Box, extra_class: []const u8, text: []const u8) PointRef {
    const ix = self.getBottomInterface().push();
    if (text.len > 0) {
        const item = self.state.createLabel(text, .{
            .class = extra_class,
            ._class1 = @tagName(self.options.shape),
            ._class2 = "box-label interface bottom",
            .alignment = .left,
            .baseline = .middle,
            .angle = -90,
        });
        self.state.constrainEql(&item._x, ix, "interface label x from interface x");
        // since we're rotated we use the x padding in the y direction:
        self.state.constrainOffset(&item._y, &self._y.end, -self.state.drawing.style.box_padding_x, "interface label y from box y span end");
    }
    return .{
        .state = self.state,
        ._x = ix,
        ._y = &self._y.end,
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

    if (self.options.shape == .mux or self.options.shape == .demux) {
        if (!self._x.isDeltaConstrained()) {
            self.state.constrainScale(&self._x.delta, &self._y.delta, 0.5, "mux/demux default width");
        }
    }

    self._x.addMissingConstraints(self.state, 0, switch (self.options.shape) {
        .block, .mux, .demux => 240,
        .small => 30,
    });
    self._y.addMissingConstraints(self.state, 0, switch (self.options.shape) {
        .block, .mux, .demux => 120,
        .small => 30,
    });
}

fn addMissingInterfaceConstraints(self: *Box, interface: *Interface, default_mid: *const f64) void {
    if (!interface.span.isPositionConstrained()) {
        self.state.constrainEql(&interface.span.mid, default_mid, "interface span mid matching box mid");
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
