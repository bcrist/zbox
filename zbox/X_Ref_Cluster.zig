interface: Interface,

pub fn left(self: *X_Ref_Cluster) X_Ref {
    return .{
        .state = self.interface.state,
        ._x = &self.interface.span.begin,
    };
}

pub fn center(self: *X_Ref_Cluster) X_Ref {
    return .{
        .state = self.interface.state,
        ._x = &self.interface.span.mid,
    };
}

pub fn right(self: *X_Ref_Cluster) X_Ref {
    return .{
        .state = self.interface.state,
        ._x = &self.interface.span.end,
    };
}

pub fn get(self: *X_Ref_Cluster, index: usize) X_Ref {
    return .{
        .state = self.interface.state,
        ._x = self.interface.contents.items[index],
    };
}

pub fn push(self: *X_Ref_Cluster) X_Ref {
    return .{
        .state = self.interface.state,
        ._x = self.interface.push(),
    };
}

pub fn format(self: *X_Ref_Cluster, writer: *std.Io.Writer) error{WriteFailed}!void {
    try writer.writeAll("X_Ref_Cluster: ");
    try self.interface.format(writer);
}

pub fn set_debug_name(self: *X_Ref_Cluster, debug_name: []const u8, parent: ?*const anyopaque) void {
    self.interface.state.add_debug_value_name(self, debug_name, parent);
    self.interface.set_debug_name("interface", self);
}

const X_Ref_Cluster = @This();
const X_Ref = @import("X_Ref.zig");
const Interface = @import("Interface.zig");
const Drawing_State = @import("Drawing_State.zig");
const std = @import("std");
