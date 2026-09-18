const std = @import("std");
const testing = std.testing;

const Animal = struct {
    name: []const u8,
    comment: ?[]const u8 = null,
    chain_note: []const u8 = "",
};

const animals = [_]Animal{
    .{ .name = "fly" },
    .{
        .name = "spider",
        .comment = "It wriggled and jiggled and tickled inside her.",
        .chain_note = " that wriggled and jiggled and tickled inside her",
    },
    .{ .name = "bird", .comment = "How absurd to swallow a bird!" },
    .{ .name = "cat", .comment = "Imagine that, to swallow a cat!" },
    .{ .name = "dog", .comment = "What a hog, to swallow a dog!" },
    .{ .name = "goat", .comment = "Just opened her throat and swallowed a goat!" },
    .{ .name = "cow", .comment = "I don't know how she swallowed a cow!" },
    .{ .name = "horse" },
};

pub fn recite(buffer: []u8, start_verse: u32, end_verse: u32) ![]const u8 {
    std.debug.assert(start_verse >= 1);
    std.debug.assert(end_verse >= start_verse);
    std.debug.assert(end_verse <= animals.len);

    var writer = std.Io.Writer.fixed(buffer);
    var verse: u32 = start_verse;
    while (verse <= end_verse) : (verse += 1) {
        try writeVerse(&writer, verse);
        if (verse != end_verse) {
            try writer.writeAll("\n\n");
        }
    }
    try writer.flush();

    return writer.buffered();
}

fn writeVerse(writer: *std.Io.Writer, verse: u32) !void {
    const idx = verse - 1;
    const animal = animals[idx];

    try writer.print("I know an old lady who swallowed a {s}.\n", .{animal.name});

    if (idx == animals.len - 1) {
        try writer.writeAll("She's dead, of course!");
        return;
    }

    if (animal.comment) |c| {
        try writer.print("{s}\n", .{c});
    }

    var j = idx;
    while (j >= 1) : (j -= 1) {
        const predator = animals[j].name;
        const prey = animals[j - 1];
        try writer.print(
            "She swallowed the {s} to catch the {s}{s}.\n",
            .{ predator, prey.name, prey.chain_note },
        );

        if (j == 1) break;
    }

    try writer.writeAll("I don't know why she swallowed the fly. Perhaps she'll die.");
}

fn testRecite(expected: []const u8, start_verse: u32, end_verse: u32) !void {
    var buffer: [2129]u8 = undefined;
    const actual = try recite(&buffer, start_verse, end_verse);
    try testing.expectEqual(@as([*]const u8, &buffer), actual.ptr);
    try testing.expectEqualStrings(expected, actual);
}

test "fly" {
    try testRecite(
        \\I know an old lady who swallowed a fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
    , 1, 1);
}

test "spider" {
    try testRecite(
        \\I know an old lady who swallowed a spider.
        \\It wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
    , 2, 2);
}

test "bird" {
    try testRecite(
        \\I know an old lady who swallowed a bird.
        \\How absurd to swallow a bird!
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
    , 3, 3);
}

test "cat" {
    try testRecite(
        \\I know an old lady who swallowed a cat.
        \\Imagine that, to swallow a cat!
        \\She swallowed the cat to catch the bird.
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
    , 4, 4);
}

test "dog" {
    try testRecite(
        \\I know an old lady who swallowed a dog.
        \\What a hog, to swallow a dog!
        \\She swallowed the dog to catch the cat.
        \\She swallowed the cat to catch the bird.
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
    , 5, 5);
}

test "goat" {
    try testRecite(
        \\I know an old lady who swallowed a goat.
        \\Just opened her throat and swallowed a goat!
        \\She swallowed the goat to catch the dog.
        \\She swallowed the dog to catch the cat.
        \\She swallowed the cat to catch the bird.
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
    , 6, 6);
}

test "cow" {
    try testRecite(
        \\I know an old lady who swallowed a cow.
        \\I don't know how she swallowed a cow!
        \\She swallowed the cow to catch the goat.
        \\She swallowed the goat to catch the dog.
        \\She swallowed the dog to catch the cat.
        \\She swallowed the cat to catch the bird.
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
    , 7, 7);
}

test "horse" {
    try testRecite(
        \\I know an old lady who swallowed a horse.
        \\She's dead, of course!
    , 8, 8);
}

test "multiple verses" {
    try testRecite(
        \\I know an old lady who swallowed a fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
        \\
        \\I know an old lady who swallowed a spider.
        \\It wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
        \\
        \\I know an old lady who swallowed a bird.
        \\How absurd to swallow a bird!
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
    , 1, 3);
}

test "full song" {
    try testRecite(
        \\I know an old lady who swallowed a fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
        \\
        \\I know an old lady who swallowed a spider.
        \\It wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
        \\
        \\I know an old lady who swallowed a bird.
        \\How absurd to swallow a bird!
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
        \\
        \\I know an old lady who swallowed a cat.
        \\Imagine that, to swallow a cat!
        \\She swallowed the cat to catch the bird.
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
        \\
        \\I know an old lady who swallowed a dog.
        \\What a hog, to swallow a dog!
        \\She swallowed the dog to catch the cat.
        \\She swallowed the cat to catch the bird.
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
        \\
        \\I know an old lady who swallowed a goat.
        \\Just opened her throat and swallowed a goat!
        \\She swallowed the goat to catch the dog.
        \\She swallowed the dog to catch the cat.
        \\She swallowed the cat to catch the bird.
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
        \\
        \\I know an old lady who swallowed a cow.
        \\I don't know how she swallowed a cow!
        \\She swallowed the cow to catch the goat.
        \\She swallowed the goat to catch the dog.
        \\She swallowed the dog to catch the cat.
        \\She swallowed the cat to catch the bird.
        \\She swallowed the bird to catch the spider that wriggled and jiggled and tickled inside her.
        \\She swallowed the spider to catch the fly.
        \\I don't know why she swallowed the fly. Perhaps she'll die.
        \\
        \\I know an old lady who swallowed a horse.
        \\She's dead, of course!
    , 1, 8);
}
