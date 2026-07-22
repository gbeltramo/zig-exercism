const std = @import("std");
const testing = std.testing;

const buffer_size = 100;

pub fn twoFer(buffer: []u8, name: ?[]const u8) ![]u8 {
    const who = name orelse "you";
    return try std.fmt.bufPrint(
        buffer,
        "One for {s}, one for me.",
        .{who},
    );
}

test "no name given" {
    var response: [buffer_size]u8 = undefined;
    const expected = "One for you, one for me.";
    const actual = try twoFer(&response, null);
    try testing.expectEqualStrings(expected, actual);
}

test "a name given" {
    var response: [buffer_size]u8 = undefined;
    const expected = "One for Alice, one for me.";
    const actual = try twoFer(&response, "Alice");
    try testing.expectEqualStrings(expected, actual);
}

test "another name given" {
    var response: [buffer_size]u8 = undefined;
    const expected = "One for Bob, one for me.";
    const actual = try twoFer(&response, "Bob");
    try testing.expectEqualStrings(expected, actual);
}
