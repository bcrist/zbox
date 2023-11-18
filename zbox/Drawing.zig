state: Drawing_State,
style: Style = .{},
title: []const u8 = "",
desc: []const u8 = "",
view: Viewport = .{},

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

pub fn label(self: *Drawing, class: []const u8, alignment: Label.Alignment, baseline: Label.Baseline, text: []const u8) *Label {
    return self.state.create_label(text, class, alignment, baseline, 0);
}
pub fn label_v(self: *Drawing, class: []const u8, alignment: Label.Alignment, baseline: Label.Baseline, text: []const u8) *Label {
    return self.state.create_label(text, class, alignment, baseline, -90);
}

pub fn box(self: *Drawing, options: Box.Options) *Box {
    return self.state.create_box(options);
}

// TODO cubic beziers - "swoopWest/East/North/South"
// ends with "endWestAt/EastAt/NorthAt/SouthAt(Point_Ref)

// TODO Grouping rectangles
// TODO Circles (for state diagrams)
// TODO and gates
// TODO or gates
// TODO xor gates
// TODO buffers/inverters
// TODO transmission gates
// TODO muxes & demuxes
// TODO ALU blocks
// TODO bus line driver blocks
// TODO bus/wire swap block
// TODO flowchart shapes
// TODO memory layout/protocol diagrams
// TODO simple tables
// TODO railroad diagrams?

pub fn separator_h(self: *Drawing) *Separator_H {
    return self.state.create_separator_h();
}

pub fn separator_v(self: *Drawing) *Separator_V {
    return self.state.create_separator_v();
}

pub fn columns(self: *Drawing) *X_Ref_Cluster {
    return self.state.create_x_ref_cluster();
}
pub fn rows(self: *Drawing) *Y_Ref_Cluster {
    return self.state.create_y_ref_cluster();
}

pub fn wire_h(self: *Drawing, options: wires.Options) *Wire_H {
    return self.state.create_wire_h(options, null);
}

pub fn wire_v(self: *Drawing, options: wires.Options) *Wire_V {
    return self.state.create_wire_v(options, null);
}

pub fn at(self: *Drawing, abs_x: f64, abs_y: f64) Point_Ref {
    return .{
        .state = &self.state,
        ._x = self.state.create_value(abs_x),
        ._y = self.state.create_value(abs_y),
        .mut_x = false,
        .mut_y = false,
    };
}

pub fn point(self: *Drawing) Point_Ref {
    return .{
        .state = &self.state,
        ._x = self.state.create_value(values.uninitialized),
        ._y = self.state.create_value(values.uninitialized),
    };
}

pub fn x(self: *Drawing, abs_x: f64) X_Ref {
    return .{
        .state = &self.state,
        ._x = self.state.create_value(abs_x),
        .mut = false,
    };
}

pub fn some_x(self: *Drawing) X_Ref {
    return .{
        .state = &self.state,
        ._x = self.state.create_value(values.uninitialized),
    };
}

pub fn between_x(self: *Drawing, a: X_Ref, b: X_Ref, f: f64) X_Ref {
    const item = self.state.create_value(values.uninitialized);
    self.state.constrain_lerp(item, a._x, b._x, f, "between_x");
    return .{
        .state = &self.state,
        ._x = item,
        .mut = false,
    };
}

pub fn y(self: *Drawing, abs_y: f64) Y_Ref {
    return .{
        .state = &self.state,
        ._y = self.state.create_value(abs_y),
        .mut = false,
    };
}

pub fn some_y(self: *Drawing) Y_Ref {
    return .{
        .state = &self.state,
        ._y = self.state.create_value(values.uninitialized),
    };
}

pub fn between_y(self: *Drawing, a: Y_Ref, b: Y_Ref, f: f64) Y_Ref {
    const item = self.state.create_value(values.uninitialized);
    self.state.constrain_lerp(item, a._y, b._y, f, "between_y");
    return .{
        .state = &self.state,
        ._y = item,
        .mut = false,
    };
}

pub fn render_svg(self: *Drawing, writer: anytype) !void {
    self.state.add_missing_constraints();
    try self.state.resolve_constraints();

    const computed_view = self.compute_viewport();
    const view: Viewport = .{
        .left = self.view.left orelse computed_view.left,
        .right = self.view.right orelse computed_view.right,
        .top = self.view.top orelse computed_view.top,
        .bottom = self.view.bottom orelse computed_view.bottom,
    };

    try writer.print(
        \\<svg viewBox="{d} {d} {d} {d}" xmlns="http://www.w3.org/2000/svg">
        \\
    , .{
        view.left orelse 0, view.top orelse 0,
        view.width(), view.height(),
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

    try writer.print(
        \\<style>
        \\{s}
        \\{s}
        \\</style>
        \\
    , .{ self.style.base_css, self.style.extra_css });

    for (self.state.separators_h.items) |s| {
        try writer.print(
            \\<line x1="{d}" y1="{d}" x2="{d}" y2="{d}" class="{s} sep"/>
            \\
        , .{
            view.left.?, s._y,
            view.right.?, s._y,
            s.class,
        });
    }
    for (self.state.separators_v.items) |s| {
        try writer.print(
            \\<line x1="{d}" y1="{d}" x2="{d}" y2="{d}" class="{s} sep"/>
            \\
        , .{
            s._x, view.top.?,
            s._x, view.bottom.?,
            s.class,
        });
    }

    for (self.state.wires_h.items) |w| {
        try self.render_svg_wire(wires.Wire_Ref.initH(w), writer);
    }
    for (self.state.wires_v.items) |w| {
        try self.render_svg_wire(wires.Wire_Ref.initV(w), writer);
    }

    for (self.state.boxes.items) |b| {
        try self.render_svg_box(b, writer);
    }

    for (self.state.labels.items) |l| {
        try render_svg_label(l._x, l._y, l.text, l.options, writer);
    }

    try writer.writeAll("</svg>");
}

fn render_svg_box(self: *Drawing, b: *Box, writer: anytype) @TypeOf(writer).Error!void {
    switch (b.options.shape) {
        .mux => {
            const dy = b._x.len / 4;
            try writer.print(
                \\<path d="M {d} {d} V {d} L {d} {d} V {d} Z" class="box {s} {s}"/>
                \\
            , .{
                b._x.begin,      // top left x
                b._y.begin - dy, // top left y
                b._y.end + dy,   // bottom left y
                b._x.end,        // bottom right x
                b._y.end - dy,   // bottom right y
                b._y.begin + dy, // top right y
                @tagName(b.options.shape),
                b.options.class,
            });
        },
        .demux => {
            const dy = b._x.len / 4;
            try writer.print(
                \\<path d="M {d} {d} V {d} L {d} {d} V {d} Z" class="box {s} {s}"/>
                \\
            , .{
                b._x.begin,      // top left x
                b._y.begin + dy, // top left y
                b._y.end - dy,   // bottom left y
                b._x.end,        // bottom right x
                b._y.end + dy,   // bottom right y
                b._y.begin - dy, // top right y
                @tagName(b.options.shape),
                b.options.class,
            });
        },
        .block, .small => {
            try writer.print(
                \\<rect x="{d}" y="{d}" width="{d}" height="{d}" class="box {s} {s}"/>
                \\
            , .{
                b._x.min, b._y.min,
                b._x.len, b._y.len,
                @tagName(b.options.shape),
                b.options.class,
            });
        },
    }

    if (b.options.label.len > 0) {
        const n: f64 = @floatFromInt(std.mem.count(u8, b.options.label, "\n"));
        const tx = b._x.mid;
        var ty = b._y.mid - n * self.style.box_label_line_height / 2;

        var iter = std.mem.splitScalar(u8, b.options.label, '\n');
        while (iter.next()) |line| {
            try render_svg_label(tx, ty, line, .{
                .class = b.options.label_class,
                ._class1 = @tagName(b.options.shape),
                ._class2 = "box-label main",
                .alignment = .center,
                .baseline = .middle,
            }, writer);
            ty += self.style.box_label_line_height;
        }
    }
}

fn render_svg_label(lx: f64, ly: f64, text: []const u8, options: Label.Options, writer: anytype) @TypeOf(writer).Error!void {
    try writer.print(
        \\<text x="{d}" y="{d}" class="label _{s}{s}
    , .{
        lx, ly,
        @tagName(options.baseline)[0..1],
        @tagName(options.alignment)[0..1],
    });
    if (options.class.len > 0) try writer.print(" {s}", .{ options.class });
    if (options._class1.len > 0) try writer.print(" {s}", .{ options._class1 });
    if (options._class2.len > 0) try writer.print(" {s}", .{ options._class2 });

    if (options.angle != 0) {
        try writer.print(
            \\" transform-origin="{d} {d}" transform="rotate({d})"
        , .{
            lx, ly,
            options.angle,
        });
    } else {
        try writer.writeByte('"');
    }

    try writer.print(
        \\>{s}</text>
        \\
    , .{ text });
}

fn render_svg_wire(self: *Drawing, wire: wires.Wire_Ref, writer: anytype) @TypeOf(writer).Error!void {
    const options = wire.options();
    const style = if (options.bits > 1) self.style.bus_style else self.style.wire_style;

    var draw_start_arrow = false;
    var draw_end_arrow = false;
    var draw_start_junction = false;
    var draw_end_junction = false;

    switch (options.dir) {
        .none => {},
        .forward => draw_end_arrow = true,
        .junction_end => draw_end_junction = true,
        .reverse => draw_start_arrow = true,
        .junction_begin => draw_start_junction = true,
        .bidirectional => {
            draw_start_arrow = true;
            draw_end_arrow = true;
        },
        .junction_both => {
            draw_start_junction = true;
            draw_end_junction = true;
        },
    }

    switch (wire) {
        .H => |w| try writer.print("<path d=\"M {d} {d} H {d}", .{ w._x.begin, w._y, w._x.end }),
        .V => |w| try writer.print("<path d=\"M {d} {d} V {d}", .{ w._x, w._y.begin, w._y.end }),
    }

    var iter: wires.Iterator = .{ .wire = wire };
    _ = iter.next(); // we already processed ourself
    var final_segment = wire;
    while (iter.next()) |segment| {
        final_segment = segment;
        switch (segment) {
            .H => |w| try writer.print(" H {d}", .{ w._x.end }),
            .V => |w| try writer.print(" V {d}", .{ w._y.end }),
        }
    }

    if (draw_end_arrow) {
        const begin = final_segment.begin();
        const end = final_segment.end();
        const dx = end._x.* - begin._x.*;
        const dy = end._y.* - begin._y.*;
        try render_svg_arrowhead_path(dx, dy, style, writer);
    }

    if (draw_start_arrow) {
        const begin = wire.begin();
        const end = wire.end();
        const dx = begin._x.* - end._x.*;
        const dy = begin._y.* - end._y.*;
        try writer.print(" M {d} {d}", .{ begin._x.*, begin._y.* });
        try render_svg_arrowhead_path(dx, dy, style, writer);
    }

    try writer.writeAll("\" class=\"wire");
    if (options.bits > 1) try writer.writeAll(" bus");
    if (options.class.len > 0) try writer.print(" {s}", .{ options.class });
    try writer.writeAll("\"/>\n");

    iter = .{ .wire = wire };
    while (iter.next()) |segment| {
        if (segment.bit_mark()) |f| {
            const begin = segment.begin();
            const end = segment.end();
            const cx = (1-f)*begin._x.* + f*end._x.*;
            const cy = (1-f)*begin._y.* + f*end._y.*;

            const x0 = cx - style.bit_mark_length / 2;
            const x1 = cx + style.bit_mark_length / 2;

            const y0 = cy + style.bit_mark_length / 2;
            const y1 = cy - style.bit_mark_length / 2;

            try writer.print(
                \\<line x1="{d}" y1="{d}" x2="{d}" y2="{d}" class="wire bitmark
            , .{ x0, y0, x1, y1 });
            if (options.bits > 1) try writer.writeAll(" bus");
            if (options.class.len > 0) try writer.print(" {s}", .{ options.class });
            try writer.writeAll("\"/>\n");

            var buf: [64]u8 = undefined;
            const text = try std.fmt.bufPrint(&buf, "{}", .{ options.bits });

            switch (segment) {
                .H => try render_svg_label(cx, cy + style.bit_mark_label_offset_y, text, .{
                    .alignment = .center,
                    .baseline = .hanging,
                    .class = "bitmark-label",
                }, writer),
                .V => try render_svg_label(cx + style.bit_mark_label_offset_x, cy + style.bit_mark_label_offset_xy, text, .{
                    .alignment = .left,
                    .baseline = .middle,
                    .class = "bitmark-label",
                }, writer),
            }
        }
    }

    if (draw_start_junction) {
        const begin = wire.begin();
        try writer.print(
            \\<circle cx="{d}" cy="{d}" r="{d}" class="wire junction
        , .{ begin._x.*, begin._y.*, style.junction_radius });
        if (options.bits > 1) try writer.writeAll(" bus");
        if (options.class.len > 0) try writer.print(" {s}", .{ options.class });
        try writer.writeAll("\"/>\n");
    }
    

    if (draw_end_junction) {
        const end = final_segment.end();
        try writer.print(
            \\<circle cx="{d}" cy="{d}" r="{d}" class="wire junction
        , .{ end._x.*, end._y.*, style.junction_radius });
        if (options.bits > 1) try writer.writeAll(" bus");
        if (options.class.len > 0) try writer.print(" {s}", .{ options.class });
        try writer.writeAll("\"/>\n");
    }
}

fn render_svg_arrowhead_path(dx: f64, dy: f64, wire_style: Style.Wire_Style, writer: anytype) @TypeOf(writer).Error!void {
    var tangent_x: f64 = if (dx > 0) 1 else if (dx < 0) -1 else 0;
    var tangent_y: f64 = if (dy > 0) 1 else if (dy < 0) -1 else 0;

    var normal_x = tangent_y;
    var normal_y = -tangent_x;

    tangent_x *= wire_style.arrow_length;
    tangent_y *= wire_style.arrow_length;

    normal_x *= wire_style.arrow_width;
    normal_y *= wire_style.arrow_width;

    try writer.print(
        \\ m {d} {d} l {d} {d} l {d} {d}
    , .{
        -tangent_x - normal_x,
        -tangent_y - normal_y,

        tangent_x + normal_x,
        tangent_y + normal_y,

        -tangent_x + normal_x,
        -tangent_y + normal_y,
    });
}

fn compute_viewport(self: *Drawing) Viewport {
    var view: Viewport = .{};

    for (self.state.wires_h.items) |h_wire| {
        var maybe_wire: ?*Wire_H = h_wire;
        while (maybe_wire) |w| {
            view.include_point(w._x.begin, w._y);
            view.include_point(w._x.end, w._y);

            if (w.next) |vw| {
                view.include_point(vw._x, vw._y.begin);
                view.include_point(vw._x, vw._y.end);

                maybe_wire = vw.next;
            } else {
                maybe_wire = null;
            }
        }
    }
    for (self.state.wires_v.items) |v_wire| {
        var maybe_wire: ?*Wire_V = v_wire;
        while (maybe_wire) |w| {
            view.include_point(w._x, w._y.begin);
            view.include_point(w._x, w._y.end);

            if (w.next) |hw| {
                view.include_point(hw._x.begin, hw._y);
                view.include_point(hw._x.end, hw._y);

                maybe_wire = hw.next;
            } else {
                maybe_wire = null;
            }
        }
    }

    for (self.state.boxes.items) |b| {
        view.include_point(b._x.begin, b._y.begin);
        view.include_point(b._x.end, b._y.end);
    }

    for (self.state.labels.items) |l| {
        view.include_point(l._x, l._y);
    }

    view.left = (view.left orelse 0) - self.style.drawing_padding_x;
    view.right = (view.right orelse 0) + self.style.drawing_padding_x;

    view.top = (view.top orelse 0) - self.style.drawing_padding_y;
    view.bottom = (view.bottom orelse 0) + self.style.drawing_padding_y;

    return view;
}

const Drawing = @This();
const Drawing_State = @import("Drawing_State.zig");
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
const Style = @import("Style.zig");
const Viewport = @import("Viewport.zig");
const values = @import("values.zig");
const std = @import("std");
