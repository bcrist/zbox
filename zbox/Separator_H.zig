state: *Drawing_State,
class: []const u8 = "",
_y: f64 = values.uninitialized,

pub fn y(self: *Separator_H) Y_Ref {
    return .{
        .state = self.state,
        ._y = &self._y,
    };
}

pub fn label(self: *Separator_H, x: X_Ref, text: []const u8, options: Label.Options) *Separator_H {
    const style = &self.state.drawing.style;
    const options_mut = options;
    options_mut.angle = 0;
    options_mut._class1 = self.class;
    options_mut._class2 = "sep-label";
    const item = self.state.create_label(text, options_mut);
    switch (options_mut.baseline) {
        .normal => self.state.constrain_offset(&item._y, &self._y, -style.separator_label_padding_y, "separator label y"),
        .middle => self.state.constrain_eql(&item._y, &self._y, "separator label y"),
        .hanging => self.state.constrain_offset(&item._y, &self._y, style.separator_label_padding_y, "separator label y"),
    }
    switch (options_mut.alignment) {
        .left => self.state.constrain_offset(&item._x, x._x, style.separator_label_padding_x, "separator label x"),
        .center => self.state.constrain_eql(&item._x, x._x, "separator label x"),
        .right => self.state.constrain_offset(&item._x, x._x, -style.separator_label_padding_x, "separator label x"),
    }
    return self;
}

const Separator_H = @This();
const X_Ref = @import("X_Ref.zig");
const Y_Ref = @import("Y_Ref.zig");
const Label = @import("Label.zig");
const Drawing_State = @import("Drawing_State.zig");
const values = @import("values.zig");
const std = @import("std");
