state: *Drawing_State,
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

pub fn left(self: *Box) X_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
    };
}
pub fn right(self: *Box) X_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.end,
    };
}
pub fn top(self: *Box) Y_Ref {
    return .{
        .state = self.state,
        ._y = &self._y.begin,
    };
}
pub fn bottom(self: *Box) Y_Ref {
    return .{
        .state = self.state,
        ._y = &self._y.end,
    };
}

pub fn x(self: *Box) X_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
    };
}
pub fn y(self: *Box) Y_Ref {
    return .{
        .state = self.state,
        ._y = &self._y.mid,
    };
}

pub fn top_left(self: *Box) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = &self._y.begin,
    };
}
pub fn top_center(self: *Box) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
        ._y = &self._y.begin,
    };
}
pub fn top_right(self: *Box) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = &self._y.begin,
    };
}
pub fn middle_left(self: *Box) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = &self._y.mid,
    };
}
pub fn middle_center(self: *Box) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
        ._y = &self._y.mid,
    };
}
pub fn middle_right(self: *Box) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = &self._y.mid,
    };
}
pub fn bottom_left(self: *Box) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = &self._y.end,
    };
}
pub fn bottom_center(self: *Box) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.mid,
        ._y = &self._y.end,
    };
}
pub fn bottom_right(self: *Box) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = &self._y.end,
    };
}

pub fn width(self: *Box, w: f64) *Box {
    self.state.remove_constraint(&self._x.delta);
    self._x.delta = w;
    return self;
}
pub fn match_width_of(self: *Box, other: *const Box) *Box {
    self.state.constrain_eql(&self._x.delta, &other._x.delta, "box width");
    return self;
}

pub fn height(self: *Box, h: f64) *Box {
    self.state.remove_constraint(&self._y.delta);
    self._y.delta = h;
    return self;
}
pub fn match_height_of(self: *Box, other: *const Box) *Box {
    self.state.constrain_eql(&self._y.delta, &other._y.delta, "box height");
    return self;
}

pub fn size(self: *Box, w: f64, h: f64) *Box {
    self.state.remove_constraint(&self._x.delta);
    self.state.remove_constraint(&self._y.delta);
    self._x.delta = w;
    self._y.delta = h;
    return self;
}
pub fn match_size_of(self: *Box, other: *const Box) *Box {
    self.state.constrain_eql(&self._x.delta, &other._x.delta, "box width");
    self.state.constrain_eql(&self._y.delta, &other._y.delta, "box height");
    return self;
}

pub fn top_label(self: *Box, alignment: Label.Alignment, text: []const u8) *Box {
    return self.top_label_with_class("", alignment, text);
}
pub fn top_label_with_class(self: *Box, extra_class: []const u8, alignment: Label.Alignment, text: []const u8) *Box {
    const item = self.state.create_label(text, .{
        .class = extra_class,
        ._class1 = @tagName(self.options.shape),
        ._class2 = "box-label top",
        .alignment = alignment,
        .baseline = .hanging,
    });
    self.constrain_label_x(alignment, &item._x);
    self.state.constrain_offset(&item._y, &self._y.begin, self.state.drawing.style.box_padding_y, "box label y from span begin");
    return self;
}

pub fn bottom_label(self: *Box, alignment: Label.Alignment, text: []const u8) *Box {
    return self.bottom_label_with_class("", alignment, text);
}
pub fn bottom_label_with_class(self: *Box, extra_class: []const u8, alignment: Label.Alignment, text: []const u8) *Box {
    const item = self.state.create_label(text, .{
        .class = extra_class,
        ._class1 = @tagName(self.options.shape),
        ._class2 = "box-label bottom",
        .alignment = alignment,
        .baseline = .normal,
    });
    self.constrain_label_x(alignment, &item._x);
    self.state.constrain_offset(&item._y, &self._y.end, -self.state.drawing.style.box_padding_y, "box label y from span end");
    return self;
}
fn constrain_label_x(self: *Box, alignment: Label.Alignment, label_x: *f64) void {
    switch (alignment) {
        .left => self.state.constrain_offset(label_x, &self._x.begin, self.state.drawing.style.box_padding_x, "box label x from span begin"),
        .center => self.state.constrain_eql(label_x, &self._x.mid, "box label x from span mid"),
        .right => self.state.constrain_offset(label_x, &self._x.end, -self.state.drawing.style.box_padding_x, "box label x from span end"),
    }
}

pub fn left_side(self: *Box, text: []const u8) Point_Ref {
    return self.left_side_with_class("", text);
}
pub fn left_side_with_class(self: *Box, extra_class: []const u8, text: []const u8) Point_Ref {
    const iy = self.get_left_interface().push();
    if (text.len > 0) {
        const item = self.state.create_label(text, .{
            .class = extra_class,
            ._class1 = @tagName(self.options.shape),
            ._class2 = "box-label interface left",
            .alignment = .left,
            .baseline = .middle,
        });
        self.constrain_label_x(.left, &item._x);
        self.state.constrain_eql(&item._y, iy, "interface label y from interface y");
    }
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = iy,
    };
}
pub fn get_left_side(self: *Box, index: usize) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.begin,
        ._y = self.get_left_interface().contents.items[index],
    };
}

pub fn right_side(self: *Box, text: []const u8) Point_Ref {
    return self.right_side_with_class("", text);
}
pub fn right_side_with_class(self: *Box, extra_class: []const u8, text: []const u8) Point_Ref {
    const iy = self.get_right_interface().push();
    if (text.len > 0) {
        const item = self.state.create_label(text, .{
            .class = extra_class,
            ._class1 = @tagName(self.options.shape),
            ._class2 = "box-label interface right",
            .alignment = .right,
            .baseline = .middle,
        });
        self.constrain_label_x(.right, &item._x);
        self.state.constrain_eql(&item._y, iy, "interface label y from interface y");
    }
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = iy,
    };
}
pub fn get_right_side(self: *Box, index: usize) Point_Ref {
    return .{
        .state = self.state,
        ._x = &self._x.end,
        ._y = self.get_right_interface().contents.items[index],
    };
}

pub fn top_side(self: *Box, text: []const u8) Point_Ref {
    return self.top_side_with_class("", text);
}
pub fn top_side_with_class(self: *Box, extra_class: []const u8, text: []const u8) Point_Ref {
    const ix = self.get_top_interface().push();
    if (text.len > 0) {
        const item = self.state.create_label(text, .{
            .class = extra_class,
            ._class1 = @tagName(self.options.shape),
            ._class2 = "box-label interface top",
            .alignment = .right,
            .baseline = .middle,
            .angle = -90,
        });
        self.state.constrain_eql(&item._x, ix, "interface label x from interface x");
        // since we're rotated we use the x padding in the y direction:
        self.state.constrain_offset(&item._y, &self._y.begin, self.state.drawing.style.box_padding_x, "interface label y from box y span begin");
    }
    return .{
        .state = self.state,
        ._x = ix,
        ._y = &self._y.begin,
    };
}
pub fn get_top_side(self: *Box, index: usize) Point_Ref {
    return .{
        .state = self.state,
        ._x = self.get_top_interface().contents.items[index],
        ._y = &self._y.begin,
    };
}

pub fn bottom_side(self: *Box, text: []const u8) Point_Ref {
    return self.bottom_side_with_class("", text);
}
pub fn bottom_side_with_class(self: *Box, extra_class: []const u8, text: []const u8) Point_Ref {
    const ix = self.get_bottom_interface().push();
    if (text.len > 0) {
        const item = self.state.create_label(text, .{
            .class = extra_class,
            ._class1 = @tagName(self.options.shape),
            ._class2 = "box-label interface bottom",
            .alignment = .left,
            .baseline = .middle,
            .angle = -90,
        });
        self.state.constrain_eql(&item._x, ix, "interface label x from interface x");
        // since we're rotated we use the x padding in the y direction:
        self.state.constrain_offset(&item._y, &self._y.end, -self.state.drawing.style.box_padding_x, "interface label y from box y span end");
    }
    return .{
        .state = self.state,
        ._x = ix,
        ._y = &self._y.end,
    };
}
pub fn get_bottom_side(self: *Box, index: usize) Point_Ref {
    return .{
        .state = self.state,
        ._x = self.get_bottom_interface().contents.items[index],
        ._y = &self._y.begin,
    };
}

pub fn get_left_interface(self: *Box) *Interface {
    if (self._l) |interface| return interface;
    const interface = self.state.create_interface();
    self._l = interface;
    return interface;
}

pub fn get_right_interface(self: *Box) *Interface {
    if (self._r) |interface| return interface;
    const interface = self.state.create_interface();
    self._r = interface;
    return interface;
}

pub fn get_top_interface(self: *Box) *Interface {
    if (self._t) |interface| return interface;
    const interface = self.state.create_interface();
    self._t = interface;
    return interface;
}

pub fn get_bottom_interface(self: *Box) *Interface {
    if (self._b) |interface| return interface;
    const interface = self.state.create_interface();
    self._b = interface;
    return interface;
}

pub fn add_missing_constraints(self: *Box) void {
    if (self._l) |interface| self.add_missing_interface_constraints(interface, &self._y.mid);
    if (self._r) |interface| self.add_missing_interface_constraints(interface, &self._y.mid);
    if (self._t) |interface| self.add_missing_interface_constraints(interface, &self._x.mid);
    if (self._b) |interface| self.add_missing_interface_constraints(interface, &self._x.mid);

    if (self.options.shape == .mux or self.options.shape == .demux) {
        if (!self._x.is_delta_constrained()) {
            self.state.constrain_scale(&self._x.delta, &self._y.delta, 0.5, "mux/demux default width");
        }
    }

    self._x.add_missing_constraints(self.state, 0, switch (self.options.shape) {
        .block, .mux, .demux => 240,
        .small => 25,
    });
    self._y.add_missing_constraints(self.state, 0, switch (self.options.shape) {
        .block, .mux, .demux => 120,
        .small => 25,
    });
}

fn add_missing_interface_constraints(self: *Box, interface: *Interface, default_mid: *const f64) void {
    if (!interface.span.is_position_constrained()) {
        self.state.constrain_eql(&interface.span.mid, default_mid, "interface span mid matching box mid");
    }
    interface.add_missing_constraints();
}

pub fn debug(self: *Box, writer: *std.io.Writer) !void {
    try writer.print("Box ({t}): {s}\n", .{
        self.options.shape,
        self.options.class,
    });
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
const X_Ref = @import("X_Ref.zig");
const Y_Ref = @import("Y_Ref.zig");
const Point_Ref = @import("Point_Ref.zig");
const Label = @import("Label.zig");
const Interface = @import("Interface.zig");
const Span = @import("Span.zig");
const Drawing_State = @import("Drawing_State.zig");
const values = @import("values.zig");
const std = @import("std");
