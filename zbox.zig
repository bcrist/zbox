pub const wires = @import("zbox/wires.zig");
pub const values = @import("zbox/values.zig");

pub const Drawing = @import("zbox/Drawing.zig");

pub const XRef = @import("zbox/XRef.zig");
pub const YRef = @import("zbox/YRef.zig");
pub const PointRef = @import("zbox/PointRef.zig");
pub const XRefCluster = @import("zbox/XRefCluster.zig");
pub const YRefCluster = @import("zbox/YRefCluster.zig");

pub const Box = @import("zbox/Box.zig");
pub const Label = @import("zbox/Label.zig");

pub const WireH = @import("zbox/WireH.zig");
pub const WireV = @import("zbox/WireV.zig");

pub const SeparatorH = @import("zbox/SeparatorH.zig");
pub const SeparatorV = @import("zbox/SeparatorV.zig");

test "example" {
    var d = Drawing.init(std.testing.allocator);
    defer d.deinit();

    d.title = "Test";
    d.desc = "some descriptive words";

    const b = d.box(.{ .label = "Hello\nWorld" })
        .topLabel(.left, "ASDF")
        .bottomLabel(.right, "123abc")
        ;

    _ = b.size(300, 400);

    _ = b.rightSide("CLK");
    _ = b.rightSide("D0");
    _ = b.rightSide("D3");
    _ = b.rightSide("");

    const asdf = b.leftSide("asdf").wireH(.{}).length(-50);
    _ = asdf.turn()
        .turnAtOffset(b.top(), -50)
        .turnAtOffset(b.right(), 50)
        .turnAndEndAt(b.rightSide("asdf"))
        ;

    _ = asdf.turn().turn().y()
        .wire(.{ .dir = .junction_begin })
        .endAtPoint(b.topSide("asdf"))
        ;

    const small = d.box(.{ .shape = .small, .label = "^1" });
    _ = small.topLeft().attachToOffset(b.topRight(), 300, 0);

    const mux = d.box(.{ .shape = .mux });
    _ = mux.topCenter().attachToOffset(small.bottomCenter(), 0, 50);

    const demux = d.box(.{ .shape = .demux });
    _ = demux.middleLeft().attachToOffset(mux.middleRight(), 50, 0);

    _ = b.topSide("asd");
    _ = b.topSide("asd2");
    _ = b.topSide("asd3");
    _ = b.bottomSide("Hello World!");
    _ = b.bottomSide("Hellorld!");

    const b2 = d.box(.{});

    _ = b2.left().attachToOffset(b.right(), 150);
    _ = b2.bottom().attachTo(b.bottom());


    const halfway = d.someX().attachBetween(b.right(), b2.left(), 0.5);

    const sep = d.separatorV();
    _ = sep.x().attachTo(halfway);

    _ = sep.label(d.y(0), "asdf1", .{});
    _ = sep.label(d.y(0), "asdf2", .{ .baseline = .hanging });

    const cols = d.columns();
    _ = cols.center().attachBetween(b.right(), b2.left(), 0.5);

    _ = b.rightSide("D4")
        .wireH(.{ .bits = 32, .dir = .reverse })
        .bitMark()
        .turnAt(cols.push())
        .bitMark()
        .label("D4", .{ .baseline = .hanging, .alignment = .right })
        .turnAndEndAt(b2.leftSide("IN"));

    _ = b.rightSide("D5")
        .wireH(.{ .dir = .junction_both })
        .turnAt(cols.push())
        .bitMarkAt(0.2)
        .label("D5", .{})
        .turnAndEndAt(b2.leftSide("IN2"));

    _ = b2.leftSide("aaa")
        .wireH(.{})
        .bitMark()
        .endAtMutablePoint(b.rightSide("qqq"));

    cols.interface.flip();

    const b3 = d.box(.{});
    _ = b2.bottomRight().attach(b3.bottomLeft());

    const bus = d.point()
        .attachToOffset(b.bottomLeft(), 0, 100)
        .wireH(.{ .bits = 16 })
        .bitMark()
        ;

    const bus2 = bus.continueAt(b.right()).endAt(b3.right());

    _ = bus.endpoint()
        .wireV(.{ .bits = 16, .dir = .junction_begin })
        .turn()
        .endAtPoint(bus2.endpoint().offset(0, 100));

    _ = bus.label("Hellorld", .{ .baseline = .middle, .alignment = .right });
    _ = bus2.label("Hello", .{});
    _ = bus2.label("fasdf", .{ .baseline = .middle, .alignment = .left });

    _ = bus.y().wire(.{ .dir = .forward }).endAtPoint(b2.bottomSide("ABC"));
    _ = bus.y().wire(.{ .dir = .reverse }).endAtPoint(b2.bottomSide("DEF"));
    _ = b3.bottomSide("XYZ").wireV(.{ .dir = .forward }).endAt(bus.y());
    _ = b3.bottomSide("123").wireV(.{ .dir = .reverse }).endAt(bus.y());


    var f = try std.fs.cwd().createFile("test.svg", .{});
    defer f.close();
    try d.renderSvg(f.writer());

    //try d.state.debug(std.io.getStdErr().writer());
}

const std = @import("std");