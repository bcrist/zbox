state: *DrawingState,
class: []const u8,
_y: f64 = values.uninitialized,

pub fn y(self: *SeparatorH) YRef {
    return .{
        .state = self.state,
        ._y = &self._y,
    };
}

pub fn label(self: *SeparatorH, x: XRef, alignment: Label.Alignment, baseline: Label.Baseline, text: []const u8) *SeparatorH {
    const style = &self.state.drawing.style;
    return self.labelWithClass(x, style.default_separator_label_class, alignment, baseline, text);
}
pub fn labelWithClass(self: *SeparatorH, x: XRef, class: []const u8, alignment: Label.Alignment, baseline: Label.Baseline, text: []const u8) *SeparatorH {
    const style = &self.state.drawing.style;
    const item = self.state.createLabel(text, class, alignment, baseline, 0);
    switch (baseline) {
        .normal => self.state.constrainOffset(&item._y, &self._y, -style.separator_label_padding_y, "separator label y"),
        .middle => self.state.constrainEql(&item._y, &self._y, "separator label y"),
        .hanging => self.state.constrainOffset(&item._y, &self._y, style.separator_label_padding_y, "separator label y"),
    }
    switch (alignment) {
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
