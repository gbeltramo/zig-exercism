const std = @import("std");
const testing = std.testing;

var memory_buffer: [4_096]u8 = undefined;

pub fn isValid(s: []const u8) bool {
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();

    var list = std.ArrayList(u8).initCapacity(allocator, 0) catch unreachable;

    for (s) |c| {
        if (std.ascii.isDigit(c)) {
            const parsed_digit = c - '0';
            list.append(allocator, parsed_digit) catch unreachable;
        } else {
            if (!std.ascii.isWhitespace(c)) return false;
        }
    }

    if (list.items.len <= 1) return false;

    std.mem.reverse(u8, list.items);
    var idx: usize = 1;
    var total: u64 = list.items[0];
    while (idx < list.items.len) : (idx += 1) {
        const d = list.items[idx];
        var new_d: u64 = @intCast(d);
        if ((idx % 2) == 1) {
            new_d = if ((2 * d) > 9) (2 * @as(u64, @intCast(d))) - 9 else 2 * @as(u64, @intCast(d));
        }
        total += new_d;
    }
    return (total % 10) == 0;
}

test "single digit strings cannot be valid" {
    try testing.expect(!isValid("1"));
}

test "a single zero is invalid" {
    try testing.expect(!isValid("0"));
}

test "a simple valid SIN that remains valid if reversed" {
    try testing.expect(isValid("059"));
}

test "a simple valid SIN that becomes invalid if reversed" {
    try testing.expect(isValid("59"));
}

test "a valid Canadian SIN" {
    try testing.expect(isValid("055 444 285"));
}

test "invalid Canadian SIN" {
    try testing.expect(!isValid("055 444 286"));
}

test "invalid credit card" {
    try testing.expect(!isValid("8273 1232 7352 0569"));
}

test "invalid long number with an even remainder" {
    try testing.expect(!isValid("1 2345 6789 1234 5678 9012"));
}

test "invalid long number with a remainder divisible by 5" {
    try testing.expect(!isValid("1 2345 6789 1234 5678 9013"));
}

test "valid number with an even number of digits" {
    try testing.expect(isValid("095 245 88"));
}

test "valid number with an odd number of spaces" {
    try testing.expect(isValid("234 567 891 234"));
}

test "valid strings with a non-digit added at the end become invalid" {
    try testing.expect(!isValid("059a"));
}

test "valid strings with punctuation included become invalid" {
    try testing.expect(!isValid("055-444-285"));
}

test "valid strings with symbols included become invalid" {
    try testing.expect(!isValid("055# 444$ 285"));
}

test "single zero with space is invalid" {
    try testing.expect(!isValid(" 0"));
}

test "more than a single zero is valid" {
    try testing.expect(isValid("0000 0"));
}

test "input digit 9 is correctly converted to output digit 9" {
    try testing.expect(isValid("091"));
}

test "very long input is valid" {
    try testing.expect(isValid("9999999999 9999999999 9999999999 9999999999"));
}

test "valid luhn with an odd number of digits and non zero first digit" {
    try testing.expect(isValid("109"));
}

test "using ascii value for non-doubled non-digit isn't allowed" {
    try testing.expect(!isValid("055b 444 285"));
}

test "using ascii value for doubled non-digit isn't allowed" {
    try testing.expect(!isValid(":9"));
}

test "non-numeric, non-space char in the middle with a sum that's divisible by 10 isn't allowed" {
    try testing.expect(!isValid("59%59"));
}
