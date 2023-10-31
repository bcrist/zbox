drawing: *Drawing,
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

pub fn deinit(self: *DrawingState) void {
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
}

pub fn createValue(self: *DrawingState, initial_value: f64) *f64 {
    const arena = self.arena.allocator();
    var item = arena.create(f64) catch @panic("OOM");
    item.* = initial_value;
    self.loose_values.append(self.gpa, item) catch @panic("OOM");
    return item;
}

pub fn createLabel(self: *DrawingState, text: []const u8, class: []const u8, alignment: Label.Alignment, baseline: Label.Baseline, angle: f64) *Label {
    const arena = self.arena.allocator();
    const item = arena.create(Label) catch @panic("OOM");
    item.* = .{
        .text = text,
        .class = class,
        .alignment = alignment,
        .baseline = baseline,
        .angle = angle,
    };
    self.labels.append(self.gpa, item) catch @panic("OOM");
    return item;
}

pub fn createWireH(self: *DrawingState, options: wires.Options, previous: ?*WireV) *WireH {
    const arena = self.arena.allocator();
    const item = arena.create(WireH) catch @panic("OOM");
    item.* = .{
        .state = self,
        .options = options,
    };
    if (previous) |w| {
        w.next = item;
    } else {
        self.wires_h.append(self.gpa, item) catch @panic("OOM");
    }
    return item;
}

pub fn createWireV(self: *DrawingState, options: wires.Options, previous: ?*WireH) *WireV {
    const arena = self.arena.allocator();
    const item = arena.create(WireV) catch @panic("OOM");
    item.* = .{
        .state = self,
        .options = options,
    };
    if (previous) |w| {
        w.next = item;
    } else {
        self.wires_v.append(self.gpa, item) catch @panic("OOM");
    }
    return item;
}

pub fn createBox(self: *DrawingState, class: []const u8) *Box {
    const arena = self.arena.allocator();
    const item = arena.create(Box) catch @panic("OOM");
    item.* = .{
        .state = self,
        .class = class,
    };
    self.boxes.append(self.gpa, item) catch @panic("OOM");
    return item;
}

pub fn createInterface(self: *DrawingState) *Interface {
    const arena = self.arena.allocator();
    const item = arena.create(Interface) catch @panic("OOM");
    item.* = .{
        .state = self,
    };
    self.interfaces.append(self.gpa, item) catch @panic("OOM");
    return item;
}

pub fn createXRefCluster(self: *DrawingState) *XRefCluster {
    const arena = self.arena.allocator();
    const item = arena.create(XRefCluster) catch @panic("OOM");
    item.* = .{ .interface = .{
        .state = self,
    }};
    self.x_ref_clusters.append(self.gpa, item) catch @panic("OOM");
    self.interfaces.append(self.gpa, &item.interface) catch @panic("OOM");
    return item;
}

pub fn createYRefCluster(self: *DrawingState) *YRefCluster {
    const arena = self.arena.allocator();
    const item = arena.create(YRefCluster) catch @panic("OOM");
    item.* = .{ .interface = .{
        .state = self,
    }};
    self.y_ref_clusters.append(self.gpa, item) catch @panic("OOM");
    self.interfaces.append(self.gpa, &item.interface) catch @panic("OOM");
    return item;
}

pub fn addMissingConstraints(self: *DrawingState) void {
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
        c.interface.addMissingConstraints();
    }
    for (self.y_ref_clusters.items) |c| {
        c.interface.addMissingConstraints();
    }

    for (self.loose_values.items) |v| {
        if (values.isUninitialized(v.*)) {
            v.* = 0;
        }
    }
}

pub fn resolveConstraints(self: *DrawingState) !void {
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
pub fn constrain(self: *DrawingState, val: *f64, op: Constraint.Op, debug_text: []const u8) void {
    const new_op = op.clone(self.arena.allocator());
    self.constraints.put(self.gpa, val, .{
        .dest = val,
        .op = new_op,
        .debug = debug_text,
    }) catch @panic("OOM");
    std.debug.assert(values.isUninitialized(val.*));
    val.* = values.constrained;
}

pub fn removeConstraint(self: *DrawingState, val: *f64) void {
    _ = self.constraints.remove(val);
}

pub fn debug(self: *DrawingState, writer: anytype) !void {
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

const DrawingState = @This();
const Drawing = @import("Drawing.zig");
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
const ShallowAutoHashMapUnmanaged = @import("deep_hash_map").ShallowAutoHashMapUnmanaged;
const kahn = @import("kahn.zig");
const values = @import("values.zig");
const std = @import("std");
