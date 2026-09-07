const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const BUFFER_LEN: usize = 10_001;
const MAX_NUMBER: usize = 104_743;

pub fn primes(buffer: []usize, limit: usize) []usize {
    var mask: [MAX_NUMBER - 1]bool = undefined;
    for (2..MAX_NUMBER + 1) |n| mask[n - 2] = true;

    for (2..@as(usize, @intCast(limit + 1))) |n| {
        var current_multiple: usize = 2 * n;
        while (current_multiple <= limit) : (current_multiple += n) {
            mask[current_multiple - 2] = false;
        }
    }

    var idx_prime: usize = 0;
    for (2..@as(usize, @intCast(limit + 1))) |n| {
        if (idx_prime >= buffer.len) break;
        if (mask[n - 2]) {
            buffer[idx_prime] = @intCast(n);
            idx_prime += 1;
        }
    }

    return buffer[0..idx_prime];
}

pub fn prime(allocator: mem.Allocator, number: usize) !usize {
    const buf = try allocator.alloc(u8, 1);
    defer allocator.free(buf);

    var buffer: [BUFFER_LEN]usize = undefined;
    const result = primes(&buffer, MAX_NUMBER);

    return result[number - 1];
}

test "first prime" {
    const p = try prime(testing.allocator, 1);
    try testing.expectEqual(2, p);
}

test "second prime" {
    const p = try prime(testing.allocator, 2);
    try testing.expectEqual(3, p);
}

test "third prime" {
    const p = try prime(testing.allocator, 3);
    try testing.expectEqual(5, p);
}

test "fourth prime" {
    const p = try prime(testing.allocator, 4);
    try testing.expectEqual(7, p);
}

test "fifth prime" {
    const p = try prime(testing.allocator, 5);
    try testing.expectEqual(11, p);
}

test "sixth prime" {
    const p = try prime(testing.allocator, 6);
    try testing.expectEqual(13, p);
}

test "seventh prime" {
    const p = try prime(testing.allocator, 7);
    try testing.expectEqual(17, p);
}

test "big prime" {
    const p = try prime(testing.allocator, 10_001);
    try testing.expectEqual(104_743, p);
}
