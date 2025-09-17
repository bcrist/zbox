pub fn build(b: *std.Build) void {
    const deep_hash_map = b.dependency("deep_hash_map", .{}).module("deep_hash_map");

    const zbox = b.addModule("zbox", .{
        .root_source_file = b.path("zbox.zig"),
        .imports = &.{
            .{ .name = "deep_hash_map", .module = deep_hash_map },
        },
    });

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests.zig"),
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
            .imports = &.{
                .{ .name = "zbox", .module = zbox },
            },
        }),
    });
    b.step("test", "Run all tests").dependOn(&b.addRunArtifact(tests).step);
}

const std = @import("std");
