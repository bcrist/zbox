state: *DrawingState,
class: []const u8,
_x: f64 = values.uninitialized,

pub fn x(self: *SeparatorV) XRef {
    return .{
        .state = self.state,
        ._x = &self._x,
    };
}

pub fn label(self: *SeparatorV, y: YRef, alignment: Label.Alignment, baseline: Label.Baseline, text: []const u8) *SeparatorV {
    const style = &self.state.drawing.style;
    return self.labelWithClass(y, style.default_separator_label_class, alignment, baseline, text);
}
pub fn labelWithClass(self: *SeparatorV, y: YRef, class: []const u8, alignment: Label.Alignment, baseline: Label.Baseline, text: []const u8) *SeparatorV {
    const style = &self.state.drawing.style;
    const item = self.state.createLabel(text, class, alignment, baseline, -90);
    switch (baseline) {
        .normal => self.state.constrainOffset(&item._x, &self._x, -style.separator_label_padding_y, "separator label x"),
        .middle => self.state.constrainEql(&item._x, &self._x, "separator label x"),
        .hanging => self.state.constrainOffset(&item._x, &self._x, style.separator_label_padding_y, "separator label x"),
    }
    switch (alignment) {
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
