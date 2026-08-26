const std = @import("std");
const testing = std.testing;

pub fn clean(phrase: []const u8) ?[10]u8 {
    var digits: [10]u8 = .{ 100, 100, 100, 100, 100, 100, 100, 100, 100, 100 };

    var idx: usize = 0;
    var one_one_was_already_skipped: bool = false;
    for (phrase) |n| {
        if (std.ascii.isDigit(n)) {
            if ((idx == 0) and (n == '1')) {
                if (one_one_was_already_skipped) {
                    return null;
                }
                one_one_was_already_skipped = true;
                continue;
            }
            if (idx >= 10) {
                return null;
            }
            digits[idx] = n;
            idx += 1;
        }
    }

    if (idx < 10) {
        return null;
    }

    if ((digits[0] == '0' or digits[0] == '1') or (digits[3] == '0' or digits[3] == '1')) {
        return null;
    }

    return digits;
}

test "cleans the number" {
    const expected: ?[10]u8 = "2234567890".*;
    const actual = clean("(223) 456-7890");
    try testing.expectEqual(expected, actual);
}

test "cleans numbers with dots" {
    const expected: ?[10]u8 = "2234567890".*;
    const actual = clean("223.456.7890");
    try testing.expectEqual(expected, actual);
}

test "cleans numbers with multiple spaces" {
    const expected: ?[10]u8 = "2234567890".*;
    const actual = clean("223 456   7890   ");
    try testing.expectEqual(expected, actual);
}

test "invalid when 9 digits" {
    const expected: ?[10]u8 = null;
    const actual = clean("123456789");
    try testing.expectEqual(expected, actual);
}

test "invalid when 11 digits does not start with a 1" {
    const expected: ?[10]u8 = null;
    const actual = clean("22234567890");
    try testing.expectEqual(expected, actual);
}

test "valid when 11 digits and starting with 1" {
    const expected: ?[10]u8 = "2234567890".*;
    const actual = clean("12234567890");
    try testing.expectEqual(expected, actual);
}

test "valid when 11 digits and starting with 1 even with punctuation" {
    const expected: ?[10]u8 = "2234567890".*;
    const actual = clean("+1 (223) 456-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid when more than 11 digits" {
    const expected: ?[10]u8 = null;
    const actual = clean("321234567890");
    try testing.expectEqual(expected, actual);
}

test "invalid with letters" {
    const expected: ?[10]u8 = null;
    const actual = clean("523-abc-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid with punctuations" {
    const expected: ?[10]u8 = null;
    const actual = clean("523-@:!-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid if area code starts with 0" {
    const expected: ?[10]u8 = null;
    const actual = clean("(023) 456-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid if area code starts with 1" {
    const expected: ?[10]u8 = null;
    const actual = clean("(123) 456-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid if exchange code starts with 0" {
    const expected: ?[10]u8 = null;
    const actual = clean("(223) 056-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid if exchange code starts with 1" {
    const expected: ?[10]u8 = null;
    const actual = clean("(223) 156-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid if area code starts with 0 on valid 11-digit number" {
    const expected: ?[10]u8 = null;
    const actual = clean("1 (023) 456-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid if area code starts with 1 on valid 11-digit number" {
    const expected: ?[10]u8 = null;
    const actual = clean("1 (123) 456-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid if exchange code starts with 0 on valid 11-digit number" {
    const expected: ?[10]u8 = null;
    const actual = clean("1 (223) 056-7890");
    try testing.expectEqual(expected, actual);
}

test "invalid if exchange code starts with 1 on valid 11-digit number" {
    const expected: ?[10]u8 = null;
    const actual = clean("1 (223) 156-7890");
    try testing.expectEqual(expected, actual);
}
