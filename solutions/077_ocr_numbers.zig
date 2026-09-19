const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const RecognitionError = error{
    InvalidRowCount,
    InvalidColumnCount,
};

const grid_num_rows: usize = 4;
const grid_num_cols: usize = 3;
const digits_as_grid = [10][9]u8{
    [9]u8{ // 0
        32,  95, 32,
        124, 32, 124,
        124, 95, 124,
    },
    [9]u8{ // 1
        32, 32, 32,
        32, 32, 124,
        32, 32, 124,
    },
    [9]u8{ // 2
        32,  95, 32,
        32,  95, 124,
        124, 95, 32,
    },
    [9]u8{ // 3
        32, 95, 32,
        32, 95, 124,
        32, 95, 124,
    },
    [9]u8{ // 4
        32,  32, 32,
        124, 95, 124,
        32,  32, 124,
    },
    [9]u8{ // 5
        32,  95, 32,
        124, 95, 32,
        32,  95, 124,
    },
    [9]u8{ // 6
        32,  95, 32,
        124, 95, 32,
        124, 95, 124,
    },
    [9]u8{ // 7
        32, 95, 32,
        32, 32, 124,
        32, 32, 124,
    },
    [9]u8{ // 8
        32,  95, 32,
        124, 95, 124,
        124, 95, 124,
    },
    [9]u8{ // 9
        32,  95, 32,
        124, 95, 124,
        32,  95, 124,
    },
};

pub fn convert(buffer: []u8, input: []const []const u8) RecognitionError![]u8 {
    if ((input.len == 0) or (input.len % grid_num_rows != 0)) return RecognitionError.InvalidRowCount;
    if ((input[0].len == 0) or (input[0].len % grid_num_cols != 0)) return RecognitionError.InvalidColumnCount;

    const num_meta_rows: usize = input.len / grid_num_rows;
    const num_meta_cols: usize = input[0].len / grid_num_cols;
    var length: usize = 0;
    for (0..num_meta_rows) |idx_meta_row| {
        for (0..num_meta_cols) |idx_meta_col| {
            const digit_part_0 = input[grid_num_rows * idx_meta_row + 0][grid_num_cols * idx_meta_col .. grid_num_cols * idx_meta_col + grid_num_cols];
            const digit_part_1 = input[grid_num_rows * idx_meta_row + 1][grid_num_cols * idx_meta_col .. grid_num_cols * idx_meta_col + grid_num_cols];
            const digit_part_2 = input[grid_num_rows * idx_meta_row + 2][grid_num_cols * idx_meta_col .. grid_num_cols * idx_meta_col + grid_num_cols];
            // NOTE (gabriele) last row is always 32, 32, 32. Can be skipped

            const current_digit = [9]u8{
                digit_part_0[0], digit_part_0[1], digit_part_0[2],
                digit_part_1[0], digit_part_1[1], digit_part_1[2],
                digit_part_2[0], digit_part_2[1], digit_part_2[2],
            };

            buffer[length] = for (digits_as_grid, 0..) |target_digit, value| {
                if (std.mem.eql(u8, &current_digit, &target_digit)) {
                    break '0' + @as(u8, @intCast(value));
                }
            } else '?';
            length += 1;
        }

        if (idx_meta_row != (num_meta_rows - 1)) {
            buffer[length] = ',';
            length += 1;
        }
    }

    return buffer[0..length];
}

const buffer_size = 80;

test "Recognizes 0" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        " _ ", //
        "| |", //
        "|_|", //
        "   ", //
    };
    try testing.expectEqualStrings("0", try convert(&buffer, &input));
}

test "Recognizes 1" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        "   ", //
        "  |", //
        "  |", //
        "   ", //
    };
    try testing.expectEqualStrings("1", try convert(&buffer, &input));
}

test "Unreadable but correctly sized inputs return ?" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        "   ", //
        "  _", //
        "  |", //
        "   ", //
    };
    try testing.expectEqualStrings("?", try convert(&buffer, &input));
}

test "Input with a number of lines that is not a multiple of four raises an error" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        " _ ", //
        "| |", //
        "   ", //
    };
    try testing.expectError(RecognitionError.InvalidRowCount, convert(&buffer, &input));
}

test "Input with a number of columns that is not a multiple of three raises an error" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        "    ", //
        "   |", //
        "   |", //
        "    ", //
    };
    try testing.expectError(RecognitionError.InvalidColumnCount, convert(&buffer, &input));
}

test "Recognizes 110101100" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        "       _     _        _  _ ", //
        "  |  || |  || |  |  || || |", //
        "  |  ||_|  ||_|  |  ||_||_|", //
        "                           ", //
    };
    try testing.expectEqualStrings("110101100", try convert(&buffer, &input));
}

test "Garbled numbers in a string are replaced with ?" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        "       _     _           _ ", //
        "  |  || |  || |     || || |", //
        "  |  | _|  ||_|  |  ||_||_|", //
        "                           ", //
    };
    try testing.expectEqualStrings("11?10?1?0", try convert(&buffer, &input));
}

test "Recognizes 2" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        " _ ", //
        " _|", //
        "|_ ", //
        "   ", //
    };
    try testing.expectEqualStrings("2", try convert(&buffer, &input));
}

test "Recognizes 3" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        " _ ", //
        " _|", //
        " _|", //
        "   ", //
    };
    try testing.expectEqualStrings("3", try convert(&buffer, &input));
}

test "Recognizes 4" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        "   ", //
        "|_|", //
        "  |", //
        "   ", //
    };
    try testing.expectEqualStrings("4", try convert(&buffer, &input));
}

test "Recognizes 5" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        " _ ", //
        "|_ ", //
        " _|", //
        "   ", //
    };
    try testing.expectEqualStrings("5", try convert(&buffer, &input));
}

test "Recognizes 6" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        " _ ", //
        "|_ ", //
        "|_|", //
        "   ", //
    };
    try testing.expectEqualStrings("6", try convert(&buffer, &input));
}

test "Recognizes 7" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        " _ ", //
        "  |", //
        "  |", //
        "   ", //
    };
    try testing.expectEqualStrings("7", try convert(&buffer, &input));
}

test "Recognizes 8" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        " _ ", //
        "|_|", //
        "|_|", //
        "   ", //
    };
    try testing.expectEqualStrings("8", try convert(&buffer, &input));
}

test "Recognizes 9" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        " _ ", //
        "|_|", //
        " _|", //
        "   ", //
    };
    try testing.expectEqualStrings("9", try convert(&buffer, &input));
}

test "Recognizes string of decimal numbers" {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        "    _  _     _  _  _  _  _  _ ", //
        "  | _| _||_||_ |_   ||_||_|| |", //
        "  ||_  _|  | _||_|  ||_| _||_|", //
        "                              ", //
    };
    try testing.expectEqualStrings("1234567890", try convert(&buffer, &input));
}

test "Numbers separated by empty lines are recognized. Lines are joined by commas." {
    var buffer: [buffer_size]u8 = undefined;
    const input = [_][]const u8{
        "    _  _ ", //
        "  | _| _|", //
        "  ||_  _|", //
        "         ", //
        "    _  _ ", //
        "|_||_ |_ ", //
        "  | _||_|", //
        "         ", //
        " _  _  _ ", //
        "  ||_||_|", //
        "  ||_| _|", //
        "         ", //
    };
    try testing.expectEqualStrings("123,456,789", try convert(&buffer, &input));
}
