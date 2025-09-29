dest: *f64,
op: Op,
debug: []const u8,

const Formattable = struct {
    constraint: Constraint,
    state: *const Drawing_State,

    pub fn format(self: Formattable, w: *std.io.Writer) !void {
        try debug_ptr(self.state, self.constraint.dest, w);
        try w.writeAll(": ");
        try self.constraint.op.debug(self.state, w);
    }
};

pub fn formatter(self: Constraint, state: *const Drawing_State) std.fmt.Alt(Formattable, Formattable.format) {
    return .{ .data = .{
        .constraint = self,
        .state = state,
    }};
}

fn debug_ptr(state: *const Drawing_State, ptr: *const anyopaque, w: *std.io.Writer) !void {
    if (state.debug_value_names.get(ptr)) |name| {
        if (name.parent) |parent| {
            try debug_ptr(state, parent, w);
            try w.writeByte('.');
        }
        try w.writeAll(name.name);
    } else {
        try w.print("#{X:0>16}", .{ @intFromPtr(ptr) });
    }
}

pub const Op = union(enum) {
    copy: *const f64,

    offset_and_scale: One_Operand_Scale_Offset,
    scale_and_offset: One_Operand_Scale_Offset,

    scaled_difference: Two_Operand_Coefficient,
    scaled_offset: Two_Operand_Coefficient,
    lerp: Two_Operand_Coefficient,

    difference: [2]*const f64,
    midpoint: [2]*const f64,
    sum2: [2]*const f64,
    min2: [2]*const f64,
    max2: [2]*const f64,

    sum: []const *const f64,
    product: []const *const f64,
    mean: []const *const f64,
    min: []const *const f64,
    max: []const *const f64,

    pub fn clone(self: Op, allocator: std.mem.Allocator) Op {
        switch (self) {
            .copy,
            .offset_and_scale, .scale_and_offset,
            .scaled_difference, .scaled_offset, .lerp, 
            .difference, .midpoint, .sum2, .min2, .max2
                => return self,

            .sum => |ptrs| return .{ .sum = allocator.dupe(*const f64, ptrs) catch @panic("OOM") },
            .product => |ptrs| return .{ .product = allocator.dupe(*const f64, ptrs) catch @panic("OOM") },
            .mean => |ptrs| return .{ .mean = allocator.dupe(*const f64, ptrs) catch @panic("OOM") },
            .min => |ptrs| return .{ .min = allocator.dupe(*const f64, ptrs) catch @panic("OOM") },
            .max => |ptrs| return .{ .max = allocator.dupe(*const f64, ptrs) catch @panic("OOM") },
        }
    }

    pub fn debug(self: Op, state: *const Drawing_State, w: *std.io.Writer) !void {
        try w.writeAll(@tagName(self));
        try w.writeAll(": ");
        switch (self) {
            .copy => |other| try debug_ptr(state, other, w),
            .offset_and_scale, .scale_and_offset => |info| try debug_ptr(state, info.src, w),
            .scaled_difference, .scaled_offset, .lerp, => |info| {
                try w.writeAll("\n                        [0]: ");
                try debug_ptr(state, info.operands[0], w);
                try w.writeAll("\n                        [1]: ");
                try debug_ptr(state, info.operands[1], w);
            },
            .difference, .midpoint, .sum2, .min2, .max2 => |ptrs| {
                try w.writeAll("\n                        [0]: ");
                try debug_ptr(state, ptrs[0], w);
                try w.writeAll("\n                        [1]: ");
                try debug_ptr(state, ptrs[1], w);
            },
            .sum, .product, .mean, .min, .max => |ptrs| {
                for (0.., ptrs) |i, ptr| {
                    try w.print("\n                        [{d}]: ", .{ i });
                    try debug_ptr(state, ptr, w);
                }
            },
        }
    }

    pub fn deps(self: *const Op) []const *const f64 {
        return switch (self.*) {
            .copy => |*ptr| ptr[0..1],
            .offset_and_scale, .scale_and_offset => |*info| (&info.src)[0..1],
            .scaled_difference, .scaled_offset, .lerp => |*info| &info.operands,
            .difference, .midpoint, .sum2, .min2, .max2 => |*operands| operands,
            .sum, .product, .mean, .min, .max => |ptrs| ptrs,
        };
    }

    pub fn compute(self: Op) f64 {
        switch (self) {
            .copy => |ptr| {
                const v: f64 = ptr.*;
                std.debug.assert(!std.math.isNan(v));
                return v;
            },
            .offset_and_scale => |info| {
                const src = info.src.*;
                std.debug.assert(!std.math.isNan(src));
                return (src + info.offset) * info.scale;
            },
            .scale_and_offset => |info| {
                const src = info.src.*;
                std.debug.assert(!std.math.isNan(src));
                return src * info.scale + info.offset;
            },
            .scaled_difference => |info| {
                const minuend = info.operands[0].*;
                const subtrahend = info.operands[1].*;
                std.debug.assert(!std.math.isNan(minuend));
                std.debug.assert(!std.math.isNan(subtrahend));
                return (minuend - subtrahend) * info.k;
            },
            .scaled_offset => |info| {
                const base = info.operands[0].*;
                const offset = info.operands[1].*;
                std.debug.assert(!std.math.isNan(base));
                std.debug.assert(!std.math.isNan(offset));
                return base + offset * info.k;
            },
            .lerp => |info| {
                const a = info.operands[0].*;
                const b = info.operands[1].*;
                std.debug.assert(!std.math.isNan(a));
                std.debug.assert(!std.math.isNan(b));
                const fb = info.k;
                const fa = 1 - fb;
                return a * fa + b * fb;
            },
            .difference => |operands| {
                const a: f64 = operands[0].*;
                const b: f64 = operands[1].*;
                std.debug.assert(!std.math.isNan(a));
                std.debug.assert(!std.math.isNan(b));
                return a - b;
            },
            .midpoint => |operands| {
                const a: f64 = operands[0].*;
                const b: f64 = operands[1].*;
                std.debug.assert(!std.math.isNan(a));
                std.debug.assert(!std.math.isNan(b));
                return (a + b) / 2;
            },
            .sum2 => |operands| {
                const a: f64 = operands[0].*;
                const b: f64 = operands[1].*;
                std.debug.assert(!std.math.isNan(a));
                std.debug.assert(!std.math.isNan(b));
                return a + b;
            },
            .min2 => |operands| {
                const a: f64 = operands[0].*;
                const b: f64 = operands[1].*;
                std.debug.assert(!std.math.isNan(a));
                std.debug.assert(!std.math.isNan(b));
                return @min(a, b);
            },
            .max2 => |operands| {
                const a: f64 = operands[0].*;
                const b: f64 = operands[1].*;
                std.debug.assert(!std.math.isNan(a));
                std.debug.assert(!std.math.isNan(b));
                return @max(a, b);
            },
            .sum => |ptrs| {
                var a: f64 = 0;
                for (ptrs) |ptr| {
                    const src = ptr.*;
                    std.debug.assert(!std.math.isNan(src));
                    a += src;
                }
                return a;
            },
            .product => |ptrs| {
                var a: f64 = 0;
                for (ptrs) |ptr| {
                    const src = ptr.*;
                    std.debug.assert(!std.math.isNan(src));
                    a *= src;
                }
                return a;
            },
            .mean => |ptrs| {
                var a: f64 = 0;
                for (ptrs) |ptr| {
                    const src = ptr.*;
                    std.debug.assert(!std.math.isNan(src));
                    a += src;
                }
                a /= @floatFromInt(ptrs.len);
                return a;
            },
            .min => |ptrs| {
                var m: f64 = ptrs[0].*;
                for (ptrs[1..]) |ptr| {
                    const src = ptr.*;
                    std.debug.assert(!std.math.isNan(src));
                    if (src < m) {
                        m = src;
                    }
                }
                return m;
            },
            .max => |ptrs| {
                var m: f64 = ptrs[0].*;
                for (ptrs[1..]) |ptr| {
                    const src = ptr.*;
                    std.debug.assert(!std.math.isNan(src));
                    if (src > m) {
                        m = src;
                    }
                }
                return m;
            },
        }
    }
};

pub const One_Operand_Scale_Offset = struct {
    src: *const f64,
    offset: f64,
    scale: f64,
};

pub const Two_Operand_Coefficient = struct {
    operands: [2]*const f64,
    k: f64,
};

const Constraint = @This();

const Drawing_State = @import("Drawing_State.zig");
const values = @import("values.zig");
const std = @import("std");
