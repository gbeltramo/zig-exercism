const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn toRoman(allocator: mem.Allocator, arabic_numeral: i16) mem.Allocator.Error![]u8 {
    const values = [_]i16{ 1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1 };
    const symbols = [_][]const u8{ "M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I" };
    var output = try std.ArrayList(u8).initCapacity(allocator, 16);

    var current_value = arabic_numeral;
    var idx_value: usize = 0;
    while (current_value > 0 and idx_value < values.len) {
        while (current_value >= values[idx_value]) {
            try output.appendSlice(allocator, symbols[idx_value]);
            current_value -= values[idx_value];
        }
        idx_value += 1;
    }

    return output.toOwnedSlice(allocator);
}

test "1 is I" {
    const expected = "I";
    const actual = try toRoman(testing.allocator, 1);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "2 is II" {
    const expected = "II";
    const actual = try toRoman(testing.allocator, 2);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "3 is III" {
    const expected = "III";
    const actual = try toRoman(testing.allocator, 3);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "4 is IV" {
    const expected = "IV";
    const actual = try toRoman(testing.allocator, 4);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "5 is V" {
    const expected = "V";
    const actual = try toRoman(testing.allocator, 5);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "6 is VI" {
    const expected = "VI";
    const actual = try toRoman(testing.allocator, 6);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "9 is IX" {
    const expected = "IX";
    const actual = try toRoman(testing.allocator, 9);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "16 is XVI" {
    const expected = "XVI";
    const actual = try toRoman(testing.allocator, 16);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "27 is XXVII" {
    const expected = "XXVII";
    const actual = try toRoman(testing.allocator, 27);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "48 is XLVIII" {
    const expected = "XLVIII";
    const actual = try toRoman(testing.allocator, 48);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "49 is XLIX" {
    const expected = "XLIX";
    const actual = try toRoman(testing.allocator, 49);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "59 is LIX" {
    const expected = "LIX";
    const actual = try toRoman(testing.allocator, 59);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "66 is LXVI" {
    const expected = "LXVI";
    const actual = try toRoman(testing.allocator, 66);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "93 is XCIII" {
    const expected = "XCIII";
    const actual = try toRoman(testing.allocator, 93);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "141 is CXLI" {
    const expected = "CXLI";
    const actual = try toRoman(testing.allocator, 141);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "163 is CLXIII" {
    const expected = "CLXIII";
    const actual = try toRoman(testing.allocator, 163);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "166 is CLXVI" {
    const expected = "CLXVI";
    const actual = try toRoman(testing.allocator, 166);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "402 is CDII" {
    const expected = "CDII";
    const actual = try toRoman(testing.allocator, 402);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "575 is DLXXV" {
    const expected = "DLXXV";
    const actual = try toRoman(testing.allocator, 575);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "666 is DCLXVI" {
    const expected = "DCLXVI";
    const actual = try toRoman(testing.allocator, 666);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "911 is CMXI" {
    const expected = "CMXI";
    const actual = try toRoman(testing.allocator, 911);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "1024 is MXXIV" {
    const expected = "MXXIV";
    const actual = try toRoman(testing.allocator, 1024);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "1666 is MDCLXVI" {
    const expected = "MDCLXVI";
    const actual = try toRoman(testing.allocator, 1666);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "3000 is MMM" {
    const expected = "MMM";
    const actual = try toRoman(testing.allocator, 3000);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "3001 is MMMI" {
    const expected = "MMMI";
    const actual = try toRoman(testing.allocator, 3001);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "3888 is MMMDCCCLXXXVIII" {
    const expected = "MMMDCCCLXXXVIII";
    const actual = try toRoman(testing.allocator, 3888);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "3999 is MMMCMXCIX" {
    const expected = "MMMCMXCIX";
    const actual = try toRoman(testing.allocator, 3999);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}
