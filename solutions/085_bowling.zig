const std = @import("std");
const testing = std.testing;

pub const Error = error{ GameOver, PinCountExceeded, GameIncomplete };

const Frame = struct {
    throw_one: ?u8 = null,
    throw_two: ?u8 = null,
    throw_three: ?u8 = null,
    spare: bool = false,
    strike: bool = false,

    pub fn isDone(self: Frame) bool {
        return (self.strike) or (self.throw_one != null and self.throw_two != null);
    }

    pub fn isLastDone(self: Frame) bool {
        const cond_one = (self.throw_one != null and self.throw_two != null) and (self.throw_one.? != 10) and (self.throw_two.? != 10) and ((self.throw_one.? + self.throw_two.?) != 10);
        const cond_two = self.throw_one != null and self.throw_two != null and self.throw_three != null;
        return cond_one or cond_two;
    }
};

pub const Game = struct {
    frames: [10]Frame,
    idx_frame: usize,

    /// Initializes a Game.
    pub fn init() Game {
        var frames: [10]Frame = undefined;
        for (0..10) |i| frames[i] = Frame{};
        return .{ .frames = frames, .idx_frame = 0 };
    }

    /// Records a roll that knocks down `pins` pins.
    pub fn roll(self: *Game, pins: u4) Error!void {
        if (pins > 10) return Error.PinCountExceeded;

        const frame = self.frames[self.idx_frame];

        if (self.idx_frame < 9) {
            if (frame.throw_one == null) {
                self.frames[self.idx_frame].throw_one = @intCast(pins);
                if (pins == 10) { // strike
                    self.frames[self.idx_frame].strike = true;
                    self.idx_frame += 1;
                }
            } else if (frame.throw_two == null) {
                if (frame.throw_one.? + pins > 10) {
                    return Error.PinCountExceeded;
                }
                self.frames[self.idx_frame].throw_two = @intCast(pins);
                self.frames[self.idx_frame].spare = (frame.throw_one.? + pins) == 10;
                self.idx_frame += 1;
            } else {
                return Error.GameOver;
            }
        } else if (self.idx_frame == 9) {
            if (frame.throw_one == null) {
                self.frames[self.idx_frame].throw_one = @intCast(pins);
            } else if (frame.throw_two == null) {
                if (frame.throw_one.? != 10 and frame.throw_one.? + pins > 10) {
                    return Error.PinCountExceeded;
                }
                self.frames[self.idx_frame].throw_two = @intCast(pins);
            } else if (frame.throw_three == null) {
                const earned_bonus = (frame.throw_one.? == 10) or (frame.throw_one.? + frame.throw_two.? == 10);
                if (!earned_bonus) {
                    return Error.GameOver;
                }
                // NOTE Strike then non-strike: throw_two/throw_three share a rack
                if (frame.throw_one.? == 10 and frame.throw_two.? != 10 and frame.throw_two.? + pins > 10) {
                    return Error.PinCountExceeded;
                }
                self.frames[self.idx_frame].throw_three = @intCast(pins);
            } else {
                return Error.GameOver;
            }
        } else {
            return Error.GameOver;
        }
    }

    /// Returns the score of a complete game.
    pub fn score(self: Game) Error!u32 {
        for (0..9) |idx| {
            if (!self.frames[idx].isDone()) {
                return Error.GameIncomplete;
            }
        }

        if (!self.frames[9].isLastDone()) return Error.GameIncomplete;

        var total: u32 = 0;
        for (0..10) |idx| {
            const frame = self.frames[idx];
            if (idx < 9) {
                total += frame.throw_one.?;
                if (frame.throw_two != null) {
                    total += frame.throw_two.?;
                }
                if (frame.strike) {
                    const next_frame = self.frames[idx + 1];
                    var second_throw: u32 = 0;
                    if (next_frame.throw_two == null) {
                        second_throw = self.frames[idx + 2].throw_one.?;
                    } else {
                        second_throw = next_frame.throw_two.?;
                    }
                    total += next_frame.throw_one.? + second_throw;
                } else if (frame.spare) {
                    const next_frame = self.frames[idx + 1];
                    total += next_frame.throw_one.?;
                }
            } else {
                total += frame.throw_one.?;
                if (frame.throw_two != null) {
                    total += frame.throw_two.?;
                }
                if (frame.throw_three != null) {
                    total += frame.throw_three.?;
                }
            }
        }
        return total;
    }
};

test "should be able to score a game with all zeros" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(0, game.score());
}

test "should be able to score a game with no strikes or spares" {
    var game = Game.init();
    for ([_]u4{ 3, 6, 3, 6, 3, 6, 3, 6, 3, 6, 3, 6, 3, 6, 3, 6, 3, 6, 3, 6 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(90, game.score());
}

test "a spare followed by zeros is worth ten points" {
    var game = Game.init();
    for ([_]u4{ 6, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(10, game.score());
}

test "points scored in the roll after a spare are counted twice" {
    var game = Game.init();
    for ([_]u4{ 6, 4, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(16, game.score());
}

test "consecutive spares each get a one roll bonus" {
    var game = Game.init();
    for ([_]u4{ 5, 5, 3, 7, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(31, game.score());
}

test "a spare in the last frame gets a one roll bonus that is counted once" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 3, 7 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(17, game.score());
}

test "a strike earns ten points in a frame with a single roll" {
    var game = Game.init();
    for ([_]u4{ 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(10, game.score());
}

test "points scored in the two rolls after a strike are counted twice as a bonus" {
    var game = Game.init();
    for ([_]u4{ 10, 5, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(26, game.score());
}

test "consecutive strikes each get the two roll bonus" {
    var game = Game.init();
    for ([_]u4{ 10, 10, 10, 5, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(81, game.score());
}

test "a strike in the last frame gets a two roll bonus that is counted once" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 7, 1 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(18, game.score());
}

test "rolling a spare with the two roll bonus does not get a bonus roll" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 7, 3 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(20, game.score());
}

test "strikes with the two roll bonus do not get bonus rolls" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 10, 10 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(30, game.score());
}

test "last two strikes followed by only last bonus with non strike points" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 10, 0, 1 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(31, game.score());
}

test "a strike with the one roll bonus after a spare in the last frame does not get a bonus" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 3, 10 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(20, game.score());
}

test "all strikes is a perfect game" {
    var game = Game.init();
    for ([_]u4{ 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(300, game.score());
}

test "a roll cannot score more than 10 points" {
    var game = Game.init();
    try testing.expectError(Error.PinCountExceeded, game.roll(11));
}

test "two rolls in a frame cannot score more than 10 points" {
    var game = Game.init();
    for ([_]u4{5}) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.PinCountExceeded, game.roll(6));
}

test "bonus roll after a strike in the last frame cannot score more than 10 points" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.PinCountExceeded, game.roll(11));
}

test "two bonus rolls after a strike in the last frame cannot score more than 10 points" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 5 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.PinCountExceeded, game.roll(6));
}

test "two bonus rolls after a strike in the last frame can score more than 10 points if one is a strike" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 10, 6 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectEqual(26, game.score());
}

test "the second bonus rolls after a strike in the last frame cannot be a strike if the first one is not a strike" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 6 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.PinCountExceeded, game.roll(10));
}

test "second bonus roll after a strike in the last frame cannot score more than 10 points" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 10 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.PinCountExceeded, game.roll(11));
}

test "an unstarted game cannot be scored" {
    const game = Game.init();
    try testing.expectError(Error.GameIncomplete, game.score());
}

test "an incomplete game cannot be scored" {
    var game = Game.init();
    for ([_]u4{ 0, 0 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.GameIncomplete, game.score());
}

test "cannot roll if game already has ten frames" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.GameOver, game.roll(0));
}

test "bonus rolls for a strike in the last frame must be rolled before score can be calculated" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.GameIncomplete, game.score());
}

test "both bonus rolls for a strike in the last frame must be rolled before score can be calculated" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 10 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.GameIncomplete, game.score());
}

test "bonus roll for a spare in the last frame must be rolled before score can be calculated" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 3 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.GameIncomplete, game.score());
}

test "cannot roll after bonus roll for spare" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 3, 2 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.GameOver, game.roll(2));
}

test "cannot roll after bonus rolls for strike" {
    var game = Game.init();
    for ([_]u4{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 3, 2 }) |pins| {
        try game.roll(pins);
    }
    try testing.expectError(Error.GameOver, game.roll(2));
}
