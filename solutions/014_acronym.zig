const std = @import("std");
const testing = std.testing;
const mem = std.mem;

const cache_line = std.atomic.cache_line;

pub fn abbreviate(allocator: mem.Allocator, words: []const u8) mem.Allocator.Error![]align(cache_line) u8 {
    var stack = try std.ArrayListAlignedUnmanaged(
        u8,
        mem.Alignment.fromByteUnits(cache_line),
    ).initCapacity(allocator, 8);
    defer stack.deinit(allocator);

    var it = std.mem.tokenizeAny(u8, words, " -");
    while (it.next()) |word| {
        loop: for (word) |c| {
            if (std.ascii.isAlphabetic(c)) {
                try stack.append(allocator, std.ascii.toUpper(c));
                break :loop;
            }
        }
    }

    return stack.toOwnedSlice(allocator);
}

test "basic" {
    const expected = "PNG";
    const actual = try abbreviate(testing.allocator, "Portable Network Graphics");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "lowercase words" {
    const expected = "ROR";
    const actual = try abbreviate(testing.allocator, "Ruby on Rails");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "punctuation" {
    const expected = "FIFO";
    const actual = try abbreviate(testing.allocator, "First In, First Out");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "all caps word" {
    const expected = "GIMP";
    const actual = try abbreviate(testing.allocator, "GNU Image Manipulation Program");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "punctuation without whitespace" {
    const expected = "CMOS";
    const actual = try abbreviate(testing.allocator, "Complementary metal-oxide semiconductor");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "very long abbreviation" {
    const expected = "ROTFLSHTMDCOALM";
    const actual = try abbreviate(testing.allocator, "Rolling On The Floor Laughing So Hard That My Dogs Came Over And Licked Me");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "consecutive delimiters" {
    const expected = "SIMUFTA";
    const actual = try abbreviate(testing.allocator, "Something - I made up from thin air");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "apostrophes" {
    const expected = "HC";
    const actual = try abbreviate(testing.allocator, "Halley's Comet");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "underscore emphasis" {
    const expected = "TRNT";
    const actual = try abbreviate(testing.allocator, "The Road _Not_ Taken");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}
