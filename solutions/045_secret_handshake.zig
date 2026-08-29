const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const Signal = enum(u5) {
    wink = 0,
    double_blink = 1,
    close_your_eyes = 2,
    jump = 3,
    reverse = 4,
};

pub fn calculateHandshake(allocator: mem.Allocator, number: u5) mem.Allocator.Error![]const Signal {
    var n = number;
    var bits = [5]bool{ false, false, false, false, false };
    var length: usize = 0;
    for (0..5) |pow| {
        const x: u5 = std.math.pow(u5, 2, @as(u5, @intCast(4 - pow)));
        if (n >= x) {
            n -= x;
            bits[pow] = true;
            if (pow != 0) length += 1;
        }
    }

    const out = try allocator.alloc(Signal, length);
    var idx_out: usize = 0;
    for (0..4) |idx| {
        if (bits[4 - idx]) {
            const signal: Signal = @enumFromInt(idx);
            out[idx_out] = signal;
            idx_out += 1;
        }
    }

    if (bits[0]) std.mem.reverse(Signal, out);

    return out;
}

test "wink for 1" {
    const expected = &[_]Signal{.wink};
    const actual = try calculateHandshake(testing.allocator, 1);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "double blink for 10" {
    const expected = &[_]Signal{.double_blink};
    const actual = try calculateHandshake(testing.allocator, 2);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "close your eyes for 100" {
    const expected = &[_]Signal{.close_your_eyes};
    const actual = try calculateHandshake(testing.allocator, 4);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "jump for 1000" {
    const expected = &[_]Signal{.jump};
    const actual = try calculateHandshake(testing.allocator, 8);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "combine two actions" {
    const expected = &[_]Signal{ .wink, .double_blink };
    const actual = try calculateHandshake(testing.allocator, 3);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "reverse two actions" {
    const expected = &[_]Signal{ .double_blink, .wink };
    const actual = try calculateHandshake(testing.allocator, 19);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "reversing one action gives the same action" {
    const expected = &[_]Signal{.jump};
    const actual = try calculateHandshake(testing.allocator, 24);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "reversing no actions still gives no actions" {
    const expected = &[_]Signal{};
    const actual = try calculateHandshake(testing.allocator, 16);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "all possible actions" {
    const expected = &[_]Signal{ .wink, .double_blink, .close_your_eyes, .jump };
    const actual = try calculateHandshake(testing.allocator, 15);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "reverse all possible actions" {
    const expected = &[_]Signal{ .jump, .close_your_eyes, .double_blink, .wink };
    const actual = try calculateHandshake(testing.allocator, 31);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}

test "do nothing for zero" {
    const expected = &[_]Signal{};
    const actual = try calculateHandshake(testing.allocator, 0);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Signal, expected, actual);
}
