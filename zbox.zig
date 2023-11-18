pub const wires = @import("zbox/wires.zig");
pub const values = @import("zbox/values.zig");

pub const Drawing = @import("zbox/Drawing.zig");

pub const X_Ref = @import("zbox/X_Ref.zig");
pub const Y_Ref = @import("zbox/Y_Ref.zig");
pub const Point_Ref = @import("zbox/Point_Ref.zig");
pub const X_Ref_Cluster = @import("zbox/X_Ref_Cluster.zig");
pub const Y_Ref_Cluster = @import("zbox/Y_Ref_Cluster.zig");

pub const Box = @import("zbox/Box.zig");
pub const Label = @import("zbox/Label.zig");

pub const Wire_H = @import("zbox/Wire_H.zig");
pub const Wire_V = @import("zbox/Wire_V.zig");

pub const Separator_H = @import("zbox/Separator_H.zig");
pub const Separator_V = @import("zbox/Separator_V.zig");

test "example" {
    var d = Drawing.init(std.testing.allocator);
    defer d.deinit();

    d.title = "Test";
    d.desc = "some descriptive words";

    const b = d.box(.{ .label = "Hello\nWorld" })
        .top_label(.left, "ASDF")
        .bottom_label(.right, "123abc")
        ;

    _ = b.size(300, 400);

    _ = b.right_side("CLK");
    _ = b.right_side("D0");
    _ = b.right_side("D3");
    _ = b.right_side("");

    const asdf = b.left_side("asdf").wire_h(.{}).length(-50);
    _ = asdf.turn()
        .turn_at_offset(b.top(), -50)
        .turn_at_offset(b.right(), 50)
        .turn_and_end_at(b.right_side("asdf"))
        ;

    _ = asdf.turn().turn().y()
        .wire(.{ .dir = .junction_begin })
        .end_at_point(b.top_side("asdf"))
        ;

    const small = d.box(.{ .shape = .small, .label = "^1" });
    _ = small.top_left().attach_to_offset(b.top_right(), 300, 0);

    const mux = d.box(.{ .shape = .mux });
    _ = mux.top_center().attach_to_offset(small.bottom_center(), 0, 50);

    const demux = d.box(.{ .shape = .demux });
    _ = demux.middle_left().attach_to_offset(mux.middle_right(), 50, 0);

    _ = b.top_side("asd");
    _ = b.top_side("asd2");
    _ = b.top_side("asd3");
    _ = b.bottom_side("Hello World!");
    _ = b.bottom_side("Hellorld!");

    const b2 = d.box(.{});

    _ = b2.left().attach_to_offset(b.right(), 150);
    _ = b2.bottom().attach_to(b.bottom());


    const halfway = d.some_x().attach_between(b.right(), b2.left(), 0.5);

    const sep = d.separator_v();
    _ = sep.x().attach_to(halfway);

    _ = sep.label(d.y(0), "asdf1", .{});
    _ = sep.label(d.y(0), "asdf2", .{ .baseline = .hanging });

    const cols = d.columns();
    _ = cols.center().attach_between(b.right(), b2.left(), 0.5);

    _ = b.right_side("D4")
        .wire_h(.{ .bits = 32, .dir = .reverse })
        .bit_mark()
        .turn_at(cols.push())
        .bit_mark()
        .label("D4", .{ .baseline = .hanging, .alignment = .right })
        .turn_and_end_at(b2.left_side("IN"));

    _ = b.right_side("D5")
        .wire_h(.{ .dir = .junction_both })
        .turn_at(cols.push())
        .bit_mark_at(0.2)
        .label("D5", .{})
        .turn_and_end_at(b2.left_side("IN2"));

    _ = b2.left_side("aaa")
        .wire_h(.{})
        .bit_mark()
        .end_at_mutable_point(b.right_side("qqq"));

    cols.interface.flip();

    const b3 = d.box(.{});
    _ = b2.bottom_right().attach(b3.bottom_left());

    const bus = d.point()
        .attach_to_offset(b.bottom_left(), 0, 100)
        .wire_h(.{ .bits = 16 })
        .bit_mark()
        ;

    const bus2 = bus.continue_at(b.right()).end_at(b3.right());

    _ = bus.endpoint()
        .wire_v(.{ .bits = 16, .dir = .junction_begin })
        .turn()
        .end_at_point(bus2.endpoint().offset(0, 100));

    _ = bus.label("Hellorld", .{ .baseline = .middle, .alignment = .right });
    _ = bus2.label("Hello", .{});
    _ = bus2.label("fasdf", .{ .baseline = .middle, .alignment = .left });

    _ = bus.y().wire(.{ .dir = .forward }).end_at_point(b2.bottom_side("ABC"));
    _ = bus.y().wire(.{ .dir = .reverse }).end_at_point(b2.bottom_side("DEF"));
    _ = b3.bottom_side("XYZ").wire_v(.{ .dir = .forward }).end_at(bus.y());
    _ = b3.bottom_side("123").wire_v(.{ .dir = .reverse }).end_at(bus.y());


    var f = try std.fs.cwd().createFile("test.svg", .{});
    defer f.close();
    try d.render_svg(f.writer());

    //try d.state.debug(std.io.getStdErr().writer());
}

const std = @import("std");