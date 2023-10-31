contents: std.ArrayListUnmanaged(*f64) = .{},
spacing: f64 = values.uninitialized,
span: Span = .{},

pub fn addMissingConstraints(self: *Interface, drawing: *Drawing) void {
    // TODO gracefully handle points in contents that aren't uninitalized
    // (take them out of the spacing calculations, etc.)
    // then they can be allowed to be mutable in XRefs/YRefs/PointRefs

    var spaces = self.contents.items.len;
    if (spaces > 0) spaces -= 1;

    const spaces_f64: f64 = @floatFromInt(spaces);

    if (!values.isUninitialized(self.spacing)) {
        drawing.constrain(&self.span.delta, .{ .offset_and_scale = .{
            .src = &self.spacing,
            .offset = 0,
            .scale = spaces_f64,
        }}, "interface span delta from spacing");

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
    } else {
        const divisor: f64 = if (spaces == 0) 1 else spaces_f64;
        drawing.constrain(&self.spacing, .{ .offset_and_scale = .{
            .src = &self.span.delta,
            .offset = 0,
            .scale = 1 / divisor,
        }}, "interface spacing from span delta");
    }

    for (0.., self.contents.items) |i, ptr| {
        const k: f64 = @floatFromInt(i);
        drawing.constrain(ptr, .{ .scaled_offset = .{
            .operands = .{ &self.span.begin, &self.spacing },
            .k = k,
        }}, "interface item from span begin/spacing");
    }

    self.span.addMissingConstraints(drawing, 0, drawing.style.default_interface_spacing * spaces_f64);
}

pub fn debug(self: *Interface, writer: anytype) !void {
    try writer.print("n: {}   spacing: {d}\n", .{ self.contents.items.len, self.spacing });
    try writer.writeAll("      span:  ");
    try self.span.debug(writer);
}

const Interface = @This();
const Span = @import("Span.zig");
const Drawing = @import("Drawing.zig");
const values = @import("values.zig");
const std = @import("std");
