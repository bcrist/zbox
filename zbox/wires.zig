pub const Arrow_Style = enum {
    none,
    forward,
    reverse,
    bidirectional,
    junction_begin,
    junction_end,
    junction_both,
    invert_begin,
    invert_end,
    invert_both,
    invert_begin_junction_end,
    junction_begin_invert_end,

    pub const Kind = enum {
        none,
        arrow,
        junction,
        invert,
    };

    pub fn init(begin_kind: Kind, end_kind: Kind) Arrow_Style {
        return switch (begin_kind) {
            .none => switch (end_kind) {
                .none => .none,
                .arrow => .forward,
                .junction => .junction_end,
                .invert => .invert_end,
            },
            .arrow => switch (end_kind) {
                .none => .reverse,
                .arrow => .bidirectional,
                .junction => unreachable,
                .invert => unreachable,
            },
            .junction => switch (end_kind) {
                .none => .junction_begin,
                .arrow => unreachable,
                .junction => .junction_both,
                .invert => .junction_begin_invert_end,
            },
            .invert => switch (end_kind) {
                .none => .invert_begin,
                .arrow => unreachable,
                .junction => .invert_begin_junction_end,
                .invert => .invert_both,
            },
        };
    }

    pub fn begin(self: Arrow_Style) Kind {
        return switch (self) {
            .none => .none,
            .forward => .none,
            .reverse => .arrow,
            .bidirectional => .arrow,
            .junction_begin => .junction,
            .junction_end => .none,
            .junction_both => .junction,
            .invert_begin => .invert,
            .invert_end => .none,
            .invert_both => .invert,
            .invert_begin_junction_end => .invert,
            .junction_begin_invert_end => .junction,
        };
    }

    pub fn end(self: Arrow_Style) Kind {
        return switch (self) {
            .none => .none,
            .forward => .arrow,
            .reverse => .none,
            .bidirectional => .arrow,
            .junction_begin => .none,
            .junction_end => .junction,
            .junction_both => .junction,
            .invert_begin => .none,
            .invert_end => .invert,
            .invert_both => .invert,
            .invert_begin_junction_end => .junction,
            .junction_begin_invert_end => .invert,
        };
    }
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

    pub fn options(self: Wire_Ref) Options {
        return switch (self) {
            .H => |w| w.options,
            .V => |w| w.options,
        };
    }

    pub fn iterator(self: Wire_Ref) Iterator {
        return switch (self) {
            .H => |w| w.iterator(),
            .V => |w| w.iterator(),
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

    pub fn get_label(self: Wire_Ref) ?*Label {
        return switch (self) {
            .H => |w| w._label,
            .V => |w| w._label,
        };
    }

    pub fn eql(self: Wire_Ref, other: Wire_Ref) bool {
        return switch (self) {
            .H => |w| other == .H and other.H == w,
            .V => |w| other == .V and other.V == w,
        };
    }

    /// N.B. this only works once constraints have been evaluated
    pub fn contains_point(self: Wire_Ref, x: f64, y: f64) bool {
        return switch (self) {
            .H => |w| w.contains_point(x, y),
            .V => |w| w.contains_point(x, y),
        };
    }
};

pub const Iterator = struct {
    wire: ?Wire_Ref,

    pub fn next(self: *Iterator) ?Wire_Ref {
        if (self.wire) |wire| {
            self.wire = switch (wire) {
                .H => |w| if (w.next) |n| n.ref() else null,
                .V => |w| if (w.next) |n| n.ref() else null,
            };
            return wire;
        }
        return null;
    }

};

const Label = @import("Label.zig");
const Wire_H = @import("Wire_H.zig");
const Wire_V = @import("Wire_V.zig");
const Point_Ref = @import("Point_Ref.zig");
const std = @import("std");
