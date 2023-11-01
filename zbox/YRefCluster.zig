interface: Interface,

pub fn top(self: *YRefCluster) YRef {
    return .{
        .state = self.interface.state,
        ._y = &self.interface.span.begin,
    };
}

pub fn middle(self: *YRefCluster) YRef {
    return .{
        .state = self.interface.state,
        ._y = &self.interface.span.mid,
    };
}

pub fn bottom(self: *YRefCluster) YRef {
    return .{
        .state = self.interface.state,
        ._y = &self.interface.span.end,
    };
}

pub fn get(self: *YRefCluster, index: usize) YRef {
    return .{
        .state = self.interface.state,
        ._y = self.interface.contents.items[index],
    };
}

pub fn push(self: *YRefCluster) YRef {
    return .{
        .state = self.interface.state,
        ._y = self.interface.push(),
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
