const std = @import("std");
const testing = std.testing;

var prng = std.Random.Xoshiro256.init(1);
const rand = prng.random();

pub fn modifier(score: i8) i8 {
    return @divFloor(score - 10, 2);
}

pub fn ability() i8 {
    var values: [4]i8 = .{ 0, 0, 0, 0 };
    var min_value: i8 = 32; // greater than 6 is fine because we simulate dice roll

    for (values, 0..) |_, idx| {
        const new_value = rand.intRangeAtMost(i8, 1, 6);
        values[idx] = new_value;
        if (new_value < min_value) {
            min_value = new_value;
        }
    }

    return values[0] + values[1] + values[2] + values[3] - min_value;
}

pub const Character = struct {
    strength: i8,
    dexterity: i8,
    constitution: i8,
    intelligence: i8,
    wisdom: i8,
    charisma: i8,
    hitpoints: i8,

    pub fn init() Character {
        const _constitution = ability();
        const _hitpoints = 10 + modifier(_constitution);
        return Character{
            .strength = ability(),
            .dexterity = ability(),
            .constitution = _constitution,
            .intelligence = ability(),
            .wisdom = ability(),
            .charisma = ability(),
            .hitpoints = _hitpoints,
        };
    }
};

fn isValidAbilityScore(n: isize) bool {
    return n >= 3 and n <= 18;
}

fn isValid(c: Character) bool {
    return isValidAbilityScore(c.strength) and
        isValidAbilityScore(c.dexterity) and
        isValidAbilityScore(c.constitution) and
        isValidAbilityScore(c.intelligence) and
        isValidAbilityScore(c.wisdom) and
        isValidAbilityScore(c.charisma) and
        (c.hitpoints == 10 + modifier(c.constitution));
}

test "ability modifier for score 3 is -4" {
    const expected: i8 = -4;
    const actual = modifier(3);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 4 is -3" {
    const expected: i8 = -3;
    const actual = modifier(4);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 5 is -3" {
    const expected: i8 = -3;
    const actual = modifier(5);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 6 is -2" {
    const expected: i8 = -2;
    const actual = modifier(6);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 7 is -2" {
    const expected: i8 = -2;
    const actual = modifier(7);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 8 is -1" {
    const expected: i8 = -1;
    const actual = modifier(8);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 9 is -1" {
    const expected: i8 = -1;
    const actual = modifier(9);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 10 is 0" {
    const expected: i8 = 0;
    const actual = modifier(10);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 11 is 0" {
    const expected: i8 = 0;
    const actual = modifier(11);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 12 is +1" {
    const expected: i8 = 1;
    const actual = modifier(12);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 13 is +1" {
    const expected: i8 = 1;
    const actual = modifier(13);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 14 is +2" {
    const expected: i8 = 2;
    const actual = modifier(14);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 15 is +2" {
    const expected: i8 = 2;
    const actual = modifier(15);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 16 is +3" {
    const expected: i8 = 3;
    const actual = modifier(16);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 17 is +3" {
    const expected: i8 = 3;
    const actual = modifier(17);
    try testing.expectEqual(expected, actual);
}

test "ability modifier for score 18 is +4" {
    const expected: i8 = 4;
    const actual = modifier(18);
    try testing.expectEqual(expected, actual);
}

test "random ability is within range" {
    for (0..20) |_| {
        const actual = ability();
        try testing.expect(isValidAbilityScore(actual));
    }
}

test "random character is valid" {
    for (0..20) |_| {
        const character = Character.init();
        try testing.expect(isValid(character));
    }
}
