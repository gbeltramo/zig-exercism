const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const AffineCipherError = error{
    NotCoprime,
};

const m: u16 = 26;

/// Are a and m=26 coprime?
fn isNotComprimeWithVocabSize(a: u8) bool {
    // NOTE => 26 = 2 * 13
    return (a % 2 == 0) or (a % 13 == 0);
}

fn modInverse(a: u8) !u16 {
    const a_u16 = a % m;
    for (1..m + 1) |x| {
        if (((a_u16 * x) % m) == 1) return @intCast(x);
    }

    return AffineCipherError.NotCoprime;
}

/// Encodes `phrase` using the affine cipher. Caller owns the returned memory.
pub fn encode(allocator: mem.Allocator, phrase: []const u8, a: u8, b: u8) (mem.Allocator.Error || AffineCipherError)![]u8 {
    if (isNotComprimeWithVocabSize(a)) return AffineCipherError.NotCoprime;

    var encoded_text = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer encoded_text.deinit(allocator);

    const a_u16 = @as(u16, @intCast(a));
    const b_u16 = @as(u16, @intCast(b));
    for (phrase) |char| {
        if (std.ascii.isAlphanumeric(char)) {
            if (std.ascii.isDigit(char)) {
                try encoded_text.append(allocator, char);
            } else {
                const lower = std.ascii.toLower(char);
                const idx_char_u16 = @as(u16, @intCast(lower - 'a'));
                const enc_char = @as(u8, @intCast((a_u16 * idx_char_u16 + b_u16) % m)) + 'a';
                try encoded_text.append(allocator, enc_char);
            }
        }
    }

    var out = try std.ArrayList(u8).initCapacity(allocator, 0);
    errdefer out.deinit(allocator);

    for (encoded_text.items, 0..) |enc_char, idx| {
        if ((idx != 0) and (idx != encoded_text.items.len) and ((idx % 5) == 0)) try out.append(allocator, ' ');
        try out.append(allocator, enc_char);
    }

    return out.toOwnedSlice(allocator);
}

/// Decodes `phrase` using the affine cipher. Caller owns the returned memory.
pub fn decode(allocator: mem.Allocator, phrase: []const u8, a: u8, b: u8) (mem.Allocator.Error || AffineCipherError)![]u8 {
    if (isNotComprimeWithVocabSize(a)) return AffineCipherError.NotCoprime;

    var decoded_text = try std.ArrayList(u8).initCapacity(allocator, 0);
    errdefer decoded_text.deinit(allocator);

    const a_inv = try modInverse(a);

    for (phrase) |char| {
        if (std.ascii.isDigit(char)) {
            try decoded_text.append(allocator, char);
        } else if (std.ascii.isAlphabetic(char)) {
            const idx_char = @as(i32, char - 'a');
            const idx = @mod(idx_char - @as(i32, b), @as(i32, m));
            const dec_char = @as(u8, @intCast((a_inv * @as(u16, @intCast(idx))) % m)) + 'a';
            try decoded_text.append(allocator, dec_char);
        }
    }

    return decoded_text.toOwnedSlice(allocator);
}

fn testEncodeError(phrase: []const u8, a: u8, b: u8) !void {
    const actual = encode(testing.allocator, phrase, a, b);
    defer if (actual) |slice| testing.allocator.free(slice) else |_| {};
    try testing.expectError(AffineCipherError.NotCoprime, actual);
}

fn testDecodeError(phrase: []const u8, a: u8, b: u8) !void {
    const actual = decode(testing.allocator, phrase, a, b);
    defer if (actual) |slice| testing.allocator.free(slice) else |_| {};
    try testing.expectError(AffineCipherError.NotCoprime, actual);
}

test "encode yes" {
    const expected: []const u8 = "xbt";
    const actual = try encode(testing.allocator, "yes", 5, 7);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode no" {
    const expected: []const u8 = "fu";
    const actual = try encode(testing.allocator, "no", 15, 18);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode OMG" {
    const expected: []const u8 = "lvz";
    const actual = try encode(testing.allocator, "OMG", 21, 3);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode O M G" {
    const expected: []const u8 = "hjp";
    const actual = try encode(testing.allocator, "O M G", 25, 47);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode mindblowingly" {
    const expected: []const u8 = "rzcwa gnxzc dgt";
    const actual = try encode(testing.allocator, "mindblowingly", 11, 15);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode numbers" {
    const expected: []const u8 = "jqgjc rw123 jqgjc rw";
    const actual = try encode(testing.allocator, "Testing,1 2 3, testing.", 3, 4);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode deep thought" {
    const expected: []const u8 = "iynia fdqfb ifje";
    const actual = try encode(testing.allocator, "Truth is fiction.", 5, 17);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode all the letters" {
    const expected: []const u8 = "swxtj npvyk lruol iejdc blaxk swxmh qzglf";
    const actual = try encode(testing.allocator, "The quick brown fox jumps over the lazy dog.", 17, 33);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode with a not coprime to m" {
    try testEncodeError("This is a test.", 6, 17);
}

test "decode exercism" {
    const expected: []const u8 = "exercism";
    const actual = try decode(testing.allocator, "tytgn fjr", 3, 7);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode a sentence" {
    const expected: []const u8 = "anobstacleisoftenasteppingstone";
    const actual = try decode(testing.allocator, "qdwju nqcro muwhn odqun oppmd aunwd o", 19, 16);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode numbers" {
    const expected: []const u8 = "testing123testing";
    const actual = try decode(testing.allocator, "odpoz ub123 odpoz ub", 25, 7);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode all the letters" {
    const expected: []const u8 = "thequickbrownfoxjumpsoverthelazydog";
    const actual = try decode(testing.allocator, "swxtj npvyk lruol iejdc blaxk swxmh qzglf", 17, 33);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode with no spaces in input" {
    const expected: []const u8 = "thequickbrownfoxjumpsoverthelazydog";
    const actual = try decode(testing.allocator, "swxtjnpvyklruoliejdcblaxkswxmhqzglf", 17, 33);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode with too many spaces" {
    const expected: []const u8 = "jollygreengiant";
    const actual = try decode(testing.allocator, "vszzm    cly   yd cg    qdp", 15, 16);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode with a not coprime to m" {
    try testDecodeError("Test", 13, 5);
}

test "encode boundary characters" {
    const expected: []const u8 = "09maz nmazn";
    const actual = try encode(testing.allocator, "/09:@AMNZ[`amnz{", 25, 12);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}
