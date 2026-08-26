const std = @import("std");
const testing = std.testing;

pub const Classification = enum {
    deficient,
    perfect,
    abundant,
};

pub fn classify(n: u64) Classification {
    std.debug.assert(n != 0);

    const max_int: u64 = @divFloor(n, 2);
    var sum: u64 = 0;
    for (1..max_int + 1) |i| {
        const is_div = (n % i) == 0;
        sum += i * @intFromBool(is_div);
    }

    if (sum == n) {
        return Classification.perfect;
    } else if (sum < n) {
        return Classification.deficient;
    } else {
        return Classification.abundant;
    }
}

test "smallest perfect number is classified correctly" {
    const expected = Classification.perfect;
    const actual = classify(6);
    try testing.expectEqual(expected, actual);
}

test "medium perfect number is classified correctly" {
    const expected = Classification.perfect;
    const actual = classify(28);
    try testing.expectEqual(expected, actual);
}

test "large perfect number is classified correctly" {
    const expected = Classification.perfect;
    const actual = classify(33_550_336);
    try testing.expectEqual(expected, actual);
}

test "smallest abundant number is classified correctly" {
    const expected = Classification.abundant;
    const actual = classify(12);
    try testing.expectEqual(expected, actual);
}

test "medium abundant number is classified correctly" {
    const expected = Classification.abundant;
    const actual = classify(30);
    try testing.expectEqual(expected, actual);
}

test "large abundant number is classified correctly" {
    const expected = Classification.abundant;
    const actual = classify(33_550_335);
    try testing.expectEqual(expected, actual);
}

test "perfect square abundant number is classified correctly" {
    const expected = Classification.abundant;
    const actual = classify(196);
    try testing.expectEqual(expected, actual);
}

test "smallest prime deficient number is classified correctly" {
    const expected = Classification.deficient;
    const actual = classify(2);
    try testing.expectEqual(expected, actual);
}

test "smallest non-prime deficient number is classified correctly" {
    const expected = Classification.deficient;
    const actual = classify(4);
    try testing.expectEqual(expected, actual);
}

test "medium deficient number is classified correctly" {
    const expected = Classification.deficient;
    const actual = classify(32);
    try testing.expectEqual(expected, actual);
}

test "large deficient number is classified correctly" {
    const expected = Classification.deficient;
    const actual = classify(33_550_337);
    try testing.expectEqual(expected, actual);
}

test "edge case (no factors other than itself) is classified correctly" {
    const expected = Classification.deficient;
    const actual = classify(1);
    try testing.expectEqual(expected, actual);
}
