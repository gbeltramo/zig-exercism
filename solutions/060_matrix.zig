const std = @import("std");
const mem = std.mem;
const testing = std.testing;

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

/// Parse s into a Matrix(T)
/// Caller owns the returned memory
pub fn parseMatrix(allocator: mem.Allocator, s: []const u8, index: i32) !Matrix(i16) {
    _ = index;
    var num_rows: i32 = 1;
    for (s) |c| {
        if (c == '\n') num_rows += 1;
    }

    var num_cols: i32 = 1;
    var idx: usize = 0;
    var c: u8 = s[0];
    while ((c != '\n') and (idx < s.len)) : (idx += 1) {
        c = s[idx];
        if (c == ' ') num_cols += 1;
    }

    var matrix = try Matrix(i16).init(allocator, @intCast(num_rows), @intCast(num_cols));

    var idx_row: usize = 0;
    var idx_col: usize = 0;
    var is_negative: bool = false;

    var digits_list = try std.ArrayList(i16).initCapacity(allocator, 8);
    defer digits_list.deinit(allocator);

    for (s) |digit| {
        if (digit == ' ') {
            var new_value = parseInt(&digits_list);
            if (is_negative) new_value *= -1;
            matrix.set(idx_row, idx_col, new_value);

            digits_list.clearRetainingCapacity();
            is_negative = false;
            idx_col += 1;
        } else if (digit == '\n') {
            var new_value = parseInt(&digits_list);
            if (is_negative) new_value *= -1;
            matrix.set(idx_row, idx_col, new_value);

            digits_list.clearRetainingCapacity();
            is_negative = false;
            idx_col = 0;
            idx_row += 1;
        } else if (digit == '-') {
            std.debug.assert(!is_negative); // assuming --1 is invalid
            is_negative = true;
        } else if (std.ascii.isDigit(digit)) {
            try digits_list.append(allocator, digit - '0');
        }
    }

    var new_value = parseInt(&digits_list);
    if (is_negative) new_value *= -1;
    matrix.set(idx_row, idx_col, new_value);

    return matrix;
}

pub fn parseInt(digits_list: *std.ArrayList(i16)) i16 {
    var num: i16 = 0;
    var pow: i16 = 0;
    while (true) {
        const digit = digits_list.pop();
        if (digit == null) {
            break;
        } else {
            const multiplier = std.math.pow(i16, 10, pow);
            num += (digit.? * multiplier);
            pow += 1;
        }
    }

    return num;
}

/// Returns the selected row of the matrix.
pub fn row(allocator: mem.Allocator, s: []const u8, index: i32) ![]i16 {
    const matrix = try parseMatrix(allocator, s, index);
    defer matrix.deinit(allocator);

    const idx_row: usize = @as(usize, @intCast(index)) - 1;
    const out = try allocator.alloc(i16, matrix.num_cols);
    for (0..matrix.num_cols) |idx_col| out[idx_col] = matrix.get(idx_row, idx_col);

    return out;
}

/// Returns the selected column of the matrix.
pub fn column(allocator: mem.Allocator, s: []const u8, index: i32) ![]i16 {
    const matrix = try parseMatrix(allocator, s, index);
    defer matrix.deinit(allocator);

    const idx_col: usize = @as(usize, @intCast(index)) - 1;
    const out = try allocator.alloc(i16, matrix.num_rows);
    for (0..matrix.num_rows) |idx_row| out[idx_row] = matrix.get(idx_row, idx_col);

    return out;
}

test "extract row from one number matrix" {
    const expected = &[_]i16{1};
    const s = "1";
    const actual = try row(testing.allocator, s, 1);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
test "can extract row" {
    const expected = &[_]i16{ 3, 4 };
    const s = "1 2\n3 4";
    const actual = try row(testing.allocator, s, 2);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
test "extract row where numbers have different widths" {
    const expected = &[_]i16{ 10, 20 };
    const s = "1 2\n10 20";
    const actual = try row(testing.allocator, s, 2);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
test "can extract row from non-square matrix with no corresponding column" {
    const expected = &[_]i16{ 8, 7, 6 };
    const s = "1 2 3\n4 5 6\n7 8 9\n8 7 6";
    const actual = try row(testing.allocator, s, 4);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
test "extract column from one number matrix" {
    const expected = &[_]i16{1};
    const s = "1";
    const actual = try column(testing.allocator, s, 1);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
test "can extract column" {
    const expected = &[_]i16{ 3, 6, 9 };
    const s = "1 2 3\n4 5 6\n7 8 9";
    const actual = try column(testing.allocator, s, 3);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
test "can extract column from non-square matrix with no corresponding row" {
    const expected = &[_]i16{ 4, 8, 6 };
    const s = "1 2 3 4\n5 6 7 8\n9 8 7 6";
    const actual = try column(testing.allocator, s, 4);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
test "extract column where numbers have different widths" {
    const expected = &[_]i16{ 1903, 3, 4 };
    const s = "89 1903 3\n18 3 1\n9 4 800";
    const actual = try column(testing.allocator, s, 2);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
test "row with negative numbers" {
    const expected = &[_]i16{ -57, 9, -42 };
    const s = "1 2 4\n-57 9 -42\n10 0 65";
    const actual = try row(testing.allocator, s, 2);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
test "column with negative numbers" {
    const expected = &[_]i16{ -4, -42, -465 };
    const s = "1 2 -4\n-57 9 -42\n10 0 -465";
    const actual = try column(testing.allocator, s, 3);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(i16, expected, actual);
}
