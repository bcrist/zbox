interface: Interface,

pub fn top(self: *Y_Ref_Cluster) Y_Ref {
    return .{
        .state = self.interface.state,
        ._y = &self.interface.span.begin,
    };
}

pub fn middle(self: *Y_Ref_Cluster) Y_Ref {
    return .{
        .state = self.interface.state,
        ._y = &self.interface.span.mid,
    };
}

pub fn bottom(self: *Y_Ref_Cluster) Y_Ref {
    return .{
        .state = self.interface.state,
        ._y = &self.interface.span.end,
    };
}

pub fn get(self: *Y_Ref_Cluster, index: usize) Y_Ref {
    return .{
        .state = self.interface.state,
        ._y = self.interface.contents.items[index],
    };
}

pub fn push(self: *Y_Ref_Cluster) Y_Ref {
    return .{
        .state = self.interface.state,
        ._y = self.interface.push(),
    };
}

pub fn debug(self: *Y_Ref_Cluster, writer: anytype) !void {
    try writer.writeAll("Y_Ref_Cluster: ");
    try self.interface.debug(writer);
}

const Y_Ref_Cluster = @This();
const Y_Ref = @import("Y_Ref.zig");
const Interface = @import("Interface.zig");
const Drawing_State = @import("Drawing_State.zig");
const std = @import("std");
