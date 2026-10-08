const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const SayError = error{
    OutOfRange,
};

const min_value: i41 = 0;
const max_value: i41 = 999_999_999_999;

const words_up_to_twenty = [21][]const u8{
    "zero",    "one",     "two",       "three",    "four",
    "five",    "six",     "seven",     "eight",    "nine",
    "ten",     "eleven",  "twelve",    "thirteen", "fourteen",
    "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
    "twenty",
};

// Index 0 is "twenty", so use [decimal - 2].
const multiples_of_ten = [8][]const u8{
    "twenty", "thirty",  "forty",  "fifty",
    "sixty",  "seventy", "eighty", "ninety",
};

const scales = [4][]const u8{ "", "thousand", "million", "billion" };

/// Appends a word, inserting a space if the output isn't empty.
fn appendWord(allocator: mem.Allocator, out: *std.ArrayList(u8), word: []const u8) !void {
    if (out.items.len > 0) try out.append(allocator, ' ');
    try out.appendSlice(allocator, word);
}

/// Appends e.g. "three hundred forty-five" for hundred=3, decimal=4, digit=5.
/// Appends nothing if all three are zero.
fn appendChunk(
    allocator: mem.Allocator,
    out: *std.ArrayList(u8),
    hundred: usize,
    decimal: usize,
    digit: usize,
) !void {
    if (hundred > 0) {
        try appendWord(allocator, out, words_up_to_twenty[hundred]);
        try appendWord(allocator, out, "hundred");
    }

    if (decimal >= 2) {
        try appendWord(allocator, out, multiples_of_ten[decimal - 2]);
        if (digit > 0) {
            try out.append(allocator, '-');
            try out.appendSlice(allocator, words_up_to_twenty[digit]);
        }
    } else if (decimal == 1) {
        try appendWord(allocator, out, words_up_to_twenty[10 + digit]);
    } else if (digit > 0) {
        try appendWord(allocator, out, words_up_to_twenty[digit]);
    }
}

pub fn say(allocator: mem.Allocator, number: i41) (mem.Allocator.Error || SayError)![]u8 {
    if (number < min_value or number > max_value) {
        return SayError.OutOfRange;
    }
    if (number <= 20) {
        return allocator.dupe(u8, words_up_to_twenty[@intCast(number)]);
    }

    var chunks: [4]usize = undefined;
    var current_value: i41 = number;
    for (&chunks) |*ch| {
        ch.* = @intCast(@rem(current_value, 1_000));
        current_value = @divFloor(current_value, 1_000);
    }

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    var idx: usize = chunks.len;
    while (idx > 0) {
        idx -= 1;
        const next_three = chunks[idx];
        if (next_three == 0) continue;

        const hundred = next_three / 100;
        const decimal = (next_three % 100) / 10;
        const digit = next_three % 10;
        // std.debug.print("D: hundred={d} decimal={d} digit={d}\n", .{ hundred, decimal, digit });
        try appendChunk(allocator, &out, hundred, decimal, digit);
        if (idx > 0) try appendWord(allocator, &out, scales[idx]);
    }

    return out.toOwnedSlice(allocator);
}

fn sayTest(allocator: mem.Allocator, number: i41, expected: []const u8) anyerror!void {
    const actual = try say(allocator, number);
    defer allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "zero" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 0, "zero" },
    );
}

test "one" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 1, "one" },
    );
}

test "fourteen" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 14, "fourteen" },
    );
}

test "twenty" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 20, "twenty" },
    );
}

test "twenty-two" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 22, "twenty-two" },
    );
}

test "thirty" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 30, "thirty" },
    );
}

test "ninety-nine" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 99, "ninety-nine" },
    );
}

test "one hundred" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 100, "one hundred" },
    );
}

test "one hundred twenty-three" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 123, "one hundred twenty-three" },
    );
}

test "two hundred" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 200, "two hundred" },
    );
}

test "nine hundred ninety-nine" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 999, "nine hundred ninety-nine" },
    );
}

test "one thousand" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 1_000, "one thousand" },
    );
}

test "one thousand two hundred thirty-four" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 1_234, "one thousand two hundred thirty-four" },
    );
}

test "one million" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 1_000_000, "one million" },
    );
}

test "one million two thousand three hundred forty-five" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 1_002_345, "one million two thousand three hundred forty-five" },
    );
}

test "one billion" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 1_000_000_000, "one billion" },
    );
}

test "a big number" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 987_654_321_123, "nine hundred eighty-seven billion six hundred fifty-four million three hundred twenty-one thousand one hundred twenty-three" },
    );
}

test "numbers below zero are out of range" {
    try testing.expectError(SayError.OutOfRange, say(testing.allocator, -1));
}

test "numbers above 999,999,999,999 are out of range" {
    try testing.expectError(SayError.OutOfRange, say(testing.allocator, 1_000_000_000_000));
}

test "additional big number" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 19_011_016_013, "nineteen billion eleven million sixteen thousand thirteen" },
    );
}

test "different big number" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 812_000_070_017, "eight hundred twelve billion seventy thousand seventeen" },
    );
}

test "alternative big number" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 60_010_015_018, "sixty billion ten million fifteen thousand eighteen" },
    );
}

test "twelve sevens" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        sayTest,
        .{ 777_777_777_777, "seven hundred seventy-seven billion seven hundred seventy-seven million seven hundred seventy-seven thousand seven hundred seventy-seven" },
    );
}
