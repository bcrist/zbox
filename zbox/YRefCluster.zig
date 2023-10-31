interface: Interface,

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

const YRefCluster = @This();
const YRef = @import("YRef.zig");
const Interface = @import("Interface.zig");
const DrawingState = @import("DrawingState.zig");
const std = @import("std");
