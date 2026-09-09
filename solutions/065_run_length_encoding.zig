const std = @import("std");
const testing = std.testing;

pub fn encode(buffer: []u8, string: []const u8) []u8 {
    for (0..buffer.len) |i| buffer[i] = 0;
    if (string.len == 0) {
        return buffer[0..0];
    } else if (string.len == 1) {
        return buffer[0..1];
    } else {
        var current_char = string[0];
        var count: usize = 1;
        var idx_buffer: usize = 0;
        for (1..string.len + 1) |idx| {
            const new_char = if (idx < string.len) string[idx] else 0;

            if (new_char == current_char) {
                count += 1;
            } else {
                if (count == 1) {
                    buffer[idx_buffer] = current_char;
                    idx_buffer += 1;
                    current_char = new_char;
                    count = 1;
                } else {
                    var power_ten: usize = 0;
                    while (std.math.pow(usize, 10, power_ten) < count) power_ten += 1;

                    var p: usize = power_ten - 1;
                    while (true) {
                        const next_digit = @divFloor(count, std.math.pow(usize, 10, p));
                        buffer[idx_buffer] = '0' + @as(u8, @intCast(next_digit));
                        idx_buffer += 1;
                        count -= next_digit * std.math.pow(usize, 10, p);

                        if (p == 0) break;
                        p -= 1;
                    }
                    buffer[idx_buffer] = current_char;
                    idx_buffer += 1;
                }
                current_char = new_char;
                count = 1;
            }
        }
        return buffer[0..idx_buffer];
    }
}

pub fn decode(buffer: []u8, string: []const u8) []u8 {
    for (0..buffer.len) |i| buffer[i] = 0;
    if (string.len == 0) {
        return buffer[0..0];
    } else if (string.len == 1) {
        return buffer[0..1];
    } else {
        var count_mult: usize = 1;
        var count: usize = 0;
        var idx_buffer: usize = 0;

        if (std.ascii.isDigit(string[0])) {
            count = (count * count_mult + @as(usize, @intCast(string[0] - '0')));
            count_mult *= 10;
        } else {
            buffer[idx_buffer] = string[0];
            idx_buffer += 1;
        }

        for (1..string.len) |idx| {
            const new_char = string[idx];
            if (std.ascii.isDigit(new_char)) {
                count = (count * count_mult + @as(usize, @intCast(new_char - '0')));
                count_mult *= 10;
            } else {
                if (count == 0) {
                    buffer[idx_buffer] = new_char;
                    idx_buffer += 1;
                } else {
                    for (0..count) |_| {
                        buffer[idx_buffer] = new_char;
                        idx_buffer += 1;
                    }
                }

                count = 0;
                count_mult = 1;
            }
        }
        return buffer[0..idx_buffer];
    }
}

fn testEncode(string: []const u8, expected: []const u8) !void {
    const buffer_size = 80;
    var buffer: [buffer_size]u8 = undefined;
    const actual = encode(&buffer, string);
    try testing.expectEqualStrings(expected, actual);
}

fn testDecode(string: []const u8, expected: []const u8) !void {
    const buffer_size = 80;
    var buffer: [buffer_size]u8 = undefined;
    const actual = decode(&buffer, string);
    try testing.expectEqualStrings(expected, actual);
}

fn testConsistency(string: []const u8, expected: []const u8) !void {
    const buffer_size = 80;
    var buffer1: [buffer_size]u8 = undefined;
    var buffer2: [buffer_size]u8 = undefined;
    const encoded = encode(&buffer1, string);
    const actual = decode(&buffer2, encoded);
    try testing.expectEqualStrings(expected, actual);
}

test "run-length encode a string-empty string" {
    try testEncode("", "");
}

test "run-length encode a string-single characters only are encoded without count" {
    try testEncode("XYZ", "XYZ");
}

test "run-length encode a string-string with no single characters" {
    try testEncode("AABBBCCCC", "2A3B4C");
}

test "run-length encode a string-single characters mixed with repeated characters" {
    try testEncode("WWWWWWWWWWWWBWWWWWWWWWWWWBBBWWWWWWWWWWWWWWWWWWWWWWWWB", "12WB12W3B24WB");
}

test "run-length encode a string-multiple whitespace mixed in string" {
    try testEncode("  hsqq qww  ", "2 hs2q q2w2 ");
}

test "run-length encode a string-lowercase characters" {
    try testEncode("aabbbcccc", "2a3b4c");
}

test "run-length decode a string-empty string" {
    try testDecode("", "");
}

test "run-length decode a string-single characters only" {
    try testDecode("XYZ", "XYZ");
}

test "run-length decode a string-string with no single characters" {
    try testDecode("2A3B4C", "AABBBCCCC");
}

test "run-length decode a string-single characters with repeated characters" {
    try testDecode("12WB12W3B24WB", "WWWWWWWWWWWWBWWWWWWWWWWWWBBBWWWWWWWWWWWWWWWWWWWWWWWWB");
}

test "run-length decode a string-multiple whitespace mixed in string" {
    try testDecode("2 hs2q q2w2 ", "  hsqq qww  ");
}

test "run-length decode a string-lowercase string" {
    try testDecode("2a3b4c", "aabbbcccc");
}

test "encode and then decode-encode followed by decode gives original string" {
    try testConsistency("zzz ZZ  zZ", "zzz ZZ  zZ");
}
