// TODO consider alternative names for this struct that are more descriptive

state: *DrawingState,
contents: std.ArrayListUnmanaged(*f64) = .{},
spacing: f64 = values.uninitialized,
span: Span = .{},

pub fn push(self: *Interface) *f64 {
    const item = self.state.createValue(values.uninitialized);
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

pub fn addMissingConstraints(self: *Interface) void {
    var spaces: usize = 0;
    for (self.contents.items) |item| {
        if (values.isUninitialized(item.*)) {
            spaces += 1;
        }
    }
    if (spaces > 0) spaces -= 1;

    const spaces_f64: f64 = @floatFromInt(spaces);

    if (values.isUninitialized(self.spacing)) {
        const divisor: f64 = if (spaces == 0) 1 else spaces_f64;
        self.state.constrainScale(&self.spacing, &self.span.delta, 1 / divisor, "interface spacing from span delta");
    } else {
        self.state.constrainScale(&self.span.delta, &self.spacing, spaces_f64, "interface span delta from spacing");

        // Ensure that delta won't be clobbered by addMissingConstraints below.
        if (!values.isUninitialized(self.span.mid)) {
            self.span.begin = values.uninitialized;
            self.span.end = values.uninitialized;
        } else if (!values.isUninitialized(self.span.begin)) {
            self.span.mid = values.uninitialized;
            self.span.end = values.uninitialized;
        } else if (!values.isUninitialized(self.span.end)) {
            self.span.begin = values.uninitialized;
            self.span.mid = values.uninitialized;
        }
    }

    var i: f64 = 0;
    for (self.contents.items) |ptr| {
        if (values.isUninitialized(ptr.*)) {
            self.state.constrainScaledOffset(ptr, &self.span.begin, &self.spacing, i, "interface item from span begin/spacing");
            i += 1;
        }
    }

    self.span.addMissingConstraints(self.state, 0, self.state.drawing.style.default_interface_spacing * spaces_f64);
}

pub fn debug(self: *Interface, writer: anytype) !void {
    try writer.print("n: {}   spacing: {d}\n", .{ self.contents.items.len, self.spacing });
    try writer.writeAll("      span:  ");
    try self.span.debug(writer);
}

const Interface = @This();
const Span = @import("Span.zig");
const DrawingState = @import("DrawingState.zig");
const values = @import("values.zig");
const std = @import("std");
