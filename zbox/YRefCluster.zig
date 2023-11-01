interface: Interface,

pub fn top(self: *YRefCluster) YRef {
    return .{
        .state = self.interface.state,
        ._y = &self.interface.span.begin,
        .mut = true,
    };
}

pub fn middle(self: *YRefCluster) YRef {
    return .{
        .state = self.interface.state,
        ._y = &self.interface.span.mid,
        .mut = true,
    };
}

pub fn bottom(self: *YRefCluster) YRef {
    return .{
        .state = self.interface.state,
        ._y = &self.interface.span.end,
        .mut = true,
    };
}

pub fn get(self: *YRefCluster, index: usize) YRef {
    return .{
        .state = self.interface.state,
        ._y = self.interface.contents.items[index],
        .mut = false,
    };
}

pub fn push(self: *YRefCluster) YRef {
    const item = self.interface.push();
    return .{
        .state = self.interface.state,
        ._y = item,
        .mut = false,
    };
}

pub fn debug(self: *YRefCluster, writer: anytype) !void {
    try writer.writeAll("YRefCluster: ");
    try self.interface.debug(writer);
}

const YRefCluster = @This();
const YRef = @import("YRef.zig");
const Interface = @import("Interface.zig");
const DrawingState = @import("DrawingState.zig");
const std = @import("std");
