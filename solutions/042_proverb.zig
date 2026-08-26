const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const testing = std.testing;

pub fn recite(allocator: mem.Allocator, words: []const []const u8) mem.Allocator.Error![][]u8 {
    var list = try std.ArrayList([]u8).initCapacity(allocator, words.len);
    errdefer {
        for (list.items) |s| allocator.free(s);
        list.deinit(allocator);
    }

    if (words.len == 0) return list.toOwnedSlice(allocator);

    for (0..words.len - 1) |idx| {
        const word0 = words[idx];
        const word1 = words[idx + 1];
        const new_sentence = try std.fmt.allocPrint(allocator, "For want of a {s} the {s} was lost.\n", .{ word0, word1 });
        errdefer allocator.free(new_sentence);
        try list.append(allocator, new_sentence);
    }

    const final_sentence = try std.fmt.allocPrint(allocator, "And all for the want of a {s}.\n", .{words[0]});
    errdefer allocator.free(final_sentence);
    try list.append(allocator, final_sentence);

    return list.toOwnedSlice(allocator);
}

fn free(slices: [][]u8) void {
    for (slices) |s| {
        testing.allocator.free(s);
    }
    testing.allocator.free(slices); // No problem when `slices` has zero length.
}

fn reciteTest(allocator: std.mem.Allocator, input: []const []const u8, expected: []const []const u8) anyerror!void {
    const actual = try recite(allocator, input);
    defer free(actual);
    for (expected, 0..) |expected_slice, i| {
        try testing.expectEqualSlices(u8, expected_slice, actual[i]);
    }
}

test "zero pieces" {
    const input = [_][]const u8{};
    const expected = [_][]const u8{};
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        reciteTest,
        .{ &input, &expected },
    );
}

test "one piece" {
    const input = [_][]const u8{
        "nail",
    };
    const expected = [_][]const u8{
        "And all for the want of a nail.\n",
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        reciteTest,
        .{ &input, &expected },
    );
}

test "two pieces" {
    const input = [_][]const u8{
        "nail",
        "shoe",
    };
    const expected = [_][]const u8{
        "For want of a nail the shoe was lost.\n",
        "And all for the want of a nail.\n",
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        reciteTest,
        .{ &input, &expected },
    );
}

test "three pieces" {
    const input = [_][]const u8{
        "nail",
        "shoe",
        "horse",
    };
    const expected = [_][]const u8{
        "For want of a nail the shoe was lost.\n",
        "For want of a shoe the horse was lost.\n",
        "And all for the want of a nail.\n",
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        reciteTest,
        .{ &input, &expected },
    );
}

test "full proverb" {
    const input = [_][]const u8{
        "nail",
        "shoe",
        "horse",
        "rider",
        "message",
        "battle",
        "kingdom",
    };
    const expected = [_][]const u8{
        "For want of a nail the shoe was lost.\n",
        "For want of a shoe the horse was lost.\n",
        "For want of a horse the rider was lost.\n",
        "For want of a rider the message was lost.\n",
        "For want of a message the battle was lost.\n",
        "For want of a battle the kingdom was lost.\n",
        "And all for the want of a nail.\n",
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        reciteTest,
        .{ &input, &expected },
    );
}

test "four pieces modernized" {
    const input = [_][]const u8{
        "pin",
        "gun",
        "soldier",
        "battle",
    };
    const expected = [_][]const u8{
        "For want of a pin the gun was lost.\n",
        "For want of a gun the soldier was lost.\n",
        "For want of a soldier the battle was lost.\n",
        "And all for the want of a pin.\n",
    };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        reciteTest,
        .{ &input, &expected },
    );
}
