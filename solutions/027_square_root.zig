const std = @import("std");
const testing = std.testing;

pub fn squareRoot(radicand: usize) usize {
    const rad: f64 = @floatFromInt(radicand);

    const approx_power_radicand: usize = @intCast(@typeInfo(usize).int.bits - 1 - @clz(radicand));
    const float_power: f64 = @floatFromInt((approx_power_radicand / 2) + 1);
    const seed: f64 = std.math.pow(f64, 2.0, float_power);

    const epsilon: f64 = 0.475;
    var x_n: f64 = seed;
    var count: usize = 0;
    while (@abs(x_n * x_n - rad) >= epsilon) {
        x_n = (x_n + rad / x_n) / 2.0;
        count += 1;
    }

    const res: usize = @intFromFloat(@round(x_n));
    // std.debug.print("radicand: {d} | approx_power_radicand: {d} | power: {d} | seed: {d} | x_n: {d} | Num iterations: {d}\n", .{
    //     radicand,
    //     approx_power_radicand,
    //     float_power,
    //     seed,
    //     x_n,
    //     count,
    // });

    return res;
}

test "root of 1" {
    const expected: usize = 1;
    const actual = squareRoot(1);
    try testing.expectEqual(expected, actual);
}

test "root of 4" {
    const expected: usize = 2;
    const actual = squareRoot(4);
    try testing.expectEqual(expected, actual);
}

test "root of 25" {
    const expected: usize = 5;
    const actual = squareRoot(25);
    try testing.expectEqual(expected, actual);
}

test "root of 81" {
    const expected: usize = 9;
    const actual = squareRoot(81);
    try testing.expectEqual(expected, actual);
}

test "root of 196" {
    const expected: usize = 14;
    const actual = squareRoot(196);
    try testing.expectEqual(expected, actual);
}

test "root of 65025" {
    const expected: usize = 255;
    const actual = squareRoot(65025);
    try testing.expectEqual(expected, actual);
}
