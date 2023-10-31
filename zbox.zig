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


    const halfway = d.someX().attachBetween(b.right(), b2.left(), 0.5);

    _ = b.rightSide("D4")
        .wireH(.{ .bits = 2, .dir = .forward })
        .turnAt(halfway)
        .turnAndEndAt(b2.leftSide("IN"));


    const p = d.at(200, 100);
    _ = p;

    var f = try std.fs.cwd().createFile("test.svg", .{});
    defer f.close();
    try d.renderSvg(f.writer());
}

const std = @import("std");