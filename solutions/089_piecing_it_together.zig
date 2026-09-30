const std = @import("std");
const testing = std.testing;

pub const PuzzleError = error{
    InsufficientData,
    ContradictoryData,
};

pub const Format = enum {
    portrait,
    square,
    landscape,
};

pub const PartialInformation = struct {
    pieces: ?u30 = null, //
    border: ?u30 = null, //
    inside: ?u30 = null, //
    rows: ?u30 = null, //
    columns: ?u30 = null, //
    aspectRatio: ?f64 = null, //
    format: ?Format = null, //
};

pub const FullInformation = struct {
    pieces: u30, //
    border: u30, //
    inside: u30, //
    rows: u30, //
    columns: u30, //
    aspectRatio: f64, //
    format: Format, //
};

pub fn jigsawData(puzzle: PartialInformation) PuzzleError!FullInformation {
    var num_rows: u30 = 0;
    var num_cols: u30 = 0;

    const p = puzzle;
    if (p.pieces == null and p.border == null and p.inside == null and p.rows == null and p.columns == null) {
        return PuzzleError.InsufficientData;
    } else if (p.rows != null and p.columns != null) {
        num_rows = p.rows.?;
        num_cols = p.columns.?;
    } else if (p.pieces != null or p.border != null or p.inside != null) {
        var upper_bound: u30 = 0;

        if (p.pieces != null) {
            upper_bound = p.pieces.? - 1;
        } else if (p.border != null) {
            if ((p.border.? % 2) != 0) return PuzzleError.ContradictoryData;
            upper_bound = p.border.? / 2 + 2;
        } else if (p.inside != null) {
            upper_bound = p.inside.? + 2;
        }

        var one_valid_was_found: bool = false;

        for (1..upper_bound + 1) |r| {
            for (1..upper_bound + 1) |c| {
                const possible_full = makeFromRowCol(@intCast(r), @intCast(c));
                const is_valid = checkPartialConsistentWithFull(puzzle, possible_full);

                if (one_valid_was_found and is_valid) {
                    // NOTE More than one valid configuration was found.
                    // NOTE The partial puzzle information is not restrictive enough
                    return PuzzleError.InsufficientData;
                }
                if (is_valid) {
                    one_valid_was_found = true;
                    num_rows = @intCast(r);
                    num_cols = @intCast(c);
                }
            }
        }
        // NOTE After the loop above it is ambiguous if the data was insufficient or contradictory
        // NOTE Leaving it like this in the interest of time
    } else if ((p.rows != null) or (p.columns != null)) {
        // NOTE here only rows or columns is giving shape information and is not null
        var side: u30 = 0;
        if (p.rows != null) {
            side = p.rows.?;
        } else if (p.columns != null) {
            side = p.columns.?;
        }

        if (p.format != null) {
            if (p.format.? == Format.square) {
                num_rows = side;
                num_cols = side;
            } else {
                return PuzzleError.InsufficientData;
            }
        } else if (p.aspectRatio != null) {
            if (p.rows != null) {
                num_rows = p.rows.?;
                num_cols = @as(u30, @intFromFloat(
                    @trunc(p.aspectRatio.? * @as(f64, @floatFromInt(num_rows))),
                ));
            }
            num_rows = side;
        } else {
            return PuzzleError.InsufficientData;
        }
    }

    if (num_rows == 0 and num_cols == 0) return PuzzleError.InsufficientData;

    const possible_full = makeFromRowCol(num_rows, num_cols);
    const is_valid = checkPartialConsistentWithFull(puzzle, possible_full);

    if (is_valid) {
        return possible_full;
    } else {
        return PuzzleError.ContradictoryData;
    }
}

pub fn checkPartialConsistentWithFull(partial: PartialInformation, full: FullInformation) bool {
    if ((partial.pieces != null) and (partial.pieces.? != full.pieces)) {
        return false;
    } else if ((partial.border != null) and (partial.border.? != full.border)) {
        return false;
    } else if ((partial.inside != null) and (partial.inside.? != full.inside)) {
        return false;
    } else if ((partial.rows != null) and (partial.rows.? != full.rows)) {
        return false;
    } else if ((partial.columns != null) and (partial.columns.? != full.columns)) {
        return false;
    } else if ((partial.aspectRatio != null) and (partial.aspectRatio.? != full.aspectRatio)) {
        return false;
    } else if ((partial.format != null) and (partial.format.? != full.format)) {
        return false;
    }

    return true;
}

pub fn makeFromRowCol(num_rows: u30, num_cols: u30) FullInformation {
    var inside: u30 = 0;
    if ((num_rows > 2) and (num_cols > 2)) {
        inside = (num_rows - 2) * (num_cols - 2);
    }

    var aspect_ratio: f64 = 0;
    if (num_rows > 0) {
        aspect_ratio = @as(f64, @floatFromInt(num_cols)) / @as(f64, @floatFromInt(num_rows));
    }

    var format: Format = .square;
    if (num_rows > num_cols) {
        format = .portrait;
    } else if (num_cols > num_rows) {
        format = .landscape;
    }

    return .{
        .pieces = num_rows * num_cols,
        .border = 2 * num_rows + 2 * num_cols - 4,
        .inside = inside,
        .rows = num_rows,
        .columns = num_cols,
        .aspectRatio = aspect_ratio,
        .format = format,
    };
}

test "1000 pieces puzzle with 1.6 aspect ratio" {
    const puzzle = PartialInformation{
        .pieces = 1000,
        .aspectRatio = 1.6,
    };
    const expected = FullInformation{
        .pieces = 1000,
        .border = 126,
        .inside = 874,
        .rows = 25,
        .columns = 40,
        .aspectRatio = 1.6,
        .format = .landscape,
    };
    const actual = try jigsawData(puzzle);
    try testing.expectEqual(expected, actual);
}

test "square puzzle with 32 rows" {
    const puzzle = PartialInformation{
        .rows = 32,
        .format = .square,
    };
    const expected = FullInformation{
        .pieces = 1024,
        .border = 124,
        .inside = 900,
        .rows = 32,
        .columns = 32,
        .aspectRatio = 1.0,
        .format = .square,
    };
    const actual = try jigsawData(puzzle);
    try testing.expectEqual(expected, actual);
}

test "400 pieces square puzzle with only inside pieces and aspect ratio" {
    const puzzle = PartialInformation{
        .inside = 324,
        .aspectRatio = 1.0,
    };
    const expected = FullInformation{
        .pieces = 400,
        .border = 76,
        .inside = 324,
        .rows = 20,
        .columns = 20,
        .aspectRatio = 1.0,
        .format = .square,
    };
    const actual = try jigsawData(puzzle);
    try testing.expectEqual(expected, actual);
}

test "1500 pieces landscape puzzle with 30 rows and 1.6 aspect ratio" {
    const puzzle = PartialInformation{
        .rows = 30,
        .aspectRatio = 1.6666666666666667,
    };
    const expected = FullInformation{
        .pieces = 1500,
        .border = 156,
        .inside = 1344,
        .rows = 30,
        .columns = 50,
        .aspectRatio = 1.6666666666666667,
        .format = .landscape,
    };
    const actual = try jigsawData(puzzle);
    try testing.expectEqual(expected, actual);
}

test "300 pieces portrait puzzle with 70 border pieces" {
    const puzzle = PartialInformation{
        .pieces = 300,
        .border = 70,
        .format = .portrait,
    };
    const expected = FullInformation{
        .pieces = 300,
        .border = 70,
        .inside = 230,
        .rows = 25,
        .columns = 12,
        .aspectRatio = 0.48,
        .format = .portrait,
    };
    const actual = try jigsawData(puzzle);
    try testing.expectEqual(expected, actual);
}

test "puzzle with insufficient data" {
    const puzzle = PartialInformation{
        .pieces = 1500,
        .format = .landscape,
    };
    const actual = jigsawData(puzzle);
    try testing.expectError(PuzzleError.InsufficientData, actual);
}

test "puzzle with contradictory data" {
    const puzzle = PartialInformation{
        .rows = 100,
        .columns = 1000,
        .format = .square,
    };
    const actual = jigsawData(puzzle);
    try testing.expectError(PuzzleError.ContradictoryData, actual);
}

test "very large landscape" {
    const puzzle = PartialInformation{
        .border = 1216,
        .inside = 86625,
        .format = .landscape,
    };
    const expected = FullInformation{
        .pieces = 87841,
        .border = 1216,
        .inside = 86625,
        .rows = 233,
        .columns = 377,
        .aspectRatio = 1.6180257510729614,
        .format = .landscape,
    };
    const actual = try jigsawData(puzzle);
    try testing.expectEqual(expected, actual);
}
