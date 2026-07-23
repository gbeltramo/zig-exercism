const std = @import("std");
const testing = std.testing;

pub const ColorBand = enum(u4) {
    black = 0,
    brown = 1,
    red = 2,
    orange = 3,
    yellow = 4,
    green = 5,
    blue = 6,
    violet = 7,
    grey = 8,
    white = 9,
};

pub fn colorCode(color: ColorBand) usize {
    return @intFromEnum(color);
}

pub fn colors() []const ColorBand {
    return &[10]ColorBand{ .black, .brown, .red, .orange, .yellow, .green, .blue, .violet, .grey, .white };
}

test "black" {
    const expected: usize = 0;
    const actual = colorCode(.black);
    try testing.expectEqual(expected, actual);
}

test "white" {
    const expected: usize = 9;
    const actual = colorCode(.white);
    try testing.expectEqual(expected, actual);
}

test "orange" {
    const expected: usize = 3;
    const actual = colorCode(.orange);
    try testing.expectEqual(expected, actual);
}

test "colors" {
    const expected = &[_]ColorBand{
        .black, .brown, .red,    .orange, .yellow,
        .green, .blue,  .violet, .grey,   .white,
    };
    const actual = colors();
    try testing.expectEqualSlices(ColorBand, expected, actual);
}
