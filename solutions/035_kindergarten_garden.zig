const std = @import("std");
const testing = std.testing;

pub const Plant = enum {
    clover,
    grass,
    radishes,
    violets,
};

pub fn plants(diagram: []const u8, student: []const u8) [4]Plant {
    if (diagram.len == 0) {
        return [4]Plant{ .clover, .clover, .clover, .clover };
    }

    const target_idx_student = std.ascii.toLower(student[0]) - 'a';

    var idx: usize = 0;
    var c = diagram[0];
    var out: [4]Plant = undefined;
    while (c != '\n') {
        c = diagram[idx];
        const idx_student: usize = @divFloor(idx, 2);
        if (idx_student == target_idx_student) {
            out[idx % 2] = mapLetterToPlant(c);
        }

        idx += 1;
    }

    const offset = idx;

    while (idx < diagram.len) {
        c = diagram[idx];
        const idx_student: usize = @divFloor(idx - offset, 2);
        if (idx_student == target_idx_student) {
            out[(idx - offset) % 2 + 2] = mapLetterToPlant(c);
        }

        idx += 1;
    }

    return out;
}

pub fn mapLetterToPlant(c: u8) Plant {
    return switch (c) {
        'G' => Plant.grass,
        'C' => Plant.clover,
        'R' => Plant.radishes,
        'V' => Plant.violets,
        else => Plant.grass,
    };
}

test "partial garden with single student" {
    const diagram: []const u8 =
        \\RC
        \\GG
    ;
    const expected = .{ .radishes, .clover, .grass, .grass };
    const actual = plants(diagram, "Alice");
    try testing.expectEqual(expected, actual);
}

test "partial garden-different garden with single student" {
    const diagram: []const u8 =
        \\VC
        \\RC
    ;
    const expected = .{ .violets, .clover, .radishes, .clover };
    const actual = plants(diagram, "Alice");
    try testing.expectEqual(expected, actual);
}

test "partial garden with two students" {
    const diagram: []const u8 =
        \\VVCG
        \\VVRC
    ;
    const expected = .{ .clover, .grass, .radishes, .clover };
    const actual = plants(diagram, "Bob");
    try testing.expectEqual(expected, actual);
}

test "partial garden-multiple students for the same garden with three students-second student's garden" {
    const diagram: []const u8 =
        \\VVCCGG
        \\VVCCGG
    ;
    const expected = .{ .clover, .clover, .clover, .clover };
    const actual = plants(diagram, "Bob");
    try testing.expectEqual(expected, actual);
}

test "partial garden-multiple students for the same garden with three students-third student's garden" {
    const diagram: []const u8 =
        \\VVCCGG
        \\VVCCGG
    ;
    const expected = .{ .grass, .grass, .grass, .grass };
    const actual = plants(diagram, "Charlie");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Alice, first student's garden" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .violets, .radishes, .violets, .radishes };
    const actual = plants(diagram, "Alice");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Bob, second student's garden" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .clover, .grass, .clover, .clover };
    const actual = plants(diagram, "Bob");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Charlie" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .violets, .violets, .clover, .grass };
    const actual = plants(diagram, "Charlie");
    try testing.expectEqual(expected, actual);
}

test "full garden-for David" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .radishes, .violets, .clover, .radishes };
    const actual = plants(diagram, "David");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Eve" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .clover, .grass, .radishes, .grass };
    const actual = plants(diagram, "Eve");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Fred" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .grass, .clover, .violets, .clover };
    const actual = plants(diagram, "Fred");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Ginny" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .clover, .grass, .grass, .clover };
    const actual = plants(diagram, "Ginny");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Harriet" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .violets, .radishes, .radishes, .violets };
    const actual = plants(diagram, "Harriet");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Ileana" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .grass, .clover, .violets, .clover };
    const actual = plants(diagram, "Ileana");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Joseph" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .violets, .clover, .violets, .grass };
    const actual = plants(diagram, "Joseph");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Kincaid, second to last student's garden" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .grass, .clover, .clover, .grass };
    const actual = plants(diagram, "Kincaid");
    try testing.expectEqual(expected, actual);
}

test "full garden-for Larry, last student's garden" {
    const diagram: []const u8 =
        \\VRCGVVRVCGGCCGVRGCVCGCGV
        \\VRCCCGCRRGVCGCRVVCVGCGCV
    ;
    const expected = .{ .grass, .violets, .clover, .violets };
    const actual = plants(diagram, "Larry");
    try testing.expectEqual(expected, actual);
}
