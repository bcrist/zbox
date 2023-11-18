pub const Arrow_Style = enum {
    none,
    forward,
    reverse,
    bidirectional,
    junction_begin,
    junction_end,
    junction_both,
};

pub const Options = struct {
    bits: usize = 1,
    dir: Arrow_Style = .none,
    class: []const u8 = "",
    corner_radius: ?f64 = null,
};

pub const Wire_Ref = union(enum) {
    H: *Wire_H,
    V: *Wire_V,

    pub fn initH(wire: *Wire_H) Wire_Ref {
        return .{ .H = wire };
    }
    pub fn initV(wire: *Wire_V) Wire_Ref {
        return .{ .V = wire };
    }

    pub fn options(self: Wire_Ref) Options {
        return switch (self) {
            .H => |w| w.options,
            .V => |w| w.options,
        };
    }

    pub fn begin(self: Wire_Ref) Point_Ref {
        return switch (self) {
            .H => |w| .{
                .state = w.state,
                ._x = &w._x.begin,
                ._y = &w._y,
            },
            .V => |w| .{
                .state = w.state,
                ._x = &w._x,
                ._y = &w._y.begin,
            },
        };
    }

    pub fn end(self: Wire_Ref) Point_Ref {
        return switch (self) {
            .H => |w| .{
                .state = w.state,
                ._x = &w._x.end,
                ._y = &w._y,
            },
            .V => |w| .{
                .state = w.state,
                ._x = &w._x,
                ._y = &w._y.end,
            },
        };
    }

    pub fn bit_mark(self: Wire_Ref) ?f64 {
        return switch (self) {
            .H => |w| w.bit_mark_location,
            .V => |w| w.bit_mark_location,
        };
    }
};

pub const Iterator = struct {
    wire: ?Wire_Ref,

    pub fn next(self: *Iterator) ?Wire_Ref {
        if (self.wire) |wire| {
            self.wire = switch (wire) {
                .H => |w| if (w.next) |n| Wire_Ref.initV(n) else null,
                .V => |w| if (w.next) |n| Wire_Ref.initH(n) else null,
            };
            return wire;
        }
        return null;
    }

};

const Wire_H = @import("Wire_H.zig");
const Wire_V = @import("Wire_V.zig");
const Point_Ref = @import("Point_Ref.zig");
