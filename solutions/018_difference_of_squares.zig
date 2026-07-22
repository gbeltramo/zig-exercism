const std = @import("std");
const testing = std.testing;

pub fn squareOfSum(number: usize) usize {
    const total: usize = number * (number + 1) / 2;
    return total * total;
}

pub fn sumOfSquares(number: usize) usize {
    // closed form formula: number * (number + 1) * (2 * number + 1) / 6;
    var total: usize = 0;
    for (1..number + 1) |n| {
        total += n * n;
    }

    return total;
}

pub fn differenceOfSquares(number: usize) usize {
    return squareOfSum(number) - sumOfSquares(number);
}

test "square of sum up to 1" {
    const expected: usize = 1;
    const actual = squareOfSum(1);
    try testing.expectEqual(expected, actual);
}

test "square of sum up to 5" {
    const expected: usize = 225;
    const actual = squareOfSum(5);
    try testing.expectEqual(expected, actual);
}

test "square of sum up to 100" {
    const expected: usize = 25_502_500;
    const actual = squareOfSum(100);
    try testing.expectEqual(expected, actual);
}

test "sum of squares up to 1" {
    const expected: usize = 1;
    const actual = sumOfSquares(1);
    try testing.expectEqual(expected, actual);
}

test "sum of squares up to 5" {
    const expected: usize = 55;
    const actual = sumOfSquares(5);
    try testing.expectEqual(expected, actual);
}

test "sum of squares up to 100" {
    const expected: usize = 338_350;
    const actual = sumOfSquares(100);
    try testing.expectEqual(expected, actual);
}

test "difference of squares up to 1" {
    const expected: usize = 0;
    const actual = differenceOfSquares(1);
    try testing.expectEqual(expected, actual);
}

test "difference of squares up to 5" {
    const expected: usize = 170;
    const actual = differenceOfSquares(5);
    try testing.expectEqual(expected, actual);
}

test "difference of squares up to 100" {
    const expected: usize = 25_164_150;
    const actual = differenceOfSquares(100);
    try testing.expectEqual(expected, actual);
}
