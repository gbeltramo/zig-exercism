const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const Direction = enum(u8) {
    east,
    south,
    west,
    north,
};

const Position = struct {
    row: u16,
    col: u16,
};

pub fn spiral(allocator: mem.Allocator, size: u16) mem.Allocator.Error![][]u16 {
    if (size == 0) {
        const matrix = try allocator.alloc([]u16, 0);
        return matrix;
    } else if (size == 1) {
        const matrix = try allocator.alloc([]u16, 1);
        errdefer allocator.free(matrix);
        const row = try allocator.alloc(u16, 1);
        errdefer allocator.free(row);

        row[0] = 1;
        matrix[0] = row;
        return matrix;
    } else {
        const matrix = try allocator.alloc([]u16, size);
        errdefer allocator.free(matrix);

        var idx_row: usize = 0;
        errdefer {
            for (0..idx_row) |i| allocator.free(matrix[i]);
        }

        while (idx_row < size) : (idx_row += 1) {
            const row = try allocator.alloc(u16, size);
            std.crypto.secureZero(u16, row);
            matrix[idx_row] = row;
        }

        matrix[0][0] = 1;
        var current_direction = Direction.east;
        var current_position: Position = .{ .row = 0, .col = 0 };
        var num_values_set: u16 = 1;
        while (num_values_set < size * size) {
            switch (current_direction) {
                .east => {
                    if ((current_position.col + 1) < size) {
                        current_position.col += 1;
                        if (isVisited(matrix, current_position)) {
                            current_position.col -= 1;
                            current_direction = .south;
                            current_position.row += 1;
                        }
                    } else {
                        current_direction = .south;
                        current_position.row += 1;
                    }
                },
                .south => {
                    if ((current_position.row + 1) < size) {
                        current_position.row += 1;
                        if (isVisited(matrix, current_position)) {
                            current_position.row -= 1;
                            current_direction = .west;
                            current_position.col -= 1;
                        }
                    } else {
                        current_direction = .west;
                        current_position.col -= 1;
                    }
                },
                .west => {
                    if (current_position.col > 0) {
                        current_position.col -= 1;
                        if (isVisited(matrix, current_position)) {
                            current_position.col += 1;
                            current_direction = .north;
                            current_position.row -= 1;
                        }
                    } else {
                        current_direction = .north;
                        current_position.row -= 1;
                    }
                },
                .north => {
                    if (current_position.row > 0) {
                        current_position.row -= 1;
                        if (isVisited(matrix, current_position)) {
                            current_position.row += 1;
                            current_direction = .east;
                            current_position.col += 1;
                        }
                    } else {
                        current_direction = .east;
                        current_position.col += 1;
                    }
                },
            }

            matrix[current_position.row][current_position.col] = num_values_set + 1;
            num_values_set += 1;
        }
        return matrix;
    }
}

pub fn isVisited(matrix: [][]u16, pos: Position) bool {
    return matrix[pos.row][pos.col] != 0;
}

fn free(slices: [][]u16) void {
    for (slices) |slice| {
        testing.allocator.free(slice);
    }
    testing.allocator.free(slices);
}

fn spiralTest(allocator: std.mem.Allocator, size: u16, expected: [][]const u16) anyerror!void {
    const actual = try spiral(allocator, size);
    defer free(actual);
    try testing.expectEqual(expected.len, actual.len);
    for (expected, actual) |expected_slice, actual_slice| {
        try testing.expectEqualSlices(u16, expected_slice, actual_slice);
    }
}

test "empty spiral" {
    const expected: [0][]const u16 = undefined;
    try testing.checkAllAllocationFailures(
        testing.allocator,
        spiralTest,
        .{ 0, &expected },
    );
}

test "trivial spiral" {
    var expected: [1][]const u16 = undefined;
    expected[0] = &.{1};
    try testing.checkAllAllocationFailures(
        testing.allocator,
        spiralTest,
        .{ 1, &expected },
    );
}

test "spiral of size 2" {
    var expected: [2][]const u16 = undefined;
    expected[0] = &.{ 1, 2 };
    expected[1] = &.{ 4, 3 };
    try testing.checkAllAllocationFailures(
        testing.allocator,
        spiralTest,
        .{ 2, &expected },
    );
}

test "spiral of size 3" {
    var expected: [3][]const u16 = undefined;
    expected[0] = &.{ 1, 2, 3 };
    expected[1] = &.{ 8, 9, 4 };
    expected[2] = &.{ 7, 6, 5 };
    try testing.checkAllAllocationFailures(
        testing.allocator,
        spiralTest,
        .{ 3, &expected },
    );
}

test "spiral of size 4" {
    var expected: [4][]const u16 = undefined;
    expected[0] = &.{ 1, 2, 3, 4 };
    expected[1] = &.{ 12, 13, 14, 5 };
    expected[2] = &.{ 11, 16, 15, 6 };
    expected[3] = &.{ 10, 9, 8, 7 };
    try testing.checkAllAllocationFailures(
        testing.allocator,
        spiralTest,
        .{ 4, &expected },
    );
}

test "spiral of size 5" {
    var expected: [5][]const u16 = undefined;
    expected[0] = &.{ 1, 2, 3, 4, 5 };
    expected[1] = &.{ 16, 17, 18, 19, 6 };
    expected[2] = &.{ 15, 24, 25, 20, 7 };
    expected[3] = &.{ 14, 23, 22, 21, 8 };
    expected[4] = &.{ 13, 12, 11, 10, 9 };
    try testing.checkAllAllocationFailures(
        testing.allocator,
        spiralTest,
        .{ 5, &expected },
    );
}
