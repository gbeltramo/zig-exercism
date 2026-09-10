const std = @import("std");
const testing = std.testing;

pub const GameState = enum {
    win,
    draw,
    ongoing,
    impossible,
};

pub fn gameState(board: []const []const u8) GameState {
    const num_x = countPlayer('X', board);
    const num_o = countPlayer('O', board);
    const num_spaces = countPlayer(' ', board);

    if (num_o > num_x) return GameState.impossible;
    if ((num_x - num_o) > 1) return GameState.impossible;

    const x_won = playerWins('X', board);
    const o_won = playerWins('O', board);

    if (x_won and o_won) {
        return GameState.impossible;
    } else if (x_won or o_won) {
        if (x_won and (num_x == num_o)) return GameState.impossible;
        if (o_won and (num_x != num_o)) return GameState.impossible;
        return GameState.win;
    } else if (num_spaces > 0) {
        return GameState.ongoing;
    } else {
        return GameState.draw;
    }
}

pub fn countPlayer(player: u8, board: []const []const u8) usize {
    var count: usize = 0;
    for (board) |row| {
        for (row) |c| {
            count += @intFromBool(player == c);
        }
    }
    return count;
}

pub fn playerWins(player: u8, board: []const []const u8) bool {
    for (board) |row| {
        var is_win: bool = true;
        for (row) |c| {
            if (c != player) is_win = false;
        }
        if (is_win) return true;
    }

    const board_cols = [3][3]u8{
        [3]u8{ board[0][0], board[1][0], board[2][0] },
        [3]u8{ board[0][1], board[1][1], board[2][1] },
        [3]u8{ board[0][2], board[1][2], board[2][2] },
    };

    for (board_cols) |col| {
        var is_win: bool = true;
        for (col) |c| {
            if (c != player) is_win = false;
        }
        if (is_win) return true;
    }

    if ((board[0][0] == player) and (board[1][1] == player) and (board[2][2] == player)) return true;
    if ((board[0][2] == player) and (board[1][1] == player) and (board[2][0] == player)) return true;

    return false;
}

fn testGameState(board: []const []const u8, expected: GameState) !void {
    const actual = gameState(board);
    try testing.expectEqual(expected, actual);
}

test "Won games-Finished game where X won via left column victory" {
    const board = [_][]const u8{
        "XOO", //
        "X  ", //
        "X  ", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where X won via middle column victory" {
    const board = [_][]const u8{
        "OXO", //
        " X ", //
        " X ", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where X won via right column victory" {
    const board = [_][]const u8{
        "OOX", //
        "  X", //
        "  X", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where O won via left column victory" {
    const board = [_][]const u8{
        "OXX", //
        "OX ", //
        "O  ", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where O won via middle column victory" {
    const board = [_][]const u8{
        "XOX", //
        " OX", //
        " O ", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where O won via right column victory" {
    const board = [_][]const u8{
        "XXO", //
        " XO", //
        "  O", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where X won via top row victory" {
    const board = [_][]const u8{
        "XXX", //
        "XOO", //
        "O  ", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where X won via middle row victory" {
    const board = [_][]const u8{
        "O  ", //
        "XXX", //
        " O ", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where X won via bottom row victory" {
    const board = [_][]const u8{
        " OO", //
        "O X", //
        "XXX", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where O won via top row victory" {
    const board = [_][]const u8{
        "OOO", //
        "XXO", //
        "XX ", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where O won via middle row victory" {
    const board = [_][]const u8{
        "XX ", //
        "OOO", //
        "X  ", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where O won via bottom row victory" {
    const board = [_][]const u8{
        "XOX", //
        " XX", //
        "OOO", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where X won via falling diagonal victory" {
    const board = [_][]const u8{
        "XOO", //
        " X ", //
        "  X", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where X won via rising diagonal victory" {
    const board = [_][]const u8{
        "O X", //
        "OX ", //
        "X  ", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where O won via falling diagonal victory" {
    const board = [_][]const u8{
        "OXX", //
        "OOX", //
        "X O", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where O won via rising diagonal victory" {
    const board = [_][]const u8{
        "  O", //
        " OX", //
        "OXX", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where X won via a row and a column victory" {
    const board = [_][]const u8{
        "XXX", //
        "XOO", //
        "XOO", //
    };
    try testGameState(&board, GameState.win);
}

test "Won games-Finished game where X won via two diagonal victories" {
    const board = [_][]const u8{
        "XOX", //
        "OXO", //
        "XOX", //
    };
    try testGameState(&board, GameState.win);
}

test "Drawn games-Draw" {
    const board = [_][]const u8{
        "XOX", //
        "XXO", //
        "OXO", //
    };
    try testGameState(&board, GameState.draw);
}

test "Drawn games-Another draw" {
    const board = [_][]const u8{
        "XXO", //
        "OXX", //
        "XOO", //
    };
    try testGameState(&board, GameState.draw);
}

test "Ongoing games-Ongoing game: one move in" {
    const board = [_][]const u8{
        "   ", //
        "X  ", //
        "   ", //
    };
    try testGameState(&board, GameState.ongoing);
}

test "Ongoing games-Ongoing game: two moves in" {
    const board = [_][]const u8{
        "O  ", //
        " X ", //
        "   ", //
    };
    try testGameState(&board, GameState.ongoing);
}

test "Ongoing games-Ongoing game: five moves in" {
    const board = [_][]const u8{
        "X  ", //
        " XO", //
        "OX ", //
    };
    try testGameState(&board, GameState.ongoing);
}

test "Invalid boards-Invalid board: X went twice" {
    const board = [_][]const u8{
        "XX ", //
        "   ", //
        "   ", //
    };
    // Wrong turn order: X went twice
    try testGameState(&board, GameState.impossible);
}

test "Invalid boards-Invalid board: O started" {
    const board = [_][]const u8{
        "OOX", //
        "   ", //
        "   ", //
    };
    // Wrong turn order: O started
    try testGameState(&board, GameState.impossible);
}

test "Invalid boards-Invalid board: X won and O kept playing" {
    const board = [_][]const u8{
        "XXX", //
        "OOO", //
        "   ", //
    };
    // Impossible board: game should have ended after the game was won
    try testGameState(&board, GameState.impossible);
}

test "Invalid boards-Invalid board: players kept playing after a win" {
    const board = [_][]const u8{
        "XXX", //
        "OOO", //
        "XOX", //
    };
    // Impossible board: game should have ended after the game was won
    try testGameState(&board, GameState.impossible);
}

test "Invalid boards-Invalid board: O kept playing after X wins" {
    const board = [_][]const u8{
        "OO ", //
        "XXX", //
        " O ", //
    };
    // Impossible board: game should have ended after the game was won
    try testGameState(&board, GameState.impossible);
}

test "Invalid boards-Invalid board: X kept playing after O wins" {
    const board = [_][]const u8{
        "XX ", //
        "OOO", //
        " XX", //
    };
    // Impossible board: game should have ended after the game was won
    try testGameState(&board, GameState.impossible);
}
