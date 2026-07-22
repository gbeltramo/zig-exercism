const std = @import("std");
const testing = std.testing;

pub fn eggCount(number: usize) usize {
    var count: usize = 0;
    var n = number;
    while (n > 0) {
        if (n & 1 != 0) {
            count += 1;
        }
        n /= 2;
    }
    return count;
}

test "0 eggs" {
    const expected: usize = 0;
    const actual = eggCount(0);
    try testing.expectEqual(expected, actual);
}

test "1 egg" {
    const expected: usize = 1;
    const actual = eggCount(16);
    try testing.expectEqual(expected, actual);
}

test "4 eggs" {
    const expected: usize = 4;
    const actual = eggCount(89);
    try testing.expectEqual(expected, actual);
}

test "13 eggs" {
    const expected: usize = 13;
    const actual = eggCount(2000000000);
    try testing.expectEqual(expected, actual);
}
