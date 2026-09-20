const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const Point = struct {
    row: u16,
    column: u16,
};

pub fn saddlePoints(comptime m: usize, comptime n: usize, allocator: mem.Allocator, matrix: [m][n]i32) mem.Allocator.Error![]Point {
    if (m == 0 or n == 0) return allocator.alloc(Point, 0);

    var list: std.ArrayList(Point) = .empty;
    errdefer list.deinit(allocator);

    for (0..m) |idx_row| {
        var max_row: i32 = std.math.minInt(i32);
        for (0..n) |idx_col| max_row = @max(max_row, matrix[idx_row][idx_col]);

        for (0..n) |idx_col| {
            if (matrix[idx_row][idx_col] != max_row) continue;

            var is_minimum = true;
            for (0..m) |idx_row_inner| {
                if (matrix[idx_row_inner][idx_col] < max_row) {
                    is_minimum = false;
                    break;
                }
            }

            if (is_minimum) {
                try list.append(allocator, .{
                    .row = @intCast(idx_row + 1),
                    .column = @intCast(idx_col + 1),
                });
            }
        }
    }

    return list.toOwnedSlice(allocator);
}

test "Can identify single saddle point" {
    const matrix = [3][3]i32{
        [3]i32{ 9, 8, 7 }, //
        [3]i32{ 5, 3, 2 }, //
        [3]i32{ 6, 6, 7 }, //
    };
    const expected = [_]Point{
        .{ .row = 2, .column = 1 }, //
    };
    const actual = try saddlePoints(3, 3, testing.allocator, matrix);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Point, &expected, actual);
}

test "Can identify that empty matrix has no saddle points" {
    const matrix = [1][0]i32{
        [0]i32{}, //
    };
    const expected = [_]Point{};
    const actual = try saddlePoints(1, 0, testing.allocator, matrix);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Point, &expected, actual);
}

test "Can identify lack of saddle points when there are none" {
    const matrix = [3][3]i32{
        [3]i32{ 1, 2, 3 }, //
        [3]i32{ 3, 1, 2 }, //
        [3]i32{ 2, 3, 1 }, //
    };
    const expected = [_]Point{};
    const actual = try saddlePoints(3, 3, testing.allocator, matrix);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Point, &expected, actual);
}

test "Can identify multiple saddle points in a column" {
    const matrix = [3][3]i32{
        [3]i32{ 4, 5, 4 }, //
        [3]i32{ 3, 5, 5 }, //
        [3]i32{ 1, 5, 4 }, //
    };
    const expected = [_]Point{
        .{ .row = 1, .column = 2 }, //
        .{ .row = 2, .column = 2 }, //
        .{ .row = 3, .column = 2 }, //
    };
    const actual = try saddlePoints(3, 3, testing.allocator, matrix);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Point, &expected, actual);
}

test "Can identify multiple saddle points in a row" {
    const matrix = [3][3]i32{
        [3]i32{ 6, 7, 8 }, //
        [3]i32{ 5, 5, 5 }, //
        [3]i32{ 7, 5, 6 }, //
    };
    const expected = [_]Point{
        .{ .row = 2, .column = 1 }, //
        .{ .row = 2, .column = 2 }, //
        .{ .row = 2, .column = 3 }, //
    };
    const actual = try saddlePoints(3, 3, testing.allocator, matrix);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Point, &expected, actual);
}

test "Can identify saddle point in bottom right corner" {
    const matrix = [3][3]i32{
        [3]i32{ 8, 7, 9 }, //
        [3]i32{ 6, 7, 6 }, //
        [3]i32{ 3, 2, 5 }, //
    };
    const expected = [_]Point{
        .{ .row = 3, .column = 3 }, //
    };
    const actual = try saddlePoints(3, 3, testing.allocator, matrix);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Point, &expected, actual);
}

test "Can identify saddle points in a non square matrix" {
    const matrix = [2][3]i32{
        [3]i32{ 3, 1, 3 }, //
        [3]i32{ 3, 2, 4 }, //
    };
    const expected = [_]Point{
        .{ .row = 1, .column = 1 }, //
        .{ .row = 1, .column = 3 }, //
    };
    const actual = try saddlePoints(2, 3, testing.allocator, matrix);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Point, &expected, actual);
}

test "Can identify that saddle points in a single column matrix are those with the minimum value" {
    const matrix = [4][1]i32{
        [1]i32{2}, //
        [1]i32{1}, //
        [1]i32{4}, //
        [1]i32{1}, //
    };
    const expected = [_]Point{
        .{ .row = 2, .column = 1 }, //
        .{ .row = 4, .column = 1 }, //
    };
    const actual = try saddlePoints(4, 1, testing.allocator, matrix);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Point, &expected, actual);
}

test "Can identify that saddle points in a single row matrix are those with the maximum value" {
    const matrix = [1][4]i32{
        [4]i32{ 2, 5, 3, 5 }, //
    };
    const expected = [_]Point{
        .{ .row = 1, .column = 2 }, //
        .{ .row = 1, .column = 4 }, //
    };
    const actual = try saddlePoints(1, 4, testing.allocator, matrix);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Point, &expected, actual);
}
