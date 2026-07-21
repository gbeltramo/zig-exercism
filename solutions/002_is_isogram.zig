const std = @import("std");
const testing = std.testing;

pub fn isIsogram(str: []const u8) bool {
    var seen: u26 = 0;

    for (str) |c| {
        if (c == ' ' or c == '-') {
            continue;
        }

        const lower_c = std.ascii.toLower(c);
        const mask: u26 = @as(u26, 1) << @intCast(lower_c - 'a');
        if (seen & mask != 0) {
            return false;
        }
        seen |= mask;
    }

    return true;
}

test "empty string" {
    try testing.expect(isIsogram(""));
}

test "isogram with only lower case characters" {
    try testing.expect(isIsogram("isogram"));
}

test "word with one duplicated character" {
    try testing.expect(!isIsogram("eleven"));
}

test "word with one duplicated character from the end of the alphabet" {
    try testing.expect(!isIsogram("zzyzx"));
}

test "longest reported english isogram" {
    try testing.expect(isIsogram("subdermatoglyphic"));
}

test "word with duplicated character in mixed case" {
    try testing.expect(!isIsogram("Alphabet"));
}

test "word with duplicated character in mixed case, lowercase first" {
    try testing.expect(!isIsogram("alphAbet"));
}

test "hypothetical isogrammic word with hyphen" {
    try testing.expect(isIsogram("thumbscrew-japingly"));
}

test "hypothetical word with duplicated character following hyphen" {
    try testing.expect(!isIsogram("thumbscrew-jappingly"));
}

test "isogram with duplicated hyphen" {
    try testing.expect(isIsogram("six-year-old"));
}

test "made-up name that is an isogram" {
    try testing.expect(isIsogram("Emily Jung Schwartzkopf"));
}

test "duplicated character in the middle" {
    try testing.expect(!isIsogram("accentor"));
}

test "same first and last characters" {
    try testing.expect(!isIsogram("angola"));
}

test "word with duplicated character and with two hyphens" {
    try testing.expect(!isIsogram("up-to-date"));
}
