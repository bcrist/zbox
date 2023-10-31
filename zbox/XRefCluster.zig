drawing: *Drawing,
interface: Interface = .{},

pub fn get(self: *XRefCluster, index: usize) XRef {
    return .{
        .drawing = self.drawing,
        ._x = self.interface.contents.items[index],
        .mut = false,
    };
}

pub fn add(self: *XRefCluster) XRef {
    const arena = self.drawing.arena.allocator();
    const item = arena.create(f64) catch @panic("OOM");
    item.* = values.uninitialized;
    self.interface.contents.append(self.drawing.gpa, item) catch @panic("OOM");
    return .{
        .drawing = self.drawing,
        ._x = item,
        .mut = false,
    };
}

const XRefCluster = @This();
const XRef = @import("XRef.zig");
const Interface = @import("Interface.zig");
const Drawing = @import("Drawing.zig");
const values = @import("values.zig");
const std = @import("std");
