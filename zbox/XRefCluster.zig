interface: Interface,

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

const XRefCluster = @This();
const XRef = @import("XRef.zig");
const Interface = @import("Interface.zig");
const DrawingState = @import("DrawingState.zig");
const std = @import("std");
