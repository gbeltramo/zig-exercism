const std = @import("std");
const testing = std.testing;

pub fn isPangram(phrase: []const u8) bool {
    var seen: u26 = 0;
    const target: u26 = 0b11_1111_1111_1111_1111_1111_1111;

    const check_frequency: usize = 100;
    for (phrase, 0..) |c, idx| {
        if (!std.ascii.isAlphabetic(c)) {
            continue;
        }
        const lower_c = std.ascii.toLower(c);
        const mask: u26 = @as(u26, 1) << @intCast(lower_c - 'a');
        seen |= mask;

        if ((idx % check_frequency == 0) and (seen == target)) {
            return true;
        }
    }

    return seen == target;
}

test "empty sentence" {
    try testing.expect(!isPangram(""));
}

test "perfect lower case" {
    try testing.expect(isPangram("abcdefghijklmnopqrstuvwxyz"));
}

test "only lower case" {
    try testing.expect(isPangram("the quick brown fox jumps over the lazy dog"));
}

test "missing the letter 'x'" {
    try testing.expect(!isPangram("a quick movement of the enemy will jeopardize five gunboats"));
}

test "missing the letter 'h'" {
    try testing.expect(!isPangram("five boxing wizards jump quickly at it"));
}

test "with underscores" {
    try testing.expect(isPangram("the_quick_brown_fox_jumps_over_the_lazy_dog"));
}

test "with numbers" {
    try testing.expect(isPangram("the 1 quick brown fox jumps over the 2 lazy dogs"));
}

test "missing letters replaced by numbers" {
    try testing.expect(!isPangram("7h3 qu1ck brown fox jumps ov3r 7h3 lazy dog"));
}

test "mixed case and punctuation" {
    try testing.expect(isPangram("\"Five quacking Zephyrs jolt my wax bed.\""));
}

test "a-m and A-M are 26 different characters but not a pangram" {
    try testing.expect(!isPangram("abcdefghijklm ABCDEFGHIJKLM"));
}

test "non-alphanumeric printable ASCII" {
    try testing.expect(!isPangram(" !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"));
}
