const std = @import("std");

pub fn build(b: *std.Build) void {
    const deep_hash_map = b.dependency("Zig-DeepHashMap", .{}).module("deep_hash_map");

    const zbox = b.addModule("zbox", .{
        .root_source_file = .{ .path = "zbox.zig" },
    });
    zbox.addImport("deep_hash_map", deep_hash_map);

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "zbox.zig"},
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
    tests.root_module.addImport("deep_hash_map", deep_hash_map);
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_tests.step);
}
