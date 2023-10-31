const std = @import("std");

pub fn build(b: *std.Build) void {
    const deep_hash_map = b.dependency("Zig-DeepHashMap", .{}).module("deep_hash_map");

    _ = b.addModule("zbox", .{
        .source_file = .{ .path = "zbox.zig" },
        .dependencies = &.{
            .{ .name = "deep_hash_map", .module = deep_hash_map },
        },
    });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "zbox.zig"},
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
    tests.addModule("deep_hash_map", deep_hash_map);
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_tests.step);

}
