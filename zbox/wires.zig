pub const ArrowStyle = enum {
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
    dir: ArrowStyle = .none,
    class: ?[]const u8 = null,
    corner_radius: ?f64 = null,
};

pub const WireRef = union(enum) {
    H: *WireH,
    V: *WireV,

    pub fn initH(wire: *WireH) WireRef {
        return .{ .H = wire };
    }
    pub fn initV(wire: *WireV) WireRef {
        return .{ .V = wire };
    }

    pub fn options(self: WireRef) Options {
        return switch (self) {
            .H => |w| w.options,
            .V => |w| w.options,
        };
    }

    pub fn begin(self: WireRef) PointRef {
        return switch (self) {
            .H => |w| .{
                .state = w.state,
                ._x = &w._x.begin,
                ._y = &w._y,
                .mut_x = true,
                .mut_y = true,
            },
            .V => |w| .{
                .state = w.state,
                ._x = &w._x,
                ._y = &w._y.begin,
                .mut_x = true,
                .mut_y = true,
            },
        };
    }

    pub fn end(self: WireRef) PointRef {
        return switch (self) {
            .H => |w| .{
                .state = w.state,
                ._x = &w._x.end,
                ._y = &w._y,
                .mut_x = true,
                .mut_y = true,
            },
            .V => |w| .{
                .state = w.state,
                ._x = &w._x,
                ._y = &w._y.end,
                .mut_x = true,
                .mut_y = true,
            },
        };
    }

    pub fn bitMark(self: WireRef) ?f64 {
        return switch (self) {
            .H => |w| w.bit_mark,
            .V => |w| w.bit_mark,
        };
    }
};

pub const Iterator = struct {
    wire: ?WireRef,

    pub fn next(self: *Iterator) ?WireRef {
        if (self.wire) |wire| {
            self.wire = switch (wire) {
                .H => |w| if (w.next) |n| WireRef.initV(n) else null,
                .V => |w| if (w.next) |n| WireRef.initH(n) else null,
            };
            return wire;
        }
        return null;
    }

};

const WireH = @import("WireH.zig");
const WireV = @import("WireV.zig");
const PointRef = @import("PointRef.zig");
