gpa: std.mem.Allocator,
groups: std.ArrayList(Wire_Group) = .empty,
label_text_lookup: std.StringHashMapUnmanaged(usize) = .empty,
label_lookup: deep_hash_map.ShallowAutoHashMapUnmanaged(*Label, usize) = .empty,
wire_lookup: deep_hash_map.ShallowAutoHashMapUnmanaged(Wire_Ref, usize) = .empty,

pub const Wire_Group = struct {
    wires: std.ArrayList(Wire_Ref),
    labels: std.ArrayList(*Label),

    pub const empty: Wire_Group = .{
        .wires = .empty,
        .labels = .empty,
    };
    
    pub fn deinit(self: *Wire_Group, gpa: std.mem.Allocator) void {
        self.wires.deinit(gpa);
        self.labels.deinit(gpa);
    }

    pub fn add_wire(self: *Wire_Group, gpa: std.mem.Allocator, wire: Wire_Ref) !void {
        try self.wires.append(gpa, wire);
    }

    pub fn add_label(self: *Wire_Group, gpa: std.mem.Allocator, label: *Label) !void {
        try self.labels.append(gpa, label);
    }
};

pub fn init(gpa: std.mem.Allocator, state: *Drawing_State) !Wire_Groups {
    var self: Wire_Groups = .{
        .gpa = gpa,
    };
    errdefer self.deinit();

    for (state.wires_h.items) |wire| {
        try self.process_wire(wire.ref());
    }

    for (state.wires_v.items) |wire| {
        try self.process_wire(wire.ref());
    }

    for (state.wires_h.items) |wire| {
        try self.process_wire_junctions(wire.ref());
    }

    for (state.wires_v.items) |wire| {
        try self.process_wire_junctions(wire.ref());
    }

    return self;
}

pub fn deinit(self: *Wire_Groups) void {
    for (self.groups.items) |*group| {
        group.deinit(self.gpa);
    }
    self.groups.deinit(self.gpa);
    self.label_text_lookup.deinit(self.gpa);
    self.label_lookup.deinit(self.gpa);
    self.wire_lookup.deinit(self.gpa);
}

fn process_wire(self: *Wire_Groups, wire: Wire_Ref) !void {
    var maybe_group: ?usize = null;

    var iter = wire.iterator();
    while (iter.next()) |segment| {
        if (segment.get_label()) |label| {
            if (maybe_group == null) {
                try self.groups.ensureUnusedCapacity(self.gpa, 1);
            }

            const gop = try self.label_text_lookup.getOrPut(self.gpa, label.text);
            if (gop.found_existing) {
                if (maybe_group) |group| {
                    if (group != gop.value_ptr.*) {
                        try self.merge_groups(group, gop.value_ptr.*);
                        gop.value_ptr.* = group;
                    }
                } else {
                    maybe_group = gop.value_ptr.*;
                }
            } else {
                gop.key_ptr.* = label.text;
                if (maybe_group) |group| {
                    gop.value_ptr.* = group;
                } else {
                    gop.value_ptr.* = self.groups.items.len;
                    maybe_group = self.groups.items.len;
                    self.groups.appendAssumeCapacity(.empty);
                }
            }
        }
    }

    const group = maybe_group orelse g: {
        const group = self.groups.items.len;
        try self.groups.append(self.gpa, .empty);
        break :g group;
    };

    try self.groups.items[group].add_wire(self.gpa, wire);
    try self.wire_lookup.put(self.gpa, wire, group);
}

fn process_wire_junctions(self: *Wire_Groups, wire: Wire_Ref) !void {
    const dir = wire.options().dir;
    
    var final_segment = wire;
    var iter = wire.iterator();
    while (iter.next()) |segment| {
        final_segment = segment;

        if (segment.get_label()) |label| {
            const group = self.wire_lookup.get(wire).?;
            try self.groups.items[group].add_label(self.gpa, label);
            try self.label_lookup.put(self.gpa, label, group);
        }
    }

    if (dir.begin() == .junction) {
        try self.process_junction(wire.begin(), wire);
    }
    if (dir.end() == .junction) try self.process_junction(final_segment.end(), wire);
}

fn process_junction(self: *Wire_Groups, point: Point_Ref, wire: Wire_Ref) !void {
    const x = point._x.*;
    const y = point._y.*;

    for (0.., self.groups.items) |g, group_contents| {
        for (group_contents.wires.items) |w| {
            if (w.eql(wire)) continue;
            if (w.contains_point(x, y)) {
                const wire_g = self.wire_lookup.get(wire).?;
                if (wire_g != g) {
                    try self.merge_groups(wire_g, g);
                    break;
                }
            }
        }
    }
}

fn merge_groups(self: *Wire_Groups, dest: usize, src: usize) !void {
    std.debug.assert(dest != src);
    const groups = self.groups.items;
    try groups[dest].wires.ensureUnusedCapacity(self.gpa, groups[src].wires.items.len);
    try groups[dest].labels.ensureUnusedCapacity(self.gpa, groups[src].labels.items.len);
    for (groups[src].wires.items) |src_wire| groups[dest].wires.appendAssumeCapacity(src_wire);
    for (groups[src].labels.items) |src_label| groups[dest].labels.appendAssumeCapacity(src_label);
    groups[src].wires.clearAndFree(self.gpa);
    groups[src].labels.clearAndFree(self.gpa);

    {
        var iter = self.label_text_lookup.iterator();
        while (iter.next()) |entry| {
            if (entry.value_ptr.* == src) {
                entry.value_ptr.* = dest;
            }
        }
    }
    {
        var iter = self.label_lookup.iterator();
        while (iter.next()) |entry| {
            if (entry.value_ptr.* == src) {
                entry.value_ptr.* = dest;
            }
        }
    }
    {
        var iter = self.wire_lookup.iterator();
        while (iter.next()) |entry| {
            if (entry.value_ptr.* == src) {
                entry.value_ptr.* = dest;
            }
        }
    }
}

const Wire_Groups = @This();

const Label = @import("Label.zig");
const Point_Ref = @import("Point_Ref.zig");
const Drawing_State = @import("Drawing_State.zig");
const Wire_Ref = wires.Wire_Ref;
const wires = @import("wires.zig");
const deep_hash_map = @import("deep_hash_map");
const std = @import("std");
