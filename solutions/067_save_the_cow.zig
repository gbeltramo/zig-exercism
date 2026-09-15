const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const State = enum {
    ongoing,
    win,
    lose,
};

pub const Error = error{ GameAlreadyWon, GameAlreadyLost };

pub const Game = struct {
    state: State,
    remaining_failures: u32,
    letters: std.BufSet,
    initial_word: std.ArrayList(u8),

    /// Initializes a game with a copy of the given word, 9 remaining failures
    /// and every letter hidden.
    pub fn init(allocator: mem.Allocator, word: []const u8) mem.Allocator.Error!Game {
        var letters = std.BufSet.init(allocator);
        errdefer letters.deinit();

        var initial_word = try std.ArrayList(u8).initCapacity(allocator, word.len);
        errdefer initial_word.deinit(allocator);

        for (0..word.len) |idx| try letters.insert(word[idx .. idx + 1]);
        for (word) |l| initial_word.appendAssumeCapacity(l);

        return Game{
            .state = .ongoing,
            .remaining_failures = 9,
            .letters = letters,
            .initial_word = initial_word,
        };
    }

    /// Frees the game.
    pub fn deinit(self: *Game, allocator: mem.Allocator) void {
        self.letters.deinit();
        self.initial_word.deinit(allocator);
    }

    /// Processes one guessed letter.
    pub fn guess(self: *Game, letter: u8) Error!void {
        if (self.state == .lose) {
            return Error.GameAlreadyLost;
        } else if (self.state == .win) {
            return Error.GameAlreadyWon;
        }

        const value = [1]u8{letter};
        if (self.letters.contains(&value)) {
            self.letters.remove(&value);
        } else {
            if (self.remaining_failures == 0) {
                self.state = .lose;
                return;
            }
            self.remaining_failures -= 1;
        }

        if (self.letters.count() == 0) self.state = .win;
    }

    /// Returns the word with every unguessed letter replaced by an underscore.
    pub fn maskedWord(self: *const Game) []const u8 {
        var it = self.letters.iterator();
        while (it.next()) |item| {
            const letter_to_be_found = item.*[0];
            for (0..self.initial_word.items.len) |idx| {
                if (self.initial_word.items[idx] == letter_to_be_found) self.initial_word.items[idx] = '_';
            }
        }
        return self.initial_word.items;
    }
};

fn testGame(
    allocator: std.mem.Allocator,
    word: []const u8,
    guesses: []const u8,
    state: State,
    masked_word: []const u8,
    remaining_failures: u32,
) !void {
    var game = try Game.init(allocator, word);
    defer game.deinit(allocator);
    for (guesses) |letter| try game.guess(letter);
    try testing.expectEqual(state, game.state);
    try testing.expectEqualStrings(masked_word, game.maskedWord());
    try testing.expectEqual(remaining_failures, game.remaining_failures);
}

/// Plays `guesses` against `word` and checks that the final guess returns
/// `expected_error`.
fn testGameError(
    allocator: std.mem.Allocator,
    word: []const u8,
    guesses: []const u8,
    expected_error: anyerror,
) !void {
    var game = try Game.init(allocator, word);
    defer game.deinit(allocator);
    for (guesses[0 .. guesses.len - 1]) |letter| try game.guess(letter);
    try testing.expectError(expected_error, game.guess(guesses[guesses.len - 1]));
}

test "Initially 9 failures are allowed and no letters are guessed" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGame,
        .{ "loot", "", .ongoing, "____", 9 },
    );
}

test "After 10 failures the game is over" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGame,
        .{ "loot", "abcdefghij", .lose, "____", 0 },
    );
}

test "Losing with several correct guesses" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGame,
        .{ "loot", "toabcdefghij", .lose, "_oot", 0 },
    );
}

test "Feeding a correct letter removes underscores" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGame,
        .{ "loot", "t", .ongoing, "___t", 9 },
    );
}

test "Feeding a correct letter twice counts as a failure" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGame,
        .{ "loot", "tt", .ongoing, "___t", 8 },
    );
}

test "Guessing a repeated letter reveals all instances" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGame,
        .{ "loot", "tto", .ongoing, "_oot", 8 },
    );
}

test "Getting all the letters right makes for a win" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGame,
        .{ "loot", "ttol", .win, "loot", 8 },
    );
}

test "Winning on the last guess is still a win" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGame,
        .{ "loot", "abcdefghitol", .win, "loot", 0 },
    );
}

test "Guessing after a lose is error" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGameError,
        .{ "loot", "abcdefghijk", error.GameAlreadyLost },
    );
}

test "Guessing after a win is error" {
    try testing.checkAllAllocationFailures(
        testing.allocator,
        testGameError,
        .{ "loot", "toll", error.GameAlreadyWon },
    );
}
