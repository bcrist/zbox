drawing: *Drawing,
gpa: std.mem.Allocator,
arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator),

constraints: ShallowAutoHashMapUnmanaged(*const f64, Constraint) = .{},
debug_value_names: ShallowAutoHashMapUnmanaged(*const anyopaque, Value_Name) = .{},

labels: std.ArrayListUnmanaged(*Label) = .{},

boxes: std.ArrayListUnmanaged(*Box) = .{},

// Note only the first segment of each wire is stored here;
// iterate through the .next chains to find the other segments
wires_h: std.ArrayListUnmanaged(*Wire_H) = .{},
wires_v: std.ArrayListUnmanaged(*Wire_V) = .{},

x_ref_clusters: std.ArrayListUnmanaged(*X_Ref_Cluster) = .{},
y_ref_clusters: std.ArrayListUnmanaged(*Y_Ref_Cluster) = .{},

separators_h: std.ArrayListUnmanaged(*Separator_H) = .{},
separators_v: std.ArrayListUnmanaged(*Separator_V) = .{},

loose_values: std.ArrayListUnmanaged(*f64) = .{},

// note this includes the interfaces inside X/Y_Ref_Clusters as well
interfaces: std.ArrayListUnmanaged(*Interface) = .{},

const Value_Name = struct {
    name: []const u8,
    parent: ?*const anyopaque = null,
};

pub fn deinit(self: *Drawing_State) void {
    for (self.interfaces.items) |interface| {
        interface.contents.deinit(self.gpa);
    }

    self.interfaces.deinit(self.gpa);
    self.loose_values.deinit(self.gpa);
    self.separators_h.deinit(self.gpa);
    self.separators_v.deinit(self.gpa);
    self.y_ref_clusters.deinit(self.gpa);
    self.x_ref_clusters.deinit(self.gpa);
    self.wires_v.deinit(self.gpa);
    self.wires_h.deinit(self.gpa);
    self.boxes.deinit(self.gpa);
    self.labels.deinit(self.gpa);
    self.constraints.deinit(self.gpa);
    self.debug_value_names.deinit(self.gpa);

    self.arena.deinit();
}

pub fn add_debug_value_name(self: *Drawing_State, ptr: *const anyopaque, name: []const u8, parent: ?*const anyopaque) void {
    self.debug_value_names.put(self.gpa, ptr, .{
        .name = name,
        .parent = parent,
    }) catch @panic("OOM");
}

pub fn print(self: *Drawing_State, comptime fmt: []const u8, args: anytype) []const u8 {
    return std.fmt.allocPrint(self.arena.allocator(), fmt, args) catch @panic("OOM");
}

pub fn create_value(self: *Drawing_State, initial_value: f64, debug_name: []const u8, parent: ?*const anyopaque) *f64 {
    const arena = self.arena.allocator();
    const item = arena.create(f64) catch @panic("OOM");
    item.* = initial_value;
    self.loose_values.append(self.gpa, item) catch @panic("OOM");
    self.add_debug_value_name(item, if (debug_name.len > 0) debug_name else "(f64)", parent);
    return item;
}

pub fn create_label(self: *Drawing_State, text: []const u8, options: Label.Options, parent: ?*const anyopaque) *Label {
    const arena = self.arena.allocator();
    const item = arena.create(Label) catch @panic("OOM");
    item.* = .{
        .state = self,
        .text = text,
        .options = options,
    };
    self.labels.append(self.gpa, item) catch @panic("OOM");
    item.set_debug_name(if (options.debug.len > 0) options.debug else text, parent);
    return item;
}

pub fn create_wire_h(self: *Drawing_State, options: wires.Options, previous: ?*Wire_V, parent: ?*const anyopaque) *Wire_H {
    const arena = self.arena.allocator();
    const item = arena.create(Wire_H) catch @panic("OOM");
    item.* = .{
        .state = self,
        .options = options,
    };
    if (previous) |w| {
        w.next = item;
    } else {
        self.wires_h.append(self.gpa, item) catch @panic("OOM");
        item.set_debug_name("Wire", parent);
    }
    return item;
}

pub fn create_wire_v(self: *Drawing_State, options: wires.Options, previous: ?*Wire_H, parent: ?*const anyopaque) *Wire_V {
    const arena = self.arena.allocator();
    const item = arena.create(Wire_V) catch @panic("OOM");
    item.* = .{
        .state = self,
        .options = options,
    };
    if (previous) |w| {
        w.next = item;
    } else {
        self.wires_v.append(self.gpa, item) catch @panic("OOM");
        item.set_debug_name("Wire", parent);
    }
    return item;
}

pub fn create_separator_h(self: *Drawing_State, parent: ?*const anyopaque) *Separator_H {
    const arena = self.arena.allocator();
    const item = arena.create(Separator_H) catch @panic("OOM");
    item.* = .{
        .state = self,
    };
    self.separators_h.append(self.gpa, item) catch @panic("OOM");
    item.set_debug_name("Separator_H", parent);
    return item;
}

pub fn create_separator_v(self: *Drawing_State, parent: ?*const anyopaque) *Separator_V {
    const arena = self.arena.allocator();
    const item = arena.create(Separator_V) catch @panic("OOM");
    item.* = .{
        .state = self,
    };
    self.separators_v.append(self.gpa, item) catch @panic("OOM");
    item.set_debug_name("Separator_V", parent);
    return item;
}

pub fn create_box(self: *Drawing_State, options: Box.Options, parent: ?*const anyopaque) *Box {
    const arena = self.arena.allocator();
    const item = arena.create(Box) catch @panic("OOM");
    item.* = .{
        .state = self,
        .options = options,
    };
    self.boxes.append(self.gpa, item) catch @panic("OOM");
    const debug_name = if (options.debug.len > 0) options.debug else if (options.label.len > 0) options.label else "Box";
    item.set_debug_name(debug_name, parent);
    return item;
}

pub fn create_interface(self: *Drawing_State, debug_name: []const u8, parent: ?*const anyopaque) *Interface {
    const arena = self.arena.allocator();
    const item = arena.create(Interface) catch @panic("OOM");
    item.* = .{
        .state = self,
    };
    self.interfaces.append(self.gpa, item) catch @panic("OOM");
    item.set_debug_name(if (debug_name.len > 0) debug_name else "Interface", parent);
    return item;
}

pub fn create_x_ref_cluster(self: *Drawing_State, parent: ?*const anyopaque) *X_Ref_Cluster {
    const arena = self.arena.allocator();
    const item = arena.create(X_Ref_Cluster) catch @panic("OOM");
    item.* = .{ .interface = .{
        .state = self,
    }};
    self.x_ref_clusters.append(self.gpa, item) catch @panic("OOM");
    self.interfaces.append(self.gpa, &item.interface) catch @panic("OOM");
    item.set_debug_name("X_Ref_Cluster", parent);
    return item;
}

pub fn create_y_ref_cluster(self: *Drawing_State, parent: ?*const anyopaque) *Y_Ref_Cluster {
    const arena = self.arena.allocator();
    const item = arena.create(Y_Ref_Cluster) catch @panic("OOM");
    item.* = .{ .interface = .{
        .state = self,
    }};
    self.y_ref_clusters.append(self.gpa, item) catch @panic("OOM");
    self.interfaces.append(self.gpa, &item.interface) catch @panic("OOM");
    item.set_debug_name("Y_Ref_Cluster", parent);
    return item;
}

pub fn add_missing_constraints(self: *Drawing_State) void {
    for (self.wires_h.items) |w| {
        w.add_missing_constraints();
    }
    for (self.wires_v.items) |w| {
        w.add_missing_constraints();
    }

    for (self.boxes.items) |b| {
        b.add_missing_constraints();
    }

    for (self.labels.items) |l| {
        l.add_missing_constraints();
    }

    for (self.x_ref_clusters.items) |c| {
        c.interface.add_missing_constraints();
    }
    for (self.y_ref_clusters.items) |c| {
        c.interface.add_missing_constraints();
    }

    for (self.separators_h.items) |sep| {
        if (values.is_uninitialized(sep._y)) {
            sep._y = 0;
        }
    }
    for (self.separators_v.items) |sep| {
        if (values.is_uninitialized(sep._x)) {
            sep._x = 0;
        }
    }

    for (self.loose_values.items) |v| {
        if (values.is_uninitialized(v.*)) {
            v.* = 0;
        }
    }
}

pub fn resolve_constraints(self: *Drawing_State) !void {
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

    try kahn.sort(a, self, constraints);

    for (constraints) |constraint| {
        std.debug.assert(values.is_constrained(constraint.dest.*));
        constraint.dest.* = constraint.op.compute();
    }
}

pub fn constrain(self: *Drawing_State, val: *f64, op: Constraint.Op, debug_text: []const u8) void {
    const new_op = op.clone(self.arena.allocator());
    self.constraints.put(self.gpa, val, .{
        .dest = val,
        .op = new_op,
        .debug = debug_text,
    }) catch @panic("OOM");

    val.* = values.constrained;
}

pub fn constrain_eql(self: *Drawing_State, dest: *f64, src: *const f64, debug_text: []const u8) void {
    self.constrain(dest, .{ .copy = src }, debug_text);
}

pub fn constrain_offset(self: *Drawing_State, dest: *f64, src: *const f64, offset: f64, debug_text: []const u8) void {
    self.constrain(dest, .{ .offset_and_scale = .{
        .src = src,
        .offset = offset,
        .scale = 1,
    }}, debug_text);
}

pub fn constrain_scaled_offset(self: *Drawing_State, dest: *f64, src: *const f64, offset: *const f64, offset_scale: f64, debug_text: []const u8) void {
    self.constrain(dest, .{ .scaled_offset = .{
        .operands = .{ src, offset },
        .k = offset_scale,
    }}, debug_text);
}

pub fn constrain_scale(self: *Drawing_State, dest: *f64, src: *const f64, scale: f64, debug_text: []const u8) void {
    self.constrain(dest, .{ .offset_and_scale = .{
        .src = src,
        .offset = 0,
        .scale = scale,
    }}, debug_text);
}

pub fn constrain_midpoint(self: *Drawing_State, dest: *f64, v0: *const f64, v1: *const f64, debug_text: []const u8) void {
    self.constrain(dest, .{ .midpoint = .{ v0, v1 }}, debug_text);
}

pub fn constrain_lerp(self: *Drawing_State, dest: *f64, v0: *const f64, v1: *const f64, f: f64, debug_text: []const u8) void {
    self.constrain(dest, .{ .lerp = .{
        .operands = .{ v0, v1 },
        .k = f,
    }}, debug_text);
}

pub fn remove_constraint(self: *Drawing_State, val: *f64) void {
    _ = self.constraints.remove(val);
}

pub fn format(self: *Drawing_State, writer: *std.io.Writer) error{WriteFailed}!void {
    for (self.x_ref_clusters.items) |c| {
        try c.format(writer);
    }
    for (self.y_ref_clusters.items) |c| {
        try c.format(writer);
    }

     for (self.wires_h.items) |w| {
        try w.format(writer);
    }
    for (self.wires_v.items) |w| {
        try w.format(writer);
    }

    for (self.boxes.items) |b| {
        try b.format(writer);
    }

    for (self.labels.items) |l| {
        try l.format(writer);
    }
}

const Drawing_State = @This();
const Drawing = @import("Drawing.zig");
const Point_Ref = @import("Point_Ref.zig");
const X_Ref = @import("X_Ref.zig");
const Y_Ref = @import("Y_Ref.zig");
const X_Ref_Cluster = @import("X_Ref_Cluster.zig");
const Y_Ref_Cluster = @import("Y_Ref_Cluster.zig");
const Box = @import("Box.zig");
const Separator_H = @import("Separator_H.zig");
const Separator_V = @import("Separator_V.zig");
const wires = @import("wires.zig");
const Wire_H = @import("Wire_H.zig");
const Wire_V = @import("Wire_V.zig");
const Interface = @import("Interface.zig");
const Label = @import("Label.zig");
const Constraint = @import("Constraint.zig");
const ShallowAutoHashMapUnmanaged = @import("deep_hash_map").ShallowAutoHashMapUnmanaged;
const kahn = @import("kahn.zig");
const values = @import("values.zig");
const std = @import("std");
