/// A standard topological sort
pub fn sort(arena: std.mem.Allocator, constraints: []Constraint) !void {
    var open_nodes = OpenNodeList.initCapacity(arena, constraints.len) catch @panic("OOM");
    const nodes = initNodes(arena, constraints, &open_nodes);
    _ = nodes;

    var out_index: usize = 0;
    while (open_nodes.items.len > 0) {
        var node = open_nodes.pop();

        std.debug.assert(node.antecedents.len == 0);

        constraints[out_index] = node.constraint;
        out_index += 1;

        for (node.successors) |successor| {
            successor.removeAntecedent(node);
            if (successor.antecedents.len == 0) {
                open_nodes.appendAssumeCapacity(successor);
            }
        }
        node.successors.len = 0;
    }

    if (out_index != constraints.len) {
        return error.CyclicDependency;
    }
}

fn initNodes(arena: std.mem.Allocator, constraints: []Constraint, open_nodes: *OpenNodeList) []Node {
    var nodes = arena.alloc(Node, constraints.len) catch @panic("OOM");
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
                node.addAntecedent(antecedent);
                antecedent.addSuccessor(node);
            }
        }
        if (node.antecedents.len == 0) {
            open_nodes.appendAssumeCapacity(node);
        }
    }

    return nodes;
}

const Node = struct {
    constraint: Constraint,
    antecedents: []*Node,
    successors: []*Node,

    pub fn addAntecedent(self: *Node, antecedent: *Node) void {
        self.antecedents.len += 1;
        self.antecedents[self.antecedents.len - 1] = antecedent;
    }

    pub fn removeAntecedent(self: *Node, antecedent: *Node) void {
        for (0.., self.antecedents) |i, node| {
            if (node == antecedent) {
                self.antecedents[i] = self.antecedents[self.antecedents.len - 1];
                self.antecedents.len -= 1;
                return;
            }
        }
        std.debug.assert(false); // antecedent not found
    }

    pub fn addSuccessor(self: *Node, successor: *Node) void {
        self.successors.len += 1;
        self.successors[self.successors.len - 1] = successor;
    }

};

const OpenNodeList = std.ArrayListUnmanaged(*Node);
const Constraint = @import("Constraint.zig");
const ShallowAutoHashMap = @import("deep_hash_map").ShallowAutoHashMap;
const std = @import("std");
