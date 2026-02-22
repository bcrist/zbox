writer: *std.Io.Writer,
cursor: ?struct {
    last_command: u8,
    x: f64,
    y: f64,
},

pub fn init(w: *std.Io.Writer) !Path_Builder {
    try w.writeAll("<path d=\"");
    return .{
        .writer = w,
        .cursor = null,
    };
}

pub fn finish(self: *Path_Builder) !void {
    try self.writer.writeAll("\"/>\n");
    self.writer = undefined;
    self.cursor = null;
}

pub fn class(self: *Path_Builder, classname: []const u8) !void {
    if (classname.len == 0) return;

    if (self.cursor) |cursor| {
        if (cursor.last_command == '_') {
            try self.writer.print(" {s}", .{ classname });
            return;
        }
    }

    try self.writer.print("\" class=\"{s}", .{ classname });
    self.cursor = .{
        .last_command = '_',
        .x = 0,
        .y = 0,
    };
}

pub fn move_to(self: *Path_Builder, x: f64, y: f64) !void {
    try self.writer.print("M {d},{d} ", .{ x, y });
    self.cursor = .{
        .last_command = 'M',
        .x = x,
        .y = y,
    };
}

pub fn move_rel(self: *Path_Builder, dx: f64, dy: f64) !void {
    const current = self.cursor.?;
    try self.writer.print("m {d},{d} ", .{ dx, dy });
    self.cursor = .{
        .last_command = 'm',
        .x = current.x + dx,
        .y = current.y + dy,
    };
}

pub fn line_to(self: *Path_Builder, x: f64, y: f64) !void {
    if (self.cursor) |cursor| {
        if (cursor.x == x and cursor.y == y) return;

        if (cursor.last_command == 'M' or cursor.last_command == 'L') {
            try self.writer.print("{d},{d} ", .{ x, y });
            self.cursor = .{
                .last_command = 'L',
                .x = x,
                .y = y,
            };
            return;
        }

        if (cursor.x == x) {
            try self.writer.print("V {d} ", .{ y });
            self.cursor = .{
                .last_command = 'V',
                .x = x,
                .y = y,
            };
            return;
        }

        if (cursor.y == y) {
            try self.writer.print("H {d} ", .{ x });
            self.cursor = .{
                .last_command = 'H',
                .x = x,
                .y = y,
            };
            return;
        }
    }
    try self.writer.print("L {d},{d} ", .{ x, y });
    self.cursor = .{
        .last_command = 'L',
        .x = x,
        .y = y,
    };
}

pub fn line_rel(self: *Path_Builder, dx: f64, dy: f64) !void {
    if (dx == 0 and dy == 0) return;

    const current = self.cursor.?;
    if (current.last_command == 'm' or current.last_command == 'l') {
        try self.writer.print("{d},{d} ", .{ dx, dy });
        self.cursor = .{
            .last_command = 'l',
            .x = current.x + dx,
            .y = current.y + dy,
        };
        return;
    }
    if (dx == 0) {
        try self.writer.print("v {d} ", .{ dy });
        self.cursor = .{
            .last_command = 'v',
            .x = current.x,
            .y = current.y + dy,
        };
        return;
    }
    if (dy == 0) {
        try self.writer.print("h {d} ", .{ dx });
        self.cursor = .{
            .last_command = 'h',
            .x = current.x + dx,
            .y = current.y,
        };
        return;
    }
    try self.writer.print("l {d},{d} ", .{ dx, dy });
    self.cursor = .{
        .last_command = 'l',
        .x = current.x + dx,
        .y = current.y + dy,
    };
}

const Arc_Options = struct {
    radius: ?f64 = null,
    radius_x: ?f64 = null,
    radius_y: ?f64 = null,
    rotation_degrees: f64 = 0,
    kind: enum (u1) {
        small_arc = 0,
        large_arc = 1,
    } = .small_arc,
    direction: enum (u1) {
        ccw = 0,
        cw = 1,
    } = .cw,
};
pub fn arc_to(self: *Path_Builder, x: f64, y: f64, options: Arc_Options) !void {
    if (self.cursor) |cursor| {
        if (cursor.x == x and cursor.y == y) return;

        const dx = cursor.x - x;
        const dy = cursor.y - y;
        const dist = @sqrt(dx * dx + dy * dy);

        const radius_x = options.radius_x orelse options.radius orelse dist;
        const radius_y = options.radius_y orelse options.radius orelse dist;

        if (cursor.last_command == 'A') {
            try self.writer.print("{d} {d} {d} {d} {d} {d} {d} ", .{
                radius_x,
                radius_y,
                options.rotation_degrees,
                @intFromEnum(options.kind),
                @intFromEnum(options.direction),
                x,
                y,
            });
            self.cursor = .{
                .last_command = 'A',
                .x = x,
                .y = y,
            };
            return;
        }
    }

    const radius_x = options.radius_x orelse options.radius orelse 1;
    const radius_y = options.radius_y orelse options.radius orelse 1;

    try self.writer.print("A {d} {d} {d} {d} {d} {d} {d} ", .{
        radius_x,
        radius_y,
        options.rotation_degrees,
        @intFromEnum(options.kind),
        @intFromEnum(options.direction),
        x,
        y,
    });
    self.cursor = .{
        .last_command = 'A',
        .x = x,
        .y = y,
    };
}

pub fn arc_rel(self: *Path_Builder, dx: f64, dy: f64, options: Arc_Options) !void {
    if (dx == 0 and dy == 0) return;

    const current = self.cursor.?;

    const dist = @sqrt(dx * dx + dy * dy);

    const radius_x = options.radius_x orelse options.radius orelse dist;
    const radius_y = options.radius_y orelse options.radius orelse dist;

    if (current.last_command == 'a') {
        try self.writer.print("{d} {d} {d} {d} {d} {d} {d} ", .{
            radius_x,
            radius_y,
            options.rotation_degrees,
            @intFromEnum(options.kind),
            @intFromEnum(options.direction),
            dx,
            dy,
        });
    } else {
        try self.writer.print("a {d} {d} {d} {d} {d} {d} {d} ", .{
            radius_x,
            radius_y,
            options.rotation_degrees,
            @intFromEnum(options.kind),
            @intFromEnum(options.direction),
            dx,
            dy,
        });
    }
    self.cursor = .{
        .last_command = 'a',
        .x = current.x + dx,
        .y = current.y + dy,
    };
}

pub fn close(self: *Path_Builder) !void {
    try self.writer.writeAll("Z ");
    self.cursor = null;
}

const Path_Builder = @This();


const std = @import("std");
