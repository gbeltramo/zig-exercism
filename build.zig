const std = @import("std");

pub fn build(b: *std.Build) !void {
    const test_step = b.step("test", "Run unit tests in solutions/");
    const opt_num = b.option(u32, "num", "Only run the tests of this target exercise with index `num`.");
    const opt_filter = b.option([]const u8, "filter", "Only run tests whose name contains this string.");

    const solutions_dir = try b.root.openDir(b.graph.io, "solutions/", .{ .iterate = true });
    defer solutions_dir.close(b.graph.io);
    var found_target_num = false;

    var it = solutions_dir.iterate();
    while (try it.next(b.graph.io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;

        if (opt_num) |target_num| {
            const end = std.mem.indexOfScalar(u8, entry.name, '_') orelse continue;
            const current_exercise_num = std.fmt.parseInt(u32, entry.name[0..end], 10) catch continue;
            if (current_exercise_num != target_num) continue;
        }

        found_target_num = true;

        const file_sub_path = b.pathJoin(&.{ "solutions", entry.name });
        const unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(file_sub_path),
                .target = b.graph.host,
                .optimize = .debug,
            }),
            .name = b.fmt("test_{s}", .{entry.name}),
            .filters = if (opt_filter) |f| b.dupeStrings(&.{f}) else &.{},
        });
        test_step.dependOn(&b.addRunArtifact(unit_tests).step);
    }

    if (opt_num != null and !found_target_num) {
        std.log.err("No solution numbered num='{d}' found in solutions/\n", .{opt_num.?});
        return error.SolutionNotFound;
    }
}
