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

pub fn format(self: *Y_Ref_Cluster, writer: *std.Io.Writer) error{WriteFailed}!void {
    try writer.writeAll("Y_Ref_Cluster: ");
    try self.interface.format(writer);
}

pub fn set_debug_name(self: *Y_Ref_Cluster, debug_name: []const u8, parent: ?*const anyopaque) void {
    self.interface.state.add_debug_value_name(self, debug_name, parent);
    self.interface.set_debug_name("interface", self);
}

const Y_Ref_Cluster = @This();
const Y_Ref = @import("Y_Ref.zig");
const Interface = @import("Interface.zig");
const Drawing_State = @import("Drawing_State.zig");
const std = @import("std");
