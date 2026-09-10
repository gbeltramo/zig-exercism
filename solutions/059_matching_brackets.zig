const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn isBalanced(allocator: mem.Allocator, s: []const u8) !bool {
    var stack = try std.ArrayList(u8).initCapacity(allocator, 16);
    defer stack.deinit(allocator);

    for (s) |c| {
        const is_bracket = (c == '(') or (c == ')') or (c == '[') or (c == ']') or (c == '{') or (c == '}');
        if (!is_bracket) {
            continue;
        } else {
            if (stack.items.len > 0) {
                const last_bracket = stack.pop().?;
                const it_worked = switch (c) {
                    '(', ')' => try appendBracketOrFail(allocator, &stack, c, last_bracket, '('),
                    '[', ']' => try appendBracketOrFail(allocator, &stack, c, last_bracket, '['),
                    '{', '}' => try appendBracketOrFail(allocator, &stack, c, last_bracket, '{'),
                    else => false,
                };
                if (!it_worked) return false;
            } else {
                if ((c == ')') or (c == ']') or (c == '}')) {
                    return false;
                } else {
                    try stack.append(allocator, c);
                }
            }
        }
    }

    return stack.items.len == 0;
}

pub fn appendBracketOrFail(allocator: mem.Allocator, stack: *std.ArrayList(u8), current: u8, last_bracket: u8, open_bracket: u8) !bool {
    std.debug.assert((open_bracket == '(') or (open_bracket == '[') or (open_bracket == '{'));

    if (current == open_bracket) {
        try stack.append(allocator, last_bracket);
        try stack.append(allocator, current);
        return true;
    } else {
        return if (!(last_bracket == open_bracket)) false else true;
    }
}

test "paired square brackets" {
    const actual = try isBalanced(testing.allocator, "[]");
    try testing.expect(actual);
}

test "empty string" {
    const actual = try isBalanced(testing.allocator, "");
    try testing.expect(actual);
}

test "unpaired brackets" {
    const actual = try isBalanced(testing.allocator, "[[");
    try testing.expect(!actual);
}

test "wrong ordered brackets" {
    const actual = try isBalanced(testing.allocator, "}{");
    try testing.expect(!actual);
}

test "wrong closing bracket" {
    const actual = try isBalanced(testing.allocator, "{]");
    try testing.expect(!actual);
}

test "paired with whitespace" {
    const actual = try isBalanced(testing.allocator, "{ }");
    try testing.expect(actual);
}

test "partially paired brackets" {
    const actual = try isBalanced(testing.allocator, "{[])");
    try testing.expect(!actual);
}

test "simple nested brackets" {
    const actual = try isBalanced(testing.allocator, "{[]}");
    try testing.expect(actual);
}

test "several paired brackets" {
    const actual = try isBalanced(testing.allocator, "{}[]");
    try testing.expect(actual);
}

test "paired and nested brackets" {
    const actual = try isBalanced(testing.allocator, "([{}({}[])])");
    try testing.expect(actual);
}

test "unopened closing brackets" {
    const actual = try isBalanced(testing.allocator, "{[)][]}");
    try testing.expect(!actual);
}

test "unpaired and nested brackets" {
    const actual = try isBalanced(testing.allocator, "([{])");
    try testing.expect(!actual);
}

test "paired and wrong nested brackets" {
    const actual = try isBalanced(testing.allocator, "[({]})");
    try testing.expect(!actual);
}

test "paired and wrong nested brackets but innermost are correct" {
    const actual = try isBalanced(testing.allocator, "[({}])");
    try testing.expect(!actual);
}

test "paired and incomplete brackets" {
    const actual = try isBalanced(testing.allocator, "{}[");
    try testing.expect(!actual);
}

test "too many closing brackets" {
    const actual = try isBalanced(testing.allocator, "[]]");
    try testing.expect(!actual);
}

test "early unexpected brackets" {
    const actual = try isBalanced(testing.allocator, ")()");
    try testing.expect(!actual);
}

test "early mismatched brackets" {
    const actual = try isBalanced(testing.allocator, "{)()");
    try testing.expect(!actual);
}

test "math expression" {
    const actual = try isBalanced(testing.allocator, "(((185 + 223.85) * 15) - 543)/2");
    try testing.expect(actual);
}

test "complex latex expression" {
    const s = "\\left(\\begin{array}{cc} \\frac{1}{3} & x\\\\ \\mathrm{e}^{x} &... x^2 \\end{array}\\right)";
    const actual = try isBalanced(testing.allocator, s);
    try testing.expect(actual);
}

test "maximum required level of nesting" {
    const s = "(((_[[[_{{{_()_}}}_]]]_)))";
    const actual = try isBalanced(testing.allocator, s);
    try testing.expect(actual);
}
