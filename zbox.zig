pub const Drawing = @import("zbox/Drawing.zig");

test "example" {
    var d = Drawing.init(std.testing.allocator);
    defer d.deinit();

    d.title = "Test";
    d.desc = "some descriptive words";

    const b = d.box()
        .label("Hello World")
        .topLabel(.left, "ASDF")
        .bottomLabel(.right, "123abc")
        ;

    _ = b.size(300, 400);

    _ = b.rightSide("CLK");
    _ = b.rightSide("D0");
    _ = b.rightSide("D1");
    _ = b.rightSide("D2");
    _ = b.rightSide("D3");
    _ = b.rightSide("");

    _ = b.leftSide("asdf");
    _ = b.topSide("asd");
    _ = b.topSide("asd2");
    _ = b.topSide("asd3");
    _ = b.bottomSide("Hello World!");
    _ = b.bottomSide("Hellorld!");

    const b2 = d.box();

    _ = b2.left().attachToOffset(b.right(), 100);
    _ = b2.bottom().attachTo(b.bottom());


    //const halfway = d.someX().attachBetween(b.right(), b2.left(), 0.5);

    const cols = d.columns();
    _ = cols.center().attachBetween(b.right(), b2.left(), 0.5);

    _ = b.rightSide("D4")
        .wireH(.{ .bits = 32, .dir = .reverse })
        .bitMark()
        .turnAt(cols.push())
        .bitMark()
        .labelRight(.right, "D4")
        .turnAndEndAt(b2.leftSide("IN"));

    _ = b.rightSide("D5")
        .wireH(.{ .dir = .junction_both })
        .turnAt(cols.push())
        .bitMarkAt(0.2)
        .labelLeft(.left, "D5")
        .turnAndEndAt(b2.leftSide("IN2"));

    _ = b2.leftSide("X")
        .wireH(.{})
        .bitMark()
        .endAtMutablePoint(b.rightSide("X"));
    _ = b2.leftSide("X")
        .wireH(.{})
        .endAtMutablePoint(b.rightSide("X"));

    cols.interface.flip();

    const b3 = d.box();
    _ = b2.bottomRight().attach(b3.bottomLeft());

    const bus = d.point()
        .attachToOffset(b.bottomLeft(), 0, 100)
        .wireH(.{ .bits = 16 })
        .endAt(b3.right())
        ;

    _ = bus.labelAbove(.left, "Hello");
    _ = bus.labelLeft("Hellorld");
    _ = bus.labelRight("fasdf");

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