const std = @import("std");
const testing = std.testing;

pub const Relation = enum {
    equal,
    sublist,
    superlist,
    unequal,
};

pub fn isSublist(list_one: []const i32, list_two: []const i32) bool {
    if (list_one.len < list_two.len) {
        for (list_two, 0..) |_, idx2| {
            if ((list_two.len - idx2) < list_one.len) {
                return false;
            }

            var all_elements_are_equal: bool = true;
            inner_loop: for (list_one, 0..) |v1, idx1| {
                if (v1 != list_two[idx1 + idx2]) {
                    all_elements_are_equal = false;
                    break :inner_loop;
                }
            }

            if (all_elements_are_equal) {
                return true;
            }
        }
    }

    return false;
}

pub fn compare(list_one: []const i32, list_two: []const i32) Relation {
    if ((list_one.len == 0) and (list_two.len == 0)) {
        return Relation.equal;
    } else if ((list_one.len == 0) and (list_two.len > 0)) {
        return Relation.sublist;
    } else if ((list_one.len > 0) and (list_two.len == 0)) {
        return Relation.superlist;
    }

    if (std.mem.eql(i32, list_one, list_two)) {
        return Relation.equal;
    }

    if (isSublist(list_one, list_two)) {
        return Relation.sublist;
    }

    if (isSublist(list_two, list_one)) {
        return Relation.superlist;
    }

    return Relation.unequal;
}

test "empty lists" {
    const list_one = &[_]i32{};
    const list_two = &[_]i32{};
    const expected = .equal;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "empty list within non empty list" {
    const list_one = &[_]i32{};
    const list_two = &[_]i32{ 1, 2, 3 };
    const expected = .sublist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "non empty list contains empty list" {
    const list_one = &[_]i32{ 1, 2, 3 };
    const list_two = &[_]i32{};
    const expected = .superlist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "list equals itself" {
    const list_one = &[_]i32{ 1, 2, 3 };
    const list_two = &[_]i32{ 1, 2, 3 };
    const expected = .equal;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "different lists" {
    const list_one = &[_]i32{ 1, 2, 3 };
    const list_two = &[_]i32{ 2, 3, 4 };
    const expected = .unequal;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "false start" {
    const list_one = &[_]i32{ 1, 2, 5 };
    const list_two = &[_]i32{ 0, 1, 2, 3, 1, 2, 5, 6 };
    const expected = .sublist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "consecutive" {
    const list_one = &[_]i32{ 1, 1, 2 };
    const list_two = &[_]i32{ 0, 1, 1, 1, 2, 1, 2 };
    const expected = .sublist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "sublist at start" {
    const list_one = &[_]i32{ 0, 1, 2 };
    const list_two = &[_]i32{ 0, 1, 2, 3, 4, 5 };
    const expected = .sublist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "sublist in middle" {
    const list_one = &[_]i32{ 2, 3, 4 };
    const list_two = &[_]i32{ 0, 1, 2, 3, 4, 5 };
    const expected = .sublist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "sublist at end" {
    const list_one = &[_]i32{ 3, 4, 5 };
    const list_two = &[_]i32{ 0, 1, 2, 3, 4, 5 };
    const expected = .sublist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "at start of superlist" {
    const list_one = &[_]i32{ 0, 1, 2, 3, 4, 5 };
    const list_two = &[_]i32{ 0, 1, 2 };
    const expected = .superlist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "in middle of superlist" {
    const list_one = &[_]i32{ 0, 1, 2, 3, 4, 5 };
    const list_two = &[_]i32{ 2, 3 };
    const expected = .superlist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "at end of superlist" {
    const list_one = &[_]i32{ 0, 1, 2, 3, 4, 5 };
    const list_two = &[_]i32{ 3, 4, 5 };
    const expected = .superlist;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "first list missing element from second list" {
    const list_one = &[_]i32{ 1, 3 };
    const list_two = &[_]i32{ 1, 2, 3 };
    const expected = .unequal;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "second list missing element from first list" {
    const list_one = &[_]i32{ 1, 2, 3 };
    const list_two = &[_]i32{ 1, 3 };
    const expected = .unequal;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "first list missing additional digits from second list" {
    const list_one = &[_]i32{ 1, 2 };
    const list_two = &[_]i32{ 1, 22 };
    const expected = .unequal;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "order matters to a list" {
    const list_one = &[_]i32{ 1, 2, 3 };
    const list_two = &[_]i32{ 3, 2, 1 };
    const expected = .unequal;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}

test "same digits but different numbers" {
    const list_one = &[_]i32{ 1, 0, 1 };
    const list_two = &[_]i32{ 10, 1 };
    const expected = .unequal;
    const actual = compare(list_one, list_two);
    try testing.expectEqual(expected, actual);
}
