const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const flower_tile: u8 = '*';

pub fn Matrix(comptime T: type) type {
    return struct {
        num_rows: usize,
        num_cols: usize,
        data: []T,

        pub fn init(allocator: mem.Allocator, num_rows: usize, num_cols: usize) !Matrix(T) {
            return .{
                .num_rows = num_rows,
                .num_cols = num_cols,
                .data = try allocator.alloc(T, num_rows * num_cols),
            };
        }

        pub fn deinit(self: Matrix(T), allocator: mem.Allocator) void {
            allocator.free(self.data);
        }

        pub fn get(self: Matrix(T), i: usize, j: usize) T {
            return self.data[i * self.num_cols + j];
        }

        pub fn set(self: Matrix(T), i: usize, j: usize, new_value: T) void {
            self.data[i * self.num_cols + j] = new_value;
        }

        pub fn debugPrint(self: Matrix(T)) void {
            for (0..self.num_rows) |i| {
                std.debug.print("[", .{});
                for (0..self.num_cols) |j| {
                    std.debug.print("{d}", .{self.get(i, j)});
                    if (j != (self.num_cols - 1)) std.debug.print(" ", .{});
                }
                std.debug.print("]\n", .{});
            }
        }
    };
}

pub fn annotate(allocator: mem.Allocator, garden: []const []const u8) mem.Allocator.Error![][]u8 {
    if (garden.len == 0) {
        const out_garden = try allocator.alloc([]u8, 0);
        errdefer allocator.free(out_garden);
        return out_garden;
    } else if (garden.len == 1) {
        const out_garden = try allocator.alloc([]u8, 1);
        errdefer allocator.free(out_garden);
        const out_row = try allocator.alloc(u8, garden[0].len);
        errdefer allocator.free(out_row);
        for (0..out_row.len) |idx| out_row[idx] = garden[0][idx];

        for (0..out_row.len) |idx| {
            const tile = garden[0][idx];
            if (tile == flower_tile) {
                if (idx > 0) {
                    const idx_prev = idx - 1;
                    const prev_tile = garden[0][idx_prev];
                    if (prev_tile != flower_tile) {
                        if (out_row[idx_prev] == ' ') {
                            out_row[idx_prev] = '1';
                        } else if (out_row[idx_prev] == '1') {
                            out_row[idx_prev] = '2';
                        }
                    }
                }
                if (idx < out_row.len - 1) {
                    const idx_next = idx + 1;
                    const next_tile = garden[0][idx_next];
                    if (next_tile != flower_tile) {
                        if (out_row[idx_next] == ' ') {
                            out_row[idx_next] = '1';
                        } else if (out_row[idx_next] == '1') {
                            out_row[idx_next] = '2';
                        }
                    }
                }
            }
        }

        out_garden[0] = out_row;
        return out_garden;
    } else {
        const matrix = try Matrix(u8).init(allocator, garden.len, garden[0].len);
        defer matrix.deinit(allocator);

        for (0..garden.len) |idx_row| {
            for (0..garden[0].len) |idx_col| {
                matrix.set(idx_row, idx_col, garden[idx_row][idx_col]);
            }
        }

        for (0..matrix.num_rows) |idx_row| {
            for (0..matrix.num_cols) |idx_col| {
                const tile = matrix.get(idx_row, idx_col);
                if (tile != flower_tile) {
                    var count: u8 = 0;

                    const offsets = [3]i64{ -1, 0, 1 };
                    const min_row: i64 = 0;
                    const max_row: i64 = @intCast(matrix.num_rows - 1);
                    const min_col: i64 = 0;
                    const max_col: i64 = @intCast(matrix.num_cols - 1);
                    const cur_row: i64 = @intCast(idx_row);
                    const cur_col: i64 = @intCast(idx_col);

                    for (offsets) |o_row| {
                        for (offsets) |o_col| {
                            const new_row = cur_row + o_row;
                            const new_col = cur_col + o_col;
                            if ((new_row >= min_row) and
                                (new_row <= max_row) and
                                (new_col >= min_col) and
                                (new_col <= max_col))
                            {
                                count += @as(
                                    u8,
                                    @intFromBool(matrix.get(@as(usize, @intCast(new_row)), @as(usize, @intCast(new_col))) == flower_tile),
                                );
                            }
                        }
                    }

                    matrix.set(idx_row, idx_col, if (count == 0) ' ' else '0' + count);
                }
            }
        }

        const out_garden = try allocator.alloc([]u8, matrix.num_rows);
        errdefer allocator.free(out_garden);

        var idx_out_row: usize = 0;
        errdefer {
            for (0..idx_out_row) |i| allocator.free(out_garden[i]);
        }

        for (0..matrix.num_rows) |idx_row| {
            idx_out_row = idx_row;
            const out_row = try allocator.alloc(u8, matrix.num_cols);

            for (0..matrix.num_cols) |idx_col| {
                out_row[idx_col] = matrix.get(idx_row, idx_col);
            }

            out_garden[idx_row] = out_row;
        }

        return out_garden;
    }
}

fn annotateTest(
    allocator: mem.Allocator,
    expected: []const []const u8,
    garden: []const []const u8,
) anyerror!void {
    const actual = try annotate(allocator, garden);
    defer {
        for (actual) |line| allocator.free(line);
        allocator.free(actual);
    }
    try testing.expectEqual(expected.len, actual.len);
    for (expected, actual) |e, a| {
        try testing.expectEqualStrings(e, a);
    }
}

test "no rows" {
    const garden = [_][]const u8{};
    const expected = [_][]const u8{};
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "no columns" {
    const garden = [_][]const u8{
        "", //
    };
    const expected = [_][]const u8{
        "", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "no flowers" {
    const garden = [_][]const u8{
        "   ", //
        "   ", //
        "   ", //
    };
    const expected = [_][]const u8{
        "   ", //
        "   ", //
        "   ", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "garden full of flowers" {
    const garden = [_][]const u8{
        "***", //
        "***", //
        "***", //
    };
    const expected = [_][]const u8{
        "***", //
        "***", //
        "***", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "flower surrounded by spaces" {
    const garden = [_][]const u8{
        "   ", //
        " * ", //
        "   ", //
    };
    const expected = [_][]const u8{
        "111", //
        "1*1", //
        "111", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "space surrounded by flowers" {
    const garden = [_][]const u8{
        "***", //
        "* *", //
        "***", //
    };
    const expected = [_][]const u8{
        "***", //
        "*8*", //
        "***", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "horizontal line" {
    const garden = [_][]const u8{
        " * * ", //
    };
    const expected = [_][]const u8{
        "1*2*1", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "horizontal line, flowers at edges" {
    const garden = [_][]const u8{
        "*   *", //
    };
    const expected = [_][]const u8{
        "*1 1*", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "vertical line" {
    const garden = [_][]const u8{
        " ", //
        "*", //
        " ", //
        "*", //
        " ", //
    };
    const expected = [_][]const u8{
        "1", //
        "*", //
        "2", //
        "*", //
        "1", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "vertical line, flowers at edges" {
    const garden = [_][]const u8{
        "*", //
        " ", //
        " ", //
        " ", //
        "*", //
    };
    const expected = [_][]const u8{
        "*", //
        "1", //
        " ", //
        "1", //
        "*", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "cross" {
    const garden = [_][]const u8{
        "  *  ", //
        "  *  ", //
        "*****", //
        "  *  ", //
        "  *  ", //
    };
    const expected = [_][]const u8{
        " 2*2 ", //
        "25*52", //
        "*****", //
        "25*52", //
        " 2*2 ", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "large garden" {
    const garden = [_][]const u8{
        " *  * ", //
        "  *   ", //
        "    * ", //
        "   * *", //
        " *  * ", //
        "      ", //
    };
    const expected = [_][]const u8{
        "1*22*1", //
        "12*322", //
        " 123*2", //
        "112*4*", //
        "1*22*2", //
        "111111", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}

test "multiple adjacent flowers" {
    const garden = [_][]const u8{
        " ** ", //
    };
    const expected = [_][]const u8{
        "1**1", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        annotateTest,
        .{ &expected, &garden },
    );
}
