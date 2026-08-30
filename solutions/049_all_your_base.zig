const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const ConversionError = error{
    InvalidInputBase,
    InvalidOutputBase,
    InvalidDigit,
};

/// Converts `digits` from `input_base` to `output_base`, returning a slice of digits.
/// Caller owns the returned memory.
pub fn convert(
    allocator: mem.Allocator,
    digits: []const u32,
    input_base: u32,
    output_base: u32,
) (mem.Allocator.Error || ConversionError)![]u32 {
    if (input_base <= 1) return ConversionError.InvalidInputBase;
    if (output_base <= 1) return ConversionError.InvalidOutputBase;

    var base10: u32 = 0;
    for (0..digits.len) |pow| {
        const idx = digits.len - 1 - pow;
        const mult = digits[idx];
        if (mult > (input_base - 1)) return ConversionError.InvalidDigit;
        base10 += mult * std.math.pow(u32, input_base, @intCast(pow));
    }

    const estimate_max_length_output_digits = if (base10 > 1) std.math.log(u32, output_base, base10) + 1 else 1;

    const new_digits = try allocator.alloc(u32, estimate_max_length_output_digits);
    defer allocator.free(new_digits);

    var need_first_non_zero_mult: bool = true;
    var out_length: usize = 1;
    for (0..estimate_max_length_output_digits) |idx| {
        const pow = estimate_max_length_output_digits - 1 - idx;
        const denom = std.math.pow(u32, output_base, @intCast(pow));
        const mult = @divFloor(base10, denom);
        if (mult != 0) {
            if (need_first_non_zero_mult) {
                out_length = pow + 1;
                need_first_non_zero_mult = false;
            }
            base10 -= mult * denom;
        }
        new_digits[idx] = mult;
    }

    const out = try allocator.alloc(u32, out_length);
    @memcpy(out, new_digits[estimate_max_length_output_digits - out_length ..]);
    return out;
}

fn testConvert(digits: []const u32, input_base: u32, output_base: u32, expected: []const u32) !void {
    const actual = try convert(testing.allocator, digits, input_base, output_base);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u32, expected, actual);
}

fn testConvertError(digits: []const u32, input_base: u32, output_base: u32, expected: ConversionError) !void {
    try testing.expectError(expected, convert(testing.allocator, digits, input_base, output_base));
}

test "single bit one to decimal" {
    try testConvert(&[_]u32{1}, 2, 10, &[_]u32{1});
}

test "binary to single decimal" {
    try testConvert(&[_]u32{ 1, 0, 1 }, 2, 10, &[_]u32{5});
}

test "single decimal to binary" {
    try testConvert(&[_]u32{5}, 10, 2, &[_]u32{ 1, 0, 1 });
}

test "binary to multiple decimal" {
    try testConvert(&[_]u32{ 1, 0, 1, 0, 1, 0 }, 2, 10, &[_]u32{ 4, 2 });
}

test "decimal to binary" {
    try testConvert(&[_]u32{ 4, 2 }, 10, 2, &[_]u32{ 1, 0, 1, 0, 1, 0 });
}

test "trinary to hexadecimal" {
    try testConvert(&[_]u32{ 1, 1, 2, 0 }, 3, 16, &[_]u32{ 2, 10 });
}

test "hexadecimal to trinary" {
    try testConvert(&[_]u32{ 2, 10 }, 16, 3, &[_]u32{ 1, 1, 2, 0 });
}

test "15-bit integer" {
    try testConvert(&[_]u32{ 3, 46, 60 }, 97, 73, &[_]u32{ 6, 10, 45 });
}

test "empty list - second call returns different memory" {
    // The `convert` doc comment says that the caller owns the returned memory.
    // `convert` must always return memory that can be freed.
    // Test that `convert` does not return a slice that references a global array.
    const expected = [_]u32{0};
    const digits = [_]u32{};
    const input_base = 10;
    const output_base = 2;
    const actual = try convert(testing.allocator, &digits, input_base, output_base);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u32, &expected, actual);
    actual[0] = 1; // Modify the output!
    const again = try convert(testing.allocator, &digits, input_base, output_base);
    defer testing.allocator.free(again);
    try testing.expectEqualSlices(u32, &expected, again);
}

test "empty list" {
    try testConvert(&[_]u32{}, 2, 10, &[_]u32{0});
}

test "single zero" {
    try testConvert(&[_]u32{0}, 10, 2, &[_]u32{0});
}

test "multiple zeros" {
    try testConvert(&[_]u32{ 0, 0, 0 }, 10, 2, &[_]u32{0});
}

test "leading zeros" {
    try testConvert(&[_]u32{ 0, 6, 0 }, 7, 10, &[_]u32{ 4, 2 });
}

test "input base is one" {
    try testConvertError(&[_]u32{0}, 1, 10, ConversionError.InvalidInputBase);
}

test "input base is zero" {
    try testConvertError(&[_]u32{}, 0, 10, ConversionError.InvalidInputBase);
}

test "invalid positive digit" {
    try testConvertError(&[_]u32{ 1, 2, 1, 0, 1, 0 }, 2, 10, ConversionError.InvalidDigit);
}

test "output base is one" {
    try testConvertError(&[_]u32{ 1, 0, 1, 0, 1, 0 }, 2, 1, ConversionError.InvalidOutputBase);
}

test "output base is zero" {
    try testConvertError(&[_]u32{7}, 10, 0, ConversionError.InvalidOutputBase);
}
