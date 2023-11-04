state: *DrawingState,
class: []const u8 = "",
_x: f64 = values.uninitialized,

pub fn x(self: *SeparatorV) XRef {
    return .{
        .state = self.state,
        ._x = &self._x,
    };
}

pub fn label(self: *SeparatorV, y: YRef, text: []const u8, options: Label.Options) *SeparatorV {
    var options_mut = options;
    options_mut.angle = -90;
    options_mut._class1 = self.class;
    options_mut._class2 = "sep-label";
    const style = &self.state.drawing.style;
    const item = self.state.createLabel(text, options_mut);
    switch (options_mut.baseline) {
        .normal => self.state.constrainOffset(&item._x, &self._x, -style.separator_label_padding_y, "separator label x"),
        .middle => self.state.constrainEql(&item._x, &self._x, "separator label x"),
        .hanging => self.state.constrainOffset(&item._x, &self._x, style.separator_label_padding_y, "separator label x"),
    }
    switch (options_mut.alignment) {
        .left => self.state.constrainOffset(&item._y, y._y, style.separator_label_padding_x, "separator label y"),
        .center => self.state.constrainEql(&item._y, y._y, "separator label y"),
        .right => self.state.constrainOffset(&item._y, y._y, -style.separator_label_padding_x, "separator label y"),
    }
    return self;
}

const SeparatorV = @This();
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const Label = @import("Label.zig");
const DrawingState = @import("DrawingState.zig");
const values = @import("values.zig");
const std = @import("std");
