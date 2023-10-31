drawing: *Drawing,
interface: Interface = .{},

pub fn get(self: *YRefCluster, index: usize) YRef {
    return .{
        .drawing = self.drawing,
        ._y = self.interface.contents.items[index],
        .mut = false,
    };
}

pub fn add(self: *YRefCluster) YRef {
    const arena = self.drawing.arena.allocator();
    const item = arena.create(f64) catch @panic("OOM");
    item.* = values.uninitialized;
    self.interface.contents.append(self.drawing.gpa, item) catch @panic("OOM");
    return .{
        .drawing = self.drawing,
        ._y = item,
        .mut = false,
    };
}

const YRefCluster = @This();
const YRef = @import("YRef.zig");
const Interface = @import("Interface.zig");
const Drawing = @import("Drawing.zig");
const values = @import("values.zig");
const std = @import("std");
