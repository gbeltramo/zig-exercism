const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn rotate(allocator: mem.Allocator, text: []const u8, shiftKey: u5) mem.Allocator.Error![]u8 {
    const out = try allocator.alloc(u8, text.len);
    var low: bool = true;
    var offset: u8 = 'a';

    for (text, 0..) |c, idx| {
        if (std.ascii.isAlphabetic(c)) {
            low = std.ascii.isLower(c);
            if (!low) {
                offset = 'A';
            } else {
                offset = 'a';
            }
            const value = c - offset;
            const new_value: u8 = (value + @as(u8, @intCast(shiftKey))) % 26;
            out[idx] = new_value + offset;
        } else {
            out[idx] = c;
        }
    }
    return out;
}

test "rotate a by 0, same output as input" {
    const expected: []const u8 = "a";
    const actual = try rotate(testing.allocator, "a", 0);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "rotate a by 1" {
    const expected: []const u8 = "b";
    const actual = try rotate(testing.allocator, "a", 1);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "rotate a by 26, same output as input" {
    const expected: []const u8 = "a";
    const actual = try rotate(testing.allocator, "a", 26);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "rotate m by 13" {
    const expected: []const u8 = "z";
    const actual = try rotate(testing.allocator, "m", 13);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "rotate n by 13 with wrap around alphabet" {
    const expected: []const u8 = "a";
    const actual = try rotate(testing.allocator, "n", 13);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "rotate capital letters" {
    const expected: []const u8 = "TRL";
    const actual = try rotate(testing.allocator, "OMG", 5);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "rotate spaces" {
    const expected: []const u8 = "T R L";
    const actual = try rotate(testing.allocator, "O M G", 5);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "rotate numbers" {
    const expected: []const u8 = "Xiwxmrk 1 2 3 xiwxmrk";
    const actual = try rotate(testing.allocator, "Testing 1 2 3 testing", 4);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "rotate punctuation" {
    const expected: []const u8 = "Gzo'n zvo, Bmviyhv!";
    const actual = try rotate(testing.allocator, "Let's eat, Grandma!", 21);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "rotate all letters" {
    const expected: []const u8 = "Gur dhvpx oebja sbk whzcf bire gur ynml qbt.";
    const actual = try rotate(testing.allocator, "The quick brown fox jumps over the lazy dog.", 13);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}
