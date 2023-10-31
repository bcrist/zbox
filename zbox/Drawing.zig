state: DrawingState,
style: Style = .{},
title: []const u8 = "",
desc: []const u8 = "",

pub fn init(gpa: std.mem.Allocator) *Drawing {
    const self = gpa.create(Drawing) catch @panic("OOM");
    self.* = .{ .state = .{
        .drawing = self,
        .gpa = gpa,
    }};
    return self;
}
pub fn deinit(self: *Drawing) void {
    const gpa = self.state.gpa;
    self.state.deinit();
    gpa.destroy(self);
}

pub fn box(self: *Drawing) *Box {
    return self.state.createBox(self.style.default_box_class);
}
pub fn columns(self: *Drawing) *XRefCluster {
    return self.state.createXRefCluster();
}
pub fn rows(self: *Drawing) *YRefCluster {
    return self.state.createYRefCluster();
}

pub fn at(self: *Drawing, abs_x: f64, abs_y: f64) PointRef {
    return .{
        .state = &self.state,
        ._x = self.state.createValue(abs_x),
        ._y = self.state.createValue(abs_y),
        .mut_x = false,
        .mut_y = false,
    };
}

pub fn point(self: *Drawing) PointRef {
    return .{
        .state = &self.state,
        ._x = self.state.createValue(values.uninitialized),
        ._y = self.state.createValue(values.uninitialized),
        .mut_x = true,
        .mut_y = true,
    };
}

pub fn x(self: *Drawing, abs_x: f64) XRef {
    return .{
        .state = &self.state,
        ._x = self.state.createValue(abs_x),
        .mut = false,
    };
}

pub fn someX(self: *Drawing) XRef {
    return .{
        .state = &self.state,
        ._x = self.state.createValue(values.uninitialized),
        .mut = true,
    };
}

pub fn y(self: *Drawing, abs_y: f64) YRef {
    return .{
        .state = &self.state,
        ._y = self.state.createValue(abs_y),
        .mut = false,
    };
}

pub fn someY(self: *Drawing) YRef {
    return .{
        .state = &self.state,
        ._y = self.state.createValue(values.uninitialized),
        .mut = true,
    };
}

pub fn renderSvg(self: *Drawing, writer: anytype) !void {
    self.state.addMissingConstraints();
    try self.state.resolveConstraints();

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
    for (self.state.wires_h.items) |w| {
        try self.renderSvgWireH(w, true, w.options, writer);
    }
    for (self.state.wires_v.items) |w| {
        try self.renderSvgWireV(w, true, w.options, writer);
    }

    for (self.state.boxes.items) |b| {
        try writer.print(
            \\<rect x="{d}" y="{d}" width="{d}" height="{d}" class="{s}"/>
            \\
        , .{
            b._x.min, b._y.min,
            b._x.len, b._y.len,
            b.class,
        });
    }

    for (self.state.labels.items) |l| {
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

const Drawing = @This();
const DrawingState = @import("DrawingState.zig");
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
const values = @import("values.zig");
const std = @import("std");
