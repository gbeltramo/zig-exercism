const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const rev_alphabet = "zyxwvutsrqponmlkjihgfedcba";

/// Encodes `s` using the Atbash cipher. Caller owns the returned memory.
pub fn encode(allocator: mem.Allocator, s: []const u8) mem.Allocator.Error![]u8 {
    var list = try std.ArrayListUnmanaged(u8).initCapacity(allocator, 0);

    var idx: usize = 0;
    for (s) |c| {
        if (std.ascii.isAlphanumeric(c)) {
            const new_c: u8 = if (std.ascii.isDigit(c)) c else rev_alphabet[std.ascii.toLower(c) - 'a'];
            try list.append(allocator, new_c);
            idx += 1;
            if (idx % 5 == 0) try list.append(allocator, ' ');
        }
    }

    if (list.items[list.items.len - 1] == ' ') _ = list.pop();

    return list.toOwnedSlice(allocator);
}

/// Decodes `s` using the Atbash cipher. Caller owns the returned memory.
pub fn decode(allocator: mem.Allocator, s: []const u8) mem.Allocator.Error![]u8 {
    var list = try std.ArrayListUnmanaged(u8).initCapacity(allocator, 0);

    for (s) |c| {
        if (c != ' ') {
            const new_c: u8 = if (std.ascii.isDigit(c)) c else rev_alphabet[c - 'a'];
            try list.append(allocator, new_c);
        }
    }

    return list.toOwnedSlice(allocator);
}

test "encode yes" {
    const expected = "bvh";
    const s = "yes";
    const actual = try encode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode no" {
    const expected = "ml";
    const s = "no";
    const actual = try encode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode omg" {
    const expected = "lnt";
    const s = "OMG";
    const actual = try encode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode spaces" {
    const expected = "lnt";
    const s = "O M G";
    const actual = try encode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode mindblowingly" {
    const expected = "nrmwy oldrm tob";
    const s = "mindblowingly";
    const actual = try encode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode numbers" {
    const expected = "gvhgr mt123 gvhgr mt";
    const s = "Testing,1 2 3, testing.";
    const actual = try encode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode deep thought" {
    const expected = "gifgs rhurx grlm";
    const s = "Truth is fiction.";
    const actual = try encode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode all the letters" {
    const expected = "gsvjf rxpyi ldmul cqfnk hlevi gsvoz abwlt";
    const s = "The quick brown fox jumps over the lazy dog.";
    const actual = try encode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode exercism" {
    const expected = "exercism";
    const s = "vcvix rhn";
    const actual = try decode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode a sentence" {
    const expected = "anobstacleisoftenasteppingstone";
    const s = "zmlyh gzxov rhlug vmzhg vkkrm thglm v";
    const actual = try decode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode numbers" {
    const expected = "testing123testing";
    const s = "gvhgr mt123 gvhgr mt";
    const actual = try decode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode all the letters" {
    const expected = "thequickbrownfoxjumpsoverthelazydog";
    const s = "gsvjf rxpyi ldmul cqfnk hlevi gsvoz abwlt";
    const actual = try decode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode with too many spaces" {
    const expected = "exercism";
    const s = "vc vix    r hn";
    const actual = try decode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "decode with no spaces" {
    const expected = "anobstacleisoftenasteppingstone";
    const s = "zmlyhgzxovrhlugvmzhgvkkrmthglmv";
    const actual = try decode(testing.allocator, s);
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}
