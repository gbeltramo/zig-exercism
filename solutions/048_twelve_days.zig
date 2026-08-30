const std = @import("std");
const mem = std.mem;
const testing = std.testing;

var memory_buffer: [8_192]u8 = undefined;

const LyricsError = error{InvalidStartEndVerse};

const prefix = "On the {s} day of Christmas my true love gave to me: ";

const ordinals = [12][]const u8{
    "first",
    "second",
    "third",
    "fourth",
    "fifth",
    "sixth",
    "seventh",
    "eighth",
    "ninth",
    "tenth",
    "eleventh",
    "twelfth",
};

const things = [12][]const u8{
    "a Partridge in a Pear Tree.",
    "two Turtle Doves",
    "three French Hens",
    "four Calling Birds",
    "five Gold Rings",
    "six Geese-a-Laying",
    "seven Swans-a-Swimming",
    "eight Maids-a-Milking",
    "nine Ladies Dancing",
    "ten Lords-a-Leaping",
    "eleven Pipers Piping",
    "twelve Drummers Drumming",
};

/// Return the verse at a given index.
/// Caller owns the returned memory.
pub fn verse(allocator: mem.Allocator, idx_verse: usize) ![]u8 {
    var list = try std.ArrayList([]const u8).initCapacity(allocator, 1);
    defer list.deinit(allocator);

    const ordinal = ordinals[idx_verse - 1];
    const start_sentence = try std.fmt.allocPrint(allocator, prefix, .{ordinal});
    defer allocator.free(start_sentence);
    try list.append(allocator, start_sentence);

    for (0..idx_verse) |idx| {
        try list.append(allocator, things[idx]);
        if ((idx_verse > 1) and (idx == 0)) {
            try list.append(allocator, "and ");
        }

        if ((idx_verse - 1) != idx) {
            try list.append(allocator, ", ");
        }
    }

    std.mem.reverse([]const u8, list.items[1..]);

    const out = try std.mem.join(allocator, "", list.items);
    return out;
}

pub fn recite(buffer: []u8, start_verse: u32, end_verse: u32) ![]const u8 {
    if (start_verse < 1) return LyricsError.InvalidStartEndVerse;
    if (start_verse > 12) return LyricsError.InvalidStartEndVerse;
    if (end_verse < 1) return LyricsError.InvalidStartEndVerse;
    if (end_verse > 12) return LyricsError.InvalidStartEndVerse;

    var fba: std.heap.FixedBufferAllocator = .init(&memory_buffer);
    const allocator = fba.allocator();

    var lyrics_length: usize = 0;
    for (start_verse..end_verse + 1) |idx_verse| {
        const current_verse = try verse(allocator, idx_verse);
        @memcpy(buffer[lyrics_length .. lyrics_length + current_verse.len], current_verse);
        defer allocator.free(current_verse);

        lyrics_length += current_verse.len;

        if (idx_verse != end_verse) {
            @memcpy(buffer[lyrics_length .. lyrics_length + 1], "\n");
            lyrics_length += 1;
        }
    }

    return buffer[0..lyrics_length];
}

fn testRecite(expected: []const u8, start_verse: u32, end_verse: u32) !void {
    var buffer: [2369]u8 = undefined;
    const actual = try recite(&buffer, start_verse, end_verse);
    try testing.expectEqual(@as([*]const u8, &buffer), actual.ptr);
    try testing.expectEqualStrings(expected, actual);
}

test "verse-first day a partridge in a pear tree" {
    try testRecite(
        \\On the first day of Christmas my true love gave to me: a Partridge in a Pear Tree.
    , 1, 1);
}

test "verse-second day two turtle doves" {
    try testRecite(
        \\On the second day of Christmas my true love gave to me: two Turtle Doves, and a Partridge in a Pear Tree.
    , 2, 2);
}

test "verse-third day three french hens" {
    try testRecite(
        \\On the third day of Christmas my true love gave to me: three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 3, 3);
}

test "verse-fourth day four calling birds" {
    try testRecite(
        \\On the fourth day of Christmas my true love gave to me: four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 4, 4);
}

test "verse-fifth day five gold rings" {
    try testRecite(
        \\On the fifth day of Christmas my true love gave to me: five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 5, 5);
}

test "verse-sixth day six geese-a-laying" {
    try testRecite(
        \\On the sixth day of Christmas my true love gave to me: six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 6, 6);
}

test "verse-seventh day seven swans-a-swimming" {
    try testRecite(
        \\On the seventh day of Christmas my true love gave to me: seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 7, 7);
}

test "verse-eighth day eight maids-a-milking" {
    try testRecite(
        \\On the eighth day of Christmas my true love gave to me: eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 8, 8);
}

test "verse-ninth day nine ladies dancing" {
    try testRecite(
        \\On the ninth day of Christmas my true love gave to me: nine Ladies Dancing, eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 9, 9);
}

test "verse-tenth day ten lords-a-leaping" {
    try testRecite(
        \\On the tenth day of Christmas my true love gave to me: ten Lords-a-Leaping, nine Ladies Dancing, eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 10, 10);
}

test "verse-eleventh day eleven pipers piping" {
    try testRecite(
        \\On the eleventh day of Christmas my true love gave to me: eleven Pipers Piping, ten Lords-a-Leaping, nine Ladies Dancing, eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 11, 11);
}

test "verse-twelfth day twelve drummers drumming" {
    try testRecite(
        \\On the twelfth day of Christmas my true love gave to me: twelve Drummers Drumming, eleven Pipers Piping, ten Lords-a-Leaping, nine Ladies Dancing, eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 12, 12);
}

test "lyrics-recites first three verses of the song" {
    try testRecite(
        \\On the first day of Christmas my true love gave to me: a Partridge in a Pear Tree.
        \\On the second day of Christmas my true love gave to me: two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the third day of Christmas my true love gave to me: three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 1, 3);
}

test "lyrics-recites three verses from the middle of the song" {
    try testRecite(
        \\On the fourth day of Christmas my true love gave to me: four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the fifth day of Christmas my true love gave to me: five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the sixth day of Christmas my true love gave to me: six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 4, 6);
}

test "lyrics-recites the whole song" {
    try testRecite(
        \\On the first day of Christmas my true love gave to me: a Partridge in a Pear Tree.
        \\On the second day of Christmas my true love gave to me: two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the third day of Christmas my true love gave to me: three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the fourth day of Christmas my true love gave to me: four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the fifth day of Christmas my true love gave to me: five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the sixth day of Christmas my true love gave to me: six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the seventh day of Christmas my true love gave to me: seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the eighth day of Christmas my true love gave to me: eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the ninth day of Christmas my true love gave to me: nine Ladies Dancing, eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the tenth day of Christmas my true love gave to me: ten Lords-a-Leaping, nine Ladies Dancing, eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the eleventh day of Christmas my true love gave to me: eleven Pipers Piping, ten Lords-a-Leaping, nine Ladies Dancing, eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
        \\On the twelfth day of Christmas my true love gave to me: twelve Drummers Drumming, eleven Pipers Piping, ten Lords-a-Leaping, nine Ladies Dancing, eight Maids-a-Milking, seven Swans-a-Swimming, six Geese-a-Laying, five Gold Rings, four Calling Birds, three French Hens, two Turtle Doves, and a Partridge in a Pear Tree.
    , 1, 12);
}
