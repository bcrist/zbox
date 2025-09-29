state: *Drawing_State,
class: []const u8 = "",
_x: f64 = values.uninitialized,

pub fn x(self: *Separator_V) X_Ref {
    return .{
        .state = self.state,
        ._x = &self._x,
    };
}

pub fn label(self: *Separator_V, y: Y_Ref, text: []const u8, options: Label.Options) *Separator_V {
    var options_mut = options;
    options_mut.angle = -90;
    options_mut._class1 = self.class;
    options_mut._class2 = "sep-label";
    const style = &self.state.drawing.style;
    const item = self.state.create_label(text, options_mut, self);
    switch (options_mut.baseline) {
        .normal => self.state.constrain_offset(&item._x, &self._x, -style.separator_label_padding_y, "separator label x"),
        .middle => self.state.constrain_eql(&item._x, &self._x, "separator label x"),
        .hanging => self.state.constrain_offset(&item._x, &self._x, style.separator_label_padding_y, "separator label x"),
    }
    switch (options_mut.alignment) {
        .left => self.state.constrain_offset(&item._y, y._y, style.separator_label_padding_x, "separator label y"),
        .center => self.state.constrain_eql(&item._y, y._y, "separator label y"),
        .right => self.state.constrain_offset(&item._y, y._y, -style.separator_label_padding_x, "separator label y"),
    }
    return self;
}

pub fn set_debug_name(self: *Separator_V, debug_name: []const u8, parent: ?*const anyopaque) void {
    self.state.add_debug_value_name(self, debug_name, parent);
    self.state.add_debug_value_name(&self._x, "_x", self);
}

const Separator_V = @This();
const X_Ref = @import("X_Ref.zig");
const Y_Ref = @import("Y_Ref.zig");
const Label = @import("Label.zig");
const Drawing_State = @import("Drawing_State.zig");
const values = @import("values.zig");
const std = @import("std");
