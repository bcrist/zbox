/// A standard topological sort
pub fn sort(arena: std.mem.Allocator, state: *const Drawing_State, constraints: []Constraint) !void {
    var open_nodes = Open_Node_List.initCapacity(arena, constraints.len) catch @panic("OOM");
    const nodes = init_nodes(arena, constraints, &open_nodes);

    var out_index: usize = 0;
    while (open_nodes.items.len > 0) {
        var node = open_nodes.pop().?;

        std.debug.assert(node.antecedents.len == 0);

        constraints[out_index] = node.constraint;
        out_index += 1;

        for (node.successors) |successor| {
            successor.remove_antecedent(node);
            if (successor.antecedents.len == 0) {
                open_nodes.appendAssumeCapacity(successor);
            }
        }
        node.successors.len = 0;
    }

    if (out_index != constraints.len) {
        var visited = std.ArrayList(*Node).initCapacity(arena, nodes.len) catch return;
        defer visited.deinit(arena);
        for (nodes) |*node| {
            if (node.successors.len == 0) continue;
            if (log_cycle(node, state, &visited)) break;
        }
        return error.CyclicDependency;
    }
}

fn init_nodes(arena: std.mem.Allocator, constraints: []Constraint, open_nodes: *Open_Node_List) []Node {
    const nodes = arena.alloc(Node, constraints.len) catch @panic("OOM");
    var ptr_to_node = ShallowAutoHashMap(*const f64, *Node).init(arena);

    for (constraints, nodes) |constraint, *node| {
        node.constraint = constraint;
        node.antecedents = arena.alloc(*Node, constraint.op.deps().len) catch @panic("OOM");
        node.antecedents.len = 0;
        node.successors = &.{};
        ptr_to_node.put(constraint.dest, node) catch @panic("OOM");
    }

    for (constraints) |constraint| {
        for (constraint.op.deps()) |ptr| {
            if (ptr_to_node.get(ptr)) |antecedent| {
                antecedent.successors.len += 1;
            }
        }
    }

    for (nodes) |*node| {
        const successors = node.successors.len;
        if (successors > 0) {
            node.successors = arena.alloc(*Node, successors) catch @panic("OOM");
            node.successors.len = 0;
        }
    }

    for (constraints, nodes) |constraint, *node| {
        for (constraint.op.deps()) |ptr| {
            if (ptr_to_node.get(ptr)) |antecedent| {
                node.add_antecedent(antecedent);
                antecedent.add_successor(node);
            }
        }
        if (node.antecedents.len == 0) {
            open_nodes.appendAssumeCapacity(node);
        }
    }

    return nodes;
}

fn log_cycle(node: *Node, state: *const Drawing_State, visited: *std.ArrayList(*Node)) bool {
    for (0.., visited.items) |i, antecedent| {
        if (node == antecedent) {
            log.err("Cycle: {f}", .{ antecedent.constraint.formatter(state) });
            for (visited.items[i + 1 ..]) |s| {
                log.err("    -> {f}", .{ s.constraint.formatter(state) });
            }
            log.err("    -> (repeat)", .{});
            return true;
        }
    }
    visited.appendAssumeCapacity(node);
    defer visited.items.len -= 1;

    for (node.successors) |successor| {
        if (log_cycle(successor, state, visited)) return true;
    }

    return false;
}

const Node = struct {
    constraint: Constraint,
    antecedents: []*Node,
    successors: []*Node,

    pub fn add_antecedent(self: *Node, antecedent: *Node) void {
        self.antecedents.len += 1;
        self.antecedents[self.antecedents.len - 1] = antecedent;
    }

    pub fn remove_antecedent(self: *Node, antecedent: *Node) void {
        for (0.., self.antecedents) |i, node| {
            if (node == antecedent) {
                self.antecedents[i] = self.antecedents[self.antecedents.len - 1];
                self.antecedents.len -= 1;
                return;
            }
        }
        std.debug.assert(false); // antecedent not found
    }

    pub fn add_successor(self: *Node, successor: *Node) void {
        self.successors.len += 1;
        self.successors[self.successors.len - 1] = successor;
    }

};

const log = std.log.scoped(.kahn);

const Open_Node_List = std.ArrayListUnmanaged(*Node);
const Constraint = @import("Constraint.zig");
const Drawing_State = @import("Drawing_State.zig");
const ShallowAutoHashMap = @import("deep_hash_map").ShallowAutoHashMap;
const std = @import("std");
