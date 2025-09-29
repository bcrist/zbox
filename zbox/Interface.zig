// TODO consider alternative names for this struct that are more descriptive

state: *Drawing_State,
contents: std.ArrayListUnmanaged(*f64) = .{},
spacing: f64 = values.uninitialized,
span: Span = .{},

pub fn push(self: *Interface) *f64 {
    const item = self.state.create_value(values.uninitialized, "", null);
    self.contents.append(self.state.gpa, item) catch @panic("OOM");
    return item;
}

pub fn flip(self: *Interface) void {
    const items = self.contents.items;
    for (0..items.len/2) |i| {
        const j = items.len - i - 1;
        const temp = items[i];
        items[i] = items[j];
        items[j] = temp;
    }
}

pub fn add_missing_constraints(self: *Interface) void {
    var spaces: usize = 0;
    for (0.., self.contents.items) |i, item| {
        self.state.add_debug_value_name(item, self.state.print("[{d}]", .{ i }), self);

        if (values.is_uninitialized(item.*)) {
            spaces += 1;
        }
    }
    if (spaces > 0) spaces -= 1;

    const spaces_f64: f64 = @floatFromInt(spaces);

    if (values.is_uninitialized(self.spacing)) {
        const divisor: f64 = if (spaces == 0) 1 else spaces_f64;
        self.state.constrain_scale(&self.spacing, &self.span.delta, 1 / divisor, "interface spacing from span delta");
    } else {
        self.state.constrain_scale(&self.span.delta, &self.spacing, spaces_f64, "interface span delta from spacing");

        // Ensure that delta won't be clobbered by add_missing_constraints below.
        if (!values.is_uninitialized(self.span.mid)) {
            self.span.begin = values.uninitialized;
            self.span.end = values.uninitialized;
        } else if (!values.is_uninitialized(self.span.begin)) {
            self.span.mid = values.uninitialized;
            self.span.end = values.uninitialized;
        } else if (!values.is_uninitialized(self.span.end)) {
            self.span.begin = values.uninitialized;
            self.span.mid = values.uninitialized;
        }
    }

    var i: f64 = 0;
    for (self.contents.items) |ptr| {
        if (values.is_uninitialized(ptr.*)) {
            self.state.constrain_scaled_offset(ptr, &self.span.begin, &self.spacing, i, "interface item from span begin/spacing");
            i += 1;
        }
    }

    self.span.add_missing_constraints(self.state, 0, self.state.drawing.style.default_interface_spacing * spaces_f64);
}

pub fn format(self: *Interface, writer: *std.io.Writer) error{WriteFailed}!void {
    try writer.print("n: {}   spacing: {d}\n", .{ self.contents.items.len, self.spacing });
    try writer.writeAll("      span:  ");
    try self.span.format(writer);
}

pub fn set_debug_name(self: *Interface, debug_name: []const u8, parent: ?*const anyopaque) void {
    self.state.add_debug_value_name(self, debug_name, parent);
    self.state.add_debug_value_name(&self.spacing, "spacing", self);
    self.span.set_debug_name(self.state, "span", self);
}

const Interface = @This();
const Span = @import("Span.zig");
const Drawing_State = @import("Drawing_State.zig");
const values = @import("values.zig");
const std = @import("std");
