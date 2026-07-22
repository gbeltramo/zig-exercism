const std = @import("std");
const testing = std.testing;

pub const ComputationError = error{IllegalArgument};

pub fn steps(number: usize) ComputationError!usize {
    if (number == 0) {
        return ComputationError.IllegalArgument;
    }

    var count: usize = 0;
    var current: usize = number;
    while (current != 1) {
        current = if ((current % 2) == 0) current / 2 else (3 * current + 1);
        count += 1;
    }
    return count;
}

test "zero steps for one" {
    const expected: usize = 0;
    const actual = try steps(1);
    try testing.expectEqual(expected, actual);
}
test "divide if even" {
    const expected: usize = 4;
    const actual = try steps(16);
    try testing.expectEqual(expected, actual);
}
test "even and odd steps" {
    const expected: usize = 9;
    const actual = try steps(12);
    try testing.expectEqual(expected, actual);
}
test "large number of even and odd steps" {
    const expected: usize = 152;
    const actual = try steps(1_000_000);
    try testing.expectEqual(expected, actual);
}
test "zero is an error" {
    const expected = ComputationError.IllegalArgument;
    const actual = steps(0);
    try testing.expectError(expected, actual);
}
