// TODO move state to State struct

gpa: std.mem.Allocator,
arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator),

constraints: ShallowAutoHashMapUnmanaged(*f64, Constraint) = .{},

labels: std.ArrayListUnmanaged(*Label) = .{},
boxes: std.ArrayListUnmanaged(*Box) = .{},
wires_h: std.ArrayListUnmanaged(*WireH) = .{},
wires_v: std.ArrayListUnmanaged(*WireV) = .{},
x_ref_clusters: std.ArrayListUnmanaged(*XRefCluster) = .{},
y_ref_clusters: std.ArrayListUnmanaged(*YRefCluster) = .{},
loose_values: std.ArrayListUnmanaged(*f64) = .{},
interfaces: std.ArrayListUnmanaged(*Interface) = .{},

style: Style = .{},

title: []const u8 = "",
desc: []const u8 = "",

pub fn init(gpa: std.mem.Allocator) *Drawing {
    const self = gpa.create(Drawing) catch @panic("OOM");
    self.* = .{ .gpa = gpa };
    return self;
}

pub fn deinit(self: *Drawing) void {
    for (self.interfaces.items) |interface| {
        interface.contents.deinit(self.gpa);
    }

    self.interfaces.deinit(self.gpa);
    self.loose_values.deinit(self.gpa);
    self.y_ref_clusters.deinit(self.gpa);
    self.x_ref_clusters.deinit(self.gpa);
    self.wires_v.deinit(self.gpa);
    self.wires_h.deinit(self.gpa);
    self.boxes.deinit(self.gpa);
    self.labels.deinit(self.gpa);
    self.constraints.deinit(self.gpa);

    self.arena.deinit();
    self.gpa.destroy(self);
}

pub fn box(self: *Drawing) *Box {
    const arena = self.arena.allocator();
    const item = arena.create(Box) catch @panic("OOM");
    item.* = .{
        .drawing = self,
        .class = self.style.default_box_class,
    };
    self.boxes.append(self.gpa, item) catch @panic("OOM");
    return item;
}

pub fn columns(self: *Drawing) *XRefCluster {
    const arena = self.arena.allocator();
    const item = arena.create(XRefCluster) catch @panic("OOM");
    item.* = .{
        .drawing = self,
    };
    self.x_ref_clusters.append(self.gpa, item) catch @panic("OOM");
    return item;
}

pub fn rows(self: *Drawing) *YRefCluster {
    const arena = self.arena.allocator();
    const item = arena.create(YRefCluster) catch @panic("OOM");
    item.* = .{
        .drawing = self,
    };
    self.y_ref_clusters.append(self.gpa, item) catch @panic("OOM");
    return item;
}

pub fn at(self: *Drawing, abs_x: f64, abs_y: f64) PointRef {
    return .{
        .drawing = self,
        ._x = self.createValue(abs_x),
        ._y = self.createValue(abs_y),
        .mut_x = false,
        .mut_y = false,
    };
}

pub fn point(self: *Drawing) PointRef {
    return .{
        .drawing = self,
        ._x = self.createValue(values.uninitialized),
        ._y = self.createValue(values.uninitialized),
        .mut_x = true,
        .mut_y = true,
    };
}

pub fn x(self: *Drawing, abs_x: f64) XRef {
    return .{
        .drawing = self,
        ._x = self.createValue(abs_x),
        .mut = false,
    };
}

pub fn someX(self: *Drawing) XRef {
    return .{
        .drawing = self,
        ._x = self.createValue(values.uninitialized),
        .mut = true,
    };
}

pub fn y(self: *Drawing, abs_y: f64) YRef {
    return .{
        .drawing = self,
        ._y = self.createValue(abs_y),
        .mut = false,
    };
}

pub fn someY(self: *Drawing) YRef {
    return .{
        .drawing = self,
        ._y = self.createValue(values.uninitialized),
        .mut = true,
    };
}

fn createValue(self: *Drawing, initial: f64) *f64 {
    const arena = self.arena.allocator();
    var item = arena.create(f64) catch @panic("OOM");
    item.* = initial;
    self.loose_values.append(self.gpa, item) catch @panic("OOM");
    return item;
}

pub fn renderSvg(self: *Drawing, writer: anytype) !void {
    self.addMissingConstraints();
    try self.resolveConstraints();

    try writer.print(
        \\<svg viewBox="{d} {d} {d} {d}" xmlns="http://www.w3.org/2000/svg">
        \\
    , .{
        -500, -500, // TODO
        1000, 1000,
    });

    if (self.title.len > 0) {
        try writer.print(
            \\<title>{s}</title>
            \\
        , .{ self.title });
    }

    if (self.desc.len > 0) {
        try writer.print(
            \\<desc>{s}</desc>
            \\
        , .{ self.desc });
    }

    if (self.style.css.len > 0) {
        try writer.print(
            \\<style>
            \\{s}
            \\</style>
            \\
        , .{ self.style.css });
    }

    // TODO use paths for wires, add wire corner radius to style
    for (self.wires_h.items) |w| {
        try self.renderSvgWireH(w, true, w.options, writer);
    }
    for (self.wires_v.items) |w| {
        try self.renderSvgWireV(w, true, w.options, writer);
    }

    for (self.boxes.items) |b| {
        try writer.print(
            \\<rect x="{d}" y="{d}" width="{d}" height="{d}" class="{s}"/>
            \\
        , .{
            b._x.min, b._y.min,
            b._x.len, b._y.len,
            b.class,
        });
    }

    for (self.labels.items) |l| {
        try writer.print(
            \\<text x="{d}" y="{d}" text-anchor="{s}" dominant-baseline="{s}"
        , .{
            l._x, l._y,
            switch (l.alignment) {
                .left => "start",
                .center => "middle",
                .right => "end",
            },
            switch (l.baseline) {
                .normal => "auto",
                .middle => "middle",
                .hanging => "hanging",
            },
        });
        if (l.angle != 0) {
            try writer.print(
                \\ transform-origin="{d} {d}" transform="rotate({d})"
            , .{
                l._x, l._y,
                l.angle,
            });
        }
        try writer.print(
            \\ class="{s}">{s}</text>
            \\
        , .{
            l.class,
            l.text,
        });
    }

    try writer.writeAll("</svg>");
}

fn renderSvgWireH(self: *Drawing, wire: *WireH, first: bool, options: wires.Options, writer: anytype) @TypeOf(writer).Error!void {
    var o = options;
    o.dir = switch (options.dir) {
        .none => .none,
        .forward, .junction_end => if (wire.next == null) options.dir else .none,
        .reverse, .junction_begin => if (first) options.dir else .none,
        .bidirectional, .junction_both => if (first or wire.next == null) options.dir else .none,
    };
    try self.renderSvgLine(wire._x.begin, wire._y, wire._x.end, wire._y, o, writer);
    if (wire.next) |next| try self.renderSvgWireV(next, false, options, writer);
}
fn renderSvgWireV(self: *Drawing, wire: *WireV, first: bool, options: wires.Options, writer: anytype) @TypeOf(writer).Error!void {
    var o = options;
    o.dir = switch (options.dir) {
        .none => .none,
        .forward, .junction_end => if (wire.next == null) options.dir else .none,
        .reverse, .junction_begin => if (first) options.dir else .none,
        .bidirectional, .junction_both => if (first or wire.next == null) options.dir else .none,
    };
    try self.renderSvgLine(wire._x, wire._y.begin, wire._x, wire._y.end, o, writer);
    if (wire.next) |next| try self.renderSvgWireH(next, false, options, writer);
}

fn renderSvgLine(self: *Drawing, x0: f64, y0: f64, x1: f64, y1: f64, options: wires.Options, writer: anytype) @TypeOf(writer).Error!void {
    const class = options.class orelse if (options.bits > 1) self.style.default_bus_class else self.style.default_wire_class;
    try writer.print(
        \\<line x1="{d}" y1="{d}" x2="{d}" y2="{d}" class="{s}"/>
        \\
    , .{
        x0, y0,
        x1, y1,
        class,
    });
    switch (options.dir) {
        .none => {},
        .junction_begin => {}, // TODO
        .junction_end => {}, // TODO
        .junction_both => {}, // TODO
        .forward => try self.renderSvgArrowhead(x0, y0, x1, y1, class, writer),
        .reverse => try self.renderSvgArrowhead(x1, y1, x0, y0, class, writer),
        .bidirectional => {
            try self.renderSvgArrowhead(x0, y0, x1, y1, class, writer);
            try self.renderSvgArrowhead(x1, y1, x0, y0, class, writer);
        },
    }
}

fn renderSvgArrowhead(self: *Drawing, x0: f64, y0: f64, x1: f64, y1: f64, class: []const u8, writer: anytype) @TypeOf(writer).Error!void {
    const dx = x1 - x0;
    const dy = y1 - y0;
    const length = @sqrt(dx * dx + dy * dy);

    const tangent_x = dx / length;
    const tangent_y = dy / length;

    const normal_x = tangent_y;
    const normal_y = -tangent_x;

    try writer.print(
        \\<polyline points="{d},{d} {d},{d} {d},{d}" class="{s} arrow"/>
        \\
    , .{
        x1 - tangent_x * self.style.arrow_length - normal_x * self.style.arrow_width,
        y1 - tangent_y * self.style.arrow_length - normal_y * self.style.arrow_width,

        x1, y1,

        x1 - tangent_x * self.style.arrow_length + normal_x * self.style.arrow_width,
        y1 - tangent_y * self.style.arrow_length + normal_y * self.style.arrow_width,

        class,
    });
}

fn addMissingConstraints(self: *Drawing) void {
    for (self.wires_h.items) |w| {
        w.addMissingConstraints();
    }
    for (self.wires_v.items) |w| {
        w.addMissingConstraints();
    }

    for (self.boxes.items) |b| {
        b.addMissingConstraints();
    }

    for (self.labels.items) |l| {
        l.addMissingConstraints();
    }

    for (self.x_ref_clusters.items) |c| {
        c.interface.addMissingConstraints(self);
    }
    for (self.y_ref_clusters.items) |c| {
        c.interface.addMissingConstraints(self);
    }

    for (self.loose_values.items) |v| {
        if (values.isUninitialized(v.*)) {
            v.* = 0;
        }
    }
}

fn resolveConstraints(self: *Drawing) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var a = arena.allocator();

    var constraints = a.alloc(Constraint, self.constraints.size) catch @panic("OOM");
    var i: usize = 0;
    var iter = self.constraints.valueIterator();
    while (iter.next()) |ptr| {
        constraints[i] = ptr.*;
        i += 1;
    }
    std.debug.assert(i == constraints.len);

    try kahn.sort(a, constraints);

    for (constraints) |constraint| {
        std.debug.assert(values.isConstrained(constraint.dest.*));
        constraint.dest.* = constraint.op.compute();
    }
}

/// Don't use this directly unless you know what you're doing!
pub fn constrain(self: *Drawing, val: *f64, op: Constraint.Op, debug_text: []const u8) void {
    const new_op = op.clone(self.arena.allocator());
    self.constraints.put(self.gpa, val, .{
        .dest = val,
        .op = new_op,
        .debug = debug_text,
    }) catch @panic("OOM");
    std.debug.assert(values.isUninitialized(val.*));
    val.* = values.constrained;
}

pub fn removeConstraint(self: *Drawing, val: *f64) void {
    _ = self.constraints.remove(val);
}

pub fn debug(self: *Drawing, writer: anytype) !void {
    for (self.x_ref_clusters.items) |c| {
        try c.debug(writer);
    }
    for (self.y_ref_clusters.items) |c| {
        try c.debug(writer);
    }

     for (self.wires_h.items) |w| {
        try w.debug(writer);
    }
    for (self.wires_v.items) |w| {
        try w.debug(writer);
    }

    for (self.boxes.items) |b| {
        try b.debug(writer);
    }

    for (self.labels.items) |l| {
        try l.debug(writer);
    }
}

const Drawing = @This();
const PointRef = @import("PointRef.zig");
const XRef = @import("XRef.zig");
const YRef = @import("YRef.zig");
const XRefCluster = @import("XRefCluster.zig");
const YRefCluster = @import("YRefCluster.zig");
const Box = @import("Box.zig");
const wires = @import("wires.zig");
const WireH = @import("WireH.zig");
const WireV = @import("WireV.zig");
const Interface = @import("Interface.zig");
const Label = @import("Label.zig");
const Constraint = @import("Constraint.zig");
const Style = @import("Style.zig");
const kahn = @import("kahn.zig");
const values = @import("values.zig");
const ShallowAutoHashMapUnmanaged = @import("deep_hash_map").ShallowAutoHashMapUnmanaged;
const std = @import("std");
