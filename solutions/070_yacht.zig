const std = @import("std");
const testing = std.testing;

pub const Category = enum(u8) {
    ones = 0,
    twos = 1,
    threes = 2,
    fours = 3,
    fives = 4,
    sixes = 5,
    full_house = 6,
    four_of_a_kind = 7,
    little_straight = 8,
    big_straight = 9,
    choice = 10,
    yacht = 11,
};

pub fn score(dice: [5]u3, category: Category) u32 {
    var counts = [6]u8{ 0, 0, 0, 0, 0, 0 };
    var total: u8 = 0;
    for (dice) |d| {
        counts[d - 1] += 1;
        total += d;
    }

    const cat: u8 = @intFromEnum(category);

    return switch (category) {
        .ones, .twos, .threes, .fours, .fives, .sixes => (cat + 1) * counts[cat],
        .full_house => blk: {
            var has_three_same = false;
            var has_two_same = false;

            for (counts) |c| {
                if (c == 3) has_three_same = true;
                if (c == 2) has_two_same = true;
            }

            break :blk if (has_three_same and has_two_same) total else 0;
        },
        .four_of_a_kind => blk: {
            var has_four_same = false;
            var value_4: u8 = 0;

            for (counts, 0..) |c, idx| {
                if (c >= 4) {
                    has_four_same = true;
                    value_4 = @as(u8, @intCast(idx + 1));
                }
            }

            break :blk if (has_four_same) 4 * value_4 else 0;
        },
        .little_straight => blk: {
            const counts_little_straight = [6]u8{ 1, 1, 1, 1, 1, 0 };
            const cond = std.mem.eql(u8, &counts, &counts_little_straight);
            break :blk if (cond) 30 else 0;
        },
        .big_straight => blk: {
            const counts_big_straight = [6]u8{ 0, 1, 1, 1, 1, 1 };
            const cond = std.mem.eql(u8, &counts, &counts_big_straight);
            break :blk if (cond) 30 else 0;
        },
        .choice => total,
        .yacht => blk: {
            var has_five_same = false;

            for (counts) |c| {
                if (c == 5) has_five_same = true;
            }

            break :blk if (has_five_same) 50 else 0;
        },
    };
}

fn testScore(dice: [5]u3, category: Category, expected: u32) !void {
    try testing.expectEqual(expected, score(dice, category));
}

test "no ones" {
    try testScore([_]u3{ 4, 3, 6, 5, 5 }, .ones, 0);
}

test "ones" {
    try testScore([_]u3{ 1, 1, 1, 3, 5 }, .ones, 3);
}

test "ones, out of order" {
    try testScore([_]u3{ 3, 1, 1, 5, 1 }, .ones, 3);
}

test "twos" {
    try testScore([_]u3{ 2, 3, 4, 5, 6 }, .twos, 2);
}

test "yacht counted as threes" {
    try testScore([_]u3{ 3, 3, 3, 3, 3 }, .threes, 15);
}

test "fours" {
    try testScore([_]u3{ 1, 4, 1, 4, 1 }, .fours, 8);
}

test "fives" {
    try testScore([_]u3{ 1, 5, 3, 5, 3 }, .fives, 10);
}

test "yacht of 3s counted as fives" {
    try testScore([_]u3{ 3, 3, 3, 3, 3 }, .fives, 0);
}

test "sixes" {
    try testScore([_]u3{ 2, 3, 4, 5, 6 }, .sixes, 6);
}

test "four of a kind is not a full house" {
    try testScore([_]u3{ 1, 4, 4, 4, 4 }, .full_house, 0);
}

test "full house three small, two big" {
    try testScore([_]u3{ 5, 3, 3, 5, 3 }, .full_house, 19);
}

test "full house three small, two big, alternative order" {
    try testScore([_]u3{ 4, 4, 2, 2, 2 }, .full_house, 14);
}

test "full house two small, three big" {
    try testScore([_]u3{ 2, 2, 4, 4, 4 }, .full_house, 16);
}

test "full house two small, three big, alternative order" {
    try testScore([_]u3{ 3, 5, 5, 3, 5 }, .full_house, 21);
}

test "two pair is not a full house" {
    try testScore([_]u3{ 2, 2, 4, 4, 5 }, .full_house, 0);
}

test "yacht is not a full house" {
    try testScore([_]u3{ 2, 2, 2, 2, 2 }, .full_house, 0);
}

test "four of a kind" {
    try testScore([_]u3{ 6, 6, 4, 6, 6 }, .four_of_a_kind, 24);
}

test "four of a kind alternative order" {
    try testScore([_]u3{ 4, 4, 6, 4, 4 }, .four_of_a_kind, 16);
}

test "full house is not four of a kind" {
    try testScore([_]u3{ 3, 3, 3, 5, 5 }, .four_of_a_kind, 0);
}

test "yacht can be scored as four of a kind" {
    try testScore([_]u3{ 3, 3, 3, 3, 3 }, .four_of_a_kind, 12);
}

test "big straight as little straight" {
    try testScore([_]u3{ 6, 5, 4, 3, 2 }, .little_straight, 0);
}

test "four in order but not a little straight" {
    try testScore([_]u3{ 1, 1, 2, 3, 4 }, .little_straight, 0);
}

test "little straight" {
    try testScore([_]u3{ 3, 5, 4, 1, 2 }, .little_straight, 30);
}

test "minimum is 1, maximum is 5, but not a little straight" {
    try testScore([_]u3{ 1, 1, 3, 4, 5 }, .little_straight, 0);
}

test "no pairs but not a little straight" {
    try testScore([_]u3{ 1, 2, 3, 4, 6 }, .little_straight, 0);
}

test "big straight" {
    try testScore([_]u3{ 4, 6, 2, 5, 3 }, .big_straight, 30);
}

test "little straight as big straight" {
    try testScore([_]u3{ 1, 2, 3, 4, 5 }, .big_straight, 0);
}

test "no pairs but not a big straight" {
    try testScore([_]u3{ 6, 5, 4, 3, 1 }, .big_straight, 0);
}

test "choice" {
    try testScore([_]u3{ 3, 3, 5, 6, 6 }, .choice, 23);
}

test "yacht as choice" {
    try testScore([_]u3{ 2, 2, 2, 2, 2 }, .choice, 10);
}

test "not yacht" {
    try testScore([_]u3{ 1, 3, 3, 2, 5 }, .yacht, 0);
}

test "yacht" {
    try testScore([_]u3{ 5, 5, 5, 5, 5 }, .yacht, 50);
}
