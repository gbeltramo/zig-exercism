const std = @import("std");
const testing = std.testing;

pub fn hello() []const u8 {
    return "Hello, World!";
}

test "says hello" {
    try testing.expectEqualStrings("Hello, World!", hello());
}
