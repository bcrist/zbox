state: *DrawingState,
class: []const u8 = "",
_y: f64 = values.uninitialized,

pub fn y(self: *SeparatorH) YRef {
    return .{
        .state = self.state,
        ._y = &self._y,
    };
}

pub fn labelWithClass(self: *SeparatorH, x: XRef, text: []const u8, options: Label.Options) *SeparatorH {
    const style = &self.state.drawing.style;
    const options_mut = options;
    options_mut.angle = 0;
    options_mut._class1 = self.class;
    options_mut._class2 = "sep-label";
    const item = self.state.createLabel(text, options_mut);
    switch (options_mut.baseline) {
        .normal => self.state.constrainOffset(&item._y, &self._y, -style.separator_label_padding_y, "separator label y"),
        .middle => self.state.constrainEql(&item._y, &self._y, "separator label y"),
        .hanging => self.state.constrainOffset(&item._y, &self._y, style.separator_label_padding_y, "separator label y"),
    }
    switch (options_mut.alignment) {
        .left => self.state.constrainOffset(&item._x, x._x, style.separator_label_padding_x, "separator label x"),
        .center => self.state.constrainEql(&item._x, x._x, "separator label x"),
        .right => self.state.constrainOffset(&item._x, x._x, -style.separator_label_padding_x, "separator label x"),
    }
    return self;
}

const SeparatorH = @This();
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const Label = @import("Label.zig");
const DrawingState = @import("DrawingState.zig");
const values = @import("values.zig");
const std = @import("std");
