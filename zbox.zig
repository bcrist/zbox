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

    

    _ = b.topSide("asd");
    _ = b.topSide("asd2");
    _ = b.topSide("asd3");
    _ = b.bottomSide("Hello World!");
    _ = b.bottomSide("Hellorld!");

    const b2 = d.box();

    _ = b2.left().attachToOffset(b.right(), 150);
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

    _ = b2.leftSide("aaa")
        .wireH(.{})
        .bitMark()
        .endAtMutablePoint(b.rightSide("qqq"));

    cols.interface.flip();

    const b3 = d.box();
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

    _ = bus.labelLeft("Hellorld");
    _ = bus2.labelAbove(.left, "Hello");
    _ = bus2.labelRight("fasdf");

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