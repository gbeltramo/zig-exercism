const std = @import("std");
const testing = std.testing;

var top_three: [3]i32 = .{
    std.math.minInt(i32),
    std.math.minInt(i32),
    std.math.minInt(i32),
};

pub const HighScores = struct {
    scores: []const i32,

    pub fn init(scores: []const i32) HighScores {
        return .{ .scores = scores };
    }

    pub fn latest(self: *const HighScores) ?i32 {
        if (self.scores.len == 0) return null;
        return self.scores[self.scores.len - 1];
    }

    pub fn personalBest(self: *const HighScores) ?i32 {
        if (self.scores.len == 0) return null;
        return std.mem.max(i32, self.scores);
    }

    pub fn personalTopThree(self: *const HighScores) []const i32 {
        top_three = .{
            std.math.minInt(i32),
            std.math.minInt(i32),
            std.math.minInt(i32),
        };
        var current_min_index: usize = 0;
        var count: usize = 0;

        for (self.scores) |s| {
            if (s > top_three[current_min_index]) {
                top_three[current_min_index] = s;
                current_min_index = std.mem.findMin(i32, &top_three);
                count = @min(3, (count + 1));
            }
        }

        // Need to sort before returning
        var a = top_three[0];
        var b = top_three[1];
        var c = top_three[2];

        {
            const hi = @max(a, b);
            const lo = @min(a, b);
            a = hi;
            b = lo;
        }

        {
            const hi = @max(b, c);
            const lo = @min(b, c);
            b = hi;
            c = lo;
        }

        {
            const hi = @max(a, b);
            const lo = @min(a, b);
            a = hi;
            b = lo;
        }

        top_three[0] = a;
        top_three[1] = b;
        top_three[2] = c;

        return top_three[0..count];
    }
};

test "Latest score" {
    const scores = &[_]i32{ 100, 0, 90, 30 };
    try testing.expectEqual(30, HighScores.init(scores).latest());
}

test "Personal best" {
    const scores = &[_]i32{ 40, 100, 70 };
    try testing.expectEqual(100, HighScores.init(scores).personalBest());
}

test "Top 3 scores-Personal top three from a list of scores" {
    const scores = &[_]i32{ 10, 30, 90, 30, 100, 20, 10, 0, 30, 40, 40, 70, 70 };
    try testing.expectEqualSlices(i32, &[_]i32{ 100, 90, 70 }, HighScores.init(scores).personalTopThree());
}

test "Top 3 scores-Personal top highest to lowest" {
    const scores = &[_]i32{ 20, 10, 30 };
    try testing.expectEqualSlices(i32, &[_]i32{ 30, 20, 10 }, HighScores.init(scores).personalTopThree());
}

test "Top 3 scores-Personal top when there is a tie" {
    const scores = &[_]i32{ 40, 20, 40, 30 };
    try testing.expectEqualSlices(i32, &[_]i32{ 40, 40, 30 }, HighScores.init(scores).personalTopThree());
}

test "Top 3 scores-Personal top when there are less than 3" {
    const scores = &[_]i32{ 30, 70 };
    try testing.expectEqualSlices(i32, &[_]i32{ 70, 30 }, HighScores.init(scores).personalTopThree());
}

test "Top 3 scores-Personal top when there is only one" {
    const scores = &[_]i32{40};
    try testing.expectEqualSlices(i32, &[_]i32{40}, HighScores.init(scores).personalTopThree());
}

test "Latest score can be outside top three" {
    const scores = &[_]i32{ 80, 70, 90, 10, 20, 30 };
    try testing.expectEqual(30, HighScores.init(scores).latest());
}
