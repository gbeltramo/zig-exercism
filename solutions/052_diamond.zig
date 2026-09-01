const std = @import("std");
const mem = std.mem;
const testing = std.testing;

/// Generate diamond of letters as slice of slices.
/// Caller owns returned memory, both outer slice and inner row slices.
pub fn rows(allocator: mem.Allocator, letter: u8) mem.Allocator.Error![][]u8 {
    std.debug.assert(letter >= 'A');
    std.debug.assert(letter <= 'Z');

    const num_half_rows: usize = letter - 'A';
    const num_half_cols = num_half_rows;
    const num_rows: usize = 2 * (letter - 'A') + 1;
    const num_cols = num_rows;

    const diamond = try allocator.alloc([]u8, num_rows);
    errdefer allocator.free(diamond);

    // * Deallocate rows in "for loops" below in case one of the allocations fails
    var num_allocated: usize = 0;
    errdefer {
        for (diamond[0..num_allocated]) |row| allocator.free(row);
    }

    // * Create rows up to middle row
    for (0..num_half_rows + 1) |idx_row| {
        const row = try allocator.alloc(u8, num_cols);
        num_allocated += 1; // keep track of number of allocated rows; for error clenup

        const c = 'A' + idx_row;
        for (0..num_half_cols + 1) |idx_col| {
            const offset1 = num_half_cols + idx_col;
            const offset2 = num_half_cols - idx_col;

            if (idx_col == (c - 'A')) {
                row[offset1] = @intCast(c);
                row[offset2] = @intCast(c);
            } else {
                row[offset1] = ' ';
                row[offset2] = ' ';
            }
        }
        diamond[idx_row] = row;
    }

    // * Create second half of rows, copying the first half in reverse order
    for (num_half_rows + 1..num_rows) |idx_row| {
        const row = try allocator.alloc(u8, num_cols);
        num_allocated += 1; // keep track of number of allocated rows; for error clenup

        const prev_row = num_rows - idx_row - 1;
        @memcpy(row, diamond[prev_row]);

        diamond[idx_row] = row;
    }

    return diamond;
}

fn free(slices: [][]u8) void {
    for (slices) |slice| {
        testing.allocator.free(slice);
    }
    testing.allocator.free(slices);
}

fn testRows(allocator: std.mem.Allocator, expected: []const []const u8, letter: u8) !void {
    const actual = try rows(allocator, letter);
    defer free(actual);
    try testing.expectEqual(expected.len, actual.len);
    for (0..expected.len) |i| {
        try testing.expectEqualStrings(expected[i], actual[i]);
    }
}

test "Degenerate case with a single 'A' row" {
    const expected = [_][]const u8{
        "A", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testRows,
        .{ &expected, 'A' },
    );
}

test "Degenerate case with no row containing 3 distinct groups of spaces" {
    const expected = [_][]const u8{
        " A ", //
        "B B", //
        " A ", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testRows,
        .{ &expected, 'B' },
    );
}

test "Smallest non-degenerate case with odd diamond side length" {
    const expected = [_][]const u8{
        "  A  ", //
        " B B ", //
        "C   C", //
        " B B ", //
        "  A  ", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testRows,
        .{ &expected, 'C' },
    );
}

test "Smallest non-degenerate case with even diamond side length" {
    const expected = [_][]const u8{
        "   A   ", //
        "  B B  ", //
        " C   C ", //
        "D     D", //
        " C   C ", //
        "  B B  ", //
        "   A   ", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testRows,
        .{ &expected, 'D' },
    );
}

test "Largest possible diamond" {
    const expected = [_][]const u8{
        "                         A                         ", //
        "                        B B                        ", //
        "                       C   C                       ", //
        "                      D     D                      ", //
        "                     E       E                     ", //
        "                    F         F                    ", //
        "                   G           G                   ", //
        "                  H             H                  ", //
        "                 I               I                 ", //
        "                J                 J                ", //
        "               K                   K               ", //
        "              L                     L              ", //
        "             M                       M             ", //
        "            N                         N            ", //
        "           O                           O           ", //
        "          P                             P          ", //
        "         Q                               Q         ", //
        "        R                                 R        ", //
        "       S                                   S       ", //
        "      T                                     T      ", //
        "     U                                       U     ", //
        "    V                                         V    ", //
        "   W                                           W   ", //
        "  X                                             X  ", //
        " Y                                               Y ", //
        "Z                                                 Z", //
        " Y                                               Y ", //
        "  X                                             X  ", //
        "   W                                           W   ", //
        "    V                                         V    ", //
        "     U                                       U     ", //
        "      T                                     T      ", //
        "       S                                   S       ", //
        "        R                                 R        ", //
        "         Q                               Q         ", //
        "          P                             P          ", //
        "           O                           O           ", //
        "            N                         N            ", //
        "             M                       M             ", //
        "              L                     L              ", //
        "               K                   K               ", //
        "                J                 J                ", //
        "                 I               I                 ", //
        "                  H             H                  ", //
        "                   G           G                   ", //
        "                    F         F                    ", //
        "                     E       E                     ", //
        "                      D     D                      ", //
        "                       C   C                       ", //
        "                        B B                        ", //
        "                         A                         ", //
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testRows,
        .{ &expected, 'Z' },
    );
}
