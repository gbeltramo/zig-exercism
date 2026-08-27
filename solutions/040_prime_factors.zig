const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const MAX_NUM_FACTORS: usize = 32;

pub fn factors(allocator: mem.Allocator, value: u64) mem.Allocator.Error![]u64 {
    const buffer = try allocator.alloc(u64, MAX_NUM_FACTORS);
    defer allocator.free(buffer);

    var current_value: u64 = value;
    var length_factors: usize = 0;
    while (current_value > 1) {
        const max_divisor: u64 = @max(std.math.sqrt(current_value), 10);
        inner_loop: for (2..max_divisor) |x| {
            if ((current_value % x) == 0) {
                buffer[length_factors] = x;
                length_factors += 1;
                current_value = @divExact(current_value, x);
                break :inner_loop;
            }
        } else {
            buffer[length_factors] = current_value;
            length_factors += 1;
            current_value = 1;
        }
    }

    const out = try allocator.alloc(u64, length_factors);
    @memcpy(out, buffer[0..length_factors]);
    return out;
}

test "no factors" {
    const expected = [_]u64{};
    const actual = try factors(testing.allocator, 1);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "prime number" {
    const expected = [_]u64{2};
    const actual = try factors(testing.allocator, 2);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "another prime number" {
    const expected = [_]u64{3};
    const actual = try factors(testing.allocator, 3);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "square of a prime" {
    const expected = [_]u64{ 3, 3 };
    const actual = try factors(testing.allocator, 9);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "product of first prime" {
    const expected = [_]u64{ 2, 2 };
    const actual = try factors(testing.allocator, 4);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "cube of a prime" {
    const expected = [_]u64{ 2, 2, 2 };
    const actual = try factors(testing.allocator, 8);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "product of second prime" {
    const expected = [_]u64{ 3, 3, 3 };
    const actual = try factors(testing.allocator, 27);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "product of third prime" {
    const expected = [_]u64{ 5, 5, 5, 5 };
    const actual = try factors(testing.allocator, 625);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "product of first and second prime" {
    const expected = [_]u64{ 2, 3 };
    const actual = try factors(testing.allocator, 6);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "product of primes and non-primes" {
    const expected = [_]u64{ 2, 2, 3 };
    const actual = try factors(testing.allocator, 12);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "product of primes" {
    const expected = [_]u64{ 5, 17, 23, 461 };
    const actual = try factors(testing.allocator, 901255);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "factors include a large prime" {
    const expected = [_]u64{ 11, 9539, 894119 };
    const actual = try factors(testing.allocator, 93819012551);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "product of three large primes" {
    const expected = [_]u64{ 2077681, 2099191, 2101243 };
    const actual = try factors(testing.allocator, 9164464719174396253);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "one very large prime" {
    const expected = [_]u64{4016465016163};
    const actual = try factors(testing.allocator, 4016465016163);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}
