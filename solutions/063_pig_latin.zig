const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn translate(allocator: mem.Allocator, phrase: []const u8) mem.Allocator.Error![]u8 {
    var list = try std.ArrayList(u8).initCapacity(allocator, 8);
    var output = try std.ArrayList(u8).initCapacity(allocator, 8);
    defer list.deinit(allocator);
    errdefer output.deinit(allocator);

    var it = std.mem.splitSequence(u8, phrase, " ");
    while (it.next()) |word| {
        if (output.items.len > 0) try output.append(allocator, ' ');

        if (ruleOne(word)) { // starts with (vowel or "xr" or "yt")
            for (word) |c| {
                try list.append(allocator, c);
            }
            try list.append(allocator, 'a');
            try list.append(allocator, 'y');
        } else { // starts with consonant, so apply rules (2, 3, 4)
            const length_consonants_to_be_moved = consonantClusterLength(word);
            for (word[length_consonants_to_be_moved..]) |c| try list.append(allocator, c);
            for (word[0..length_consonants_to_be_moved]) |c| try list.append(allocator, c);
            try list.append(allocator, 'a');
            try list.append(allocator, 'y');
        }

        for (list.items) |new_c| {
            try output.append(allocator, new_c);
        }
        list.clearRetainingCapacity();
    }

    return output.toOwnedSlice(allocator);
}

fn ruleOne(word: []const u8) bool {
    return startWithVowel(word) or startWithXR(word) or startWithYT(word);
}

fn isVowel(c: u8) bool {
    return (c == 'a') or (c == 'e') or (c == 'i') or (c == 'o') or (c == 'u');
}

fn startWithVowel(word: []const u8) bool {
    return if (word.len == 0) false else isVowel(word[0]);
}

fn startWithXR(word: []const u8) bool {
    if (word.len <= 1) {
        return false;
    } else {
        const c0 = word[0];
        const c1 = word[1];
        return (c0 == 'x') and (c1 == 'r');
    }
}

fn startWithYT(word: []const u8) bool {
    if (word.len <= 1) {
        return false;
    } else {
        const c0 = word[0];
        const c1 = word[1];
        return (c0 == 'y') and (c1 == 't');
    }
}

fn consonantClusterLength(word: []const u8) usize {
    var length: usize = 0;
    while (length < word.len) : (length += 1) {
        const c = word[length];

        // We break if we find (c+ vowel, c* qu, c+ y)
        if (isVowel(c) or (c == 'y' and length > 0)) {
            break;
        } else if (c == 'q' and (length + 1) < (word.len) and (word[length + 1] == 'u')) {
            length += 2;
            break;
        }
    }
    return length;
}

test "ay is added to words that start with vowels-word beginning with a" {
    const expected: []const u8 = "appleay";
    const actual = try translate(testing.allocator, "apple");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "ay is added to words that start with vowels-word beginning with e" {
    const expected: []const u8 = "earay";
    const actual = try translate(testing.allocator, "ear");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "ay is added to words that start with vowels-word beginning with i" {
    const expected: []const u8 = "iglooay";
    const actual = try translate(testing.allocator, "igloo");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "ay is added to words that start with vowels-word beginning with o" {
    const expected: []const u8 = "objectay";
    const actual = try translate(testing.allocator, "object");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "ay is added to words that start with vowels-word beginning with u" {
    const expected: []const u8 = "underay";
    const actual = try translate(testing.allocator, "under");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "ay is added to words that start with vowels-word beginning with a vowel and followed by a qu" {
    const expected: []const u8 = "equalay";
    const actual = try translate(testing.allocator, "equal");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "first letter and ay are moved to the end of words that start with consonants-word beginning with p" {
    const expected: []const u8 = "igpay";
    const actual = try translate(testing.allocator, "pig");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "first letter and ay are moved to the end of words that start with consonants-word beginning with k" {
    const expected: []const u8 = "oalakay";
    const actual = try translate(testing.allocator, "koala");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "first letter and ay are moved to the end of words that start with consonants-word beginning with x" {
    const expected: []const u8 = "enonxay";
    const actual = try translate(testing.allocator, "xenon");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "first letter and ay are moved to the end of words that start with consonants-word beginning with q without a following u" {
    const expected: []const u8 = "atqay";
    const actual = try translate(testing.allocator, "qat");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "first letter and ay are moved to the end of words that start with consonants-word beginning with consonant and vowel containing qu" {
    const expected: []const u8 = "iquidlay";
    const actual = try translate(testing.allocator, "liquid");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "some letter clusters are treated like a single consonant-word beginning with ch" {
    const expected: []const u8 = "airchay";
    const actual = try translate(testing.allocator, "chair");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "some letter clusters are treated like a single consonant-word beginning with qu" {
    const expected: []const u8 = "eenquay";
    const actual = try translate(testing.allocator, "queen");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "some letter clusters are treated like a single consonant-word beginning with qu and a preceding consonant" {
    const expected: []const u8 = "aresquay";
    const actual = try translate(testing.allocator, "square");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "some letter clusters are treated like a single consonant-word beginning with th" {
    const expected: []const u8 = "erapythay";
    const actual = try translate(testing.allocator, "therapy");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "some letter clusters are treated like a single consonant-word beginning with thr" {
    const expected: []const u8 = "ushthray";
    const actual = try translate(testing.allocator, "thrush");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "some letter clusters are treated like a single consonant-word beginning with sch" {
    const expected: []const u8 = "oolschay";
    const actual = try translate(testing.allocator, "school");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "some letter clusters are treated like a single vowel-word beginning with yt" {
    const expected: []const u8 = "yttriaay";
    const actual = try translate(testing.allocator, "yttria");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "some letter clusters are treated like a single vowel-word beginning with xr" {
    const expected: []const u8 = "xrayay";
    const actual = try translate(testing.allocator, "xray");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "position of y in a word determines if it is a consonant or a vowel-y is treated like a consonant at the beginning of a word" {
    const expected: []const u8 = "ellowyay";
    const actual = try translate(testing.allocator, "yellow");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "position of y in a word determines if it is a consonant or a vowel-y is treated like a vowel at the end of a consonant cluster" {
    const expected: []const u8 = "ythmrhay";
    const actual = try translate(testing.allocator, "rhythm");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "position of y in a word determines if it is a consonant or a vowel-y as second letter in two letter word" {
    const expected: []const u8 = "ymay";
    const actual = try translate(testing.allocator, "my");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "phrases are translated-a whole phrase" {
    const expected: []const u8 = "ickquay astfay unray";
    const actual = try translate(testing.allocator, "quick fast run");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}
