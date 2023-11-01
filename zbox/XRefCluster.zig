interface: Interface,

pub fn left(self: *XRefCluster) XRef {
    return .{
        .state = self.interface.state,
        ._x = &self.interface.span.begin,
        .mut = true,
    };
}

pub fn center(self: *XRefCluster) XRef {
    return .{
        .state = self.interface.state,
        ._x = &self.interface.span.mid,
        .mut = true,
    };
}

pub fn right(self: *XRefCluster) XRef {
    return .{
        .state = self.interface.state,
        ._x = &self.interface.span.end,
        .mut = true,
    };
}

pub fn get(self: *XRefCluster, index: usize) XRef {
    return .{
        .state = self.interface.state,
        ._x = self.interface.contents.items[index],
        .mut = false,
    };
}

pub fn push(self: *XRefCluster) XRef {
    const item = self.interface.push();
    return .{
        .state = self.interface.state,
        ._x = item,
        .mut = false,
    };
}

pub fn debug(self: *XRefCluster, writer: anytype) !void {
    try writer.writeAll("XRefCluster: ");
    try self.interface.debug(writer);
}

const XRefCluster = @This();
const XRef = @import("XRef.zig");
const Interface = @import("Interface.zig");
const DrawingState = @import("DrawingState.zig");
const std = @import("std");
