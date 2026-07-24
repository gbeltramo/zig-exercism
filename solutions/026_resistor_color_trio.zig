const std = @import("std");
const testing = std.testing;
const mem = std.mem;

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

pub fn label(allocator: mem.Allocator, colors: []const ColorBand) mem.Allocator.Error![]u8 {
    const digit0: usize = @intCast(@intFromEnum(colors[0]));
    const digit1: usize = @intCast(@intFromEnum(colors[1]));
    const power_of_ten: usize = @intCast(@intFromEnum(colors[2]));

    const ohms: usize = (digit0 * 10 + digit1) * std.math.pow(usize, 10, power_of_ten);

    var prefix: []const u8 = "";
    var divisor: usize = 1;

    if (ohms >= 1_000_000_000) {
        prefix = "giga";
        divisor = 1_000_000_000;
    } else if (ohms >= 1_000_000) {
        prefix = "mega";
        divisor = 1_000_000;
    } else if (ohms >= 1_000) {
        prefix = "kilo";
        divisor = 1_000;
    }

    const whole = ohms / divisor;
    const remainder = ohms % divisor;

    if (remainder == 0) {
        return std.fmt.allocPrint(allocator, "{d} {s}ohms", .{ whole, prefix });
    } else {
        var frac = remainder;
        var frac_divisor = divisor;
        while (frac % 10 == 0) {
            frac /= 10;
            frac_divisor /= 10;
        }
        return std.fmt.allocPrint(allocator, "{d}.{d} {s}ohms", .{ whole, frac, prefix });
    }
}

fn labelTest(allocator: std.mem.Allocator, colors: []const ColorBand, expected: []const u8) anyerror!void {
    const actual = try label(allocator, colors);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "Orange and orange and black" {
    const colors = [_]ColorBand{ .orange, .orange, .black };
    const expected: []const u8 = "33 ohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Blue and grey and brown" {
    const colors = [_]ColorBand{ .blue, .grey, .brown };
    const expected: []const u8 = "680 ohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Red and black and red" {
    const colors = [_]ColorBand{ .red, .black, .red };
    const expected: []const u8 = "2 kiloohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Green and brown and orange" {
    const colors = [_]ColorBand{ .green, .brown, .orange };
    const expected: []const u8 = "51 kiloohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Yellow and violet and yellow" {
    const colors = [_]ColorBand{ .yellow, .violet, .yellow };
    const expected: []const u8 = "470 kiloohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Blue and violet and blue" {
    const colors = [_]ColorBand{ .blue, .violet, .blue };
    const expected: []const u8 = "67 megaohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Minimum possible value" {
    const colors = [_]ColorBand{ .black, .black, .black };
    const expected: []const u8 = "0 ohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Maximum possible value" {
    const colors = [_]ColorBand{ .white, .white, .white };
    const expected: []const u8 = "99 gigaohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "First two colors make an invalid octal number" {
    const colors = [_]ColorBand{ .black, .grey, .black };
    const expected: []const u8 = "8 ohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Ignore extra colors" {
    const colors = [_]ColorBand{ .blue, .green, .yellow, .orange };
    const expected: []const u8 = "650 kiloohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Orange and orange and red" {
    const colors = [_]ColorBand{ .orange, .orange, .red };
    const expected: []const u8 = "3.3 kiloohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "Orange and orange and green" {
    const colors = [_]ColorBand{ .orange, .orange, .green };
    const expected: []const u8 = "3.3 megaohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "White and white and violet" {
    const colors = [_]ColorBand{ .white, .white, .violet };
    const expected: []const u8 = "990 megaohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}

test "White and white and grey" {
    const colors = [_]ColorBand{ .white, .white, .grey };
    const expected: []const u8 = "9.9 gigaohms";

    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        labelTest,
        .{ &colors, expected },
    );
}
