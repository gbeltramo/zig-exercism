const std = @import("std");
const mem = std.mem;
const testing = std.testing;

/// Encodes `msg` using the rail fence cipher. Caller owns the returned memory.
pub fn encode(allocator: mem.Allocator, msg: []const u8, num_rails: u3) mem.Allocator.Error![]u8 {
    // std.debug.print("D: msg.len={d} | msg={s}\n", .{ msg.len, msg });
    const fence = try allocator.alloc([]u8, @intCast(num_rails));
    defer allocator.free(fence);

    var current_idx_rail: usize = 0;
    defer {
        for (0..current_idx_rail) |i| allocator.free(fence[i]);
    }

    for (0..@as(usize, @intCast(num_rails))) |idx_rail| {
        const rail = try allocator.alloc(u8, msg.len);
        @memset(rail, '-');
        current_idx_rail = idx_rail + 1;
        fence[idx_rail] = rail;
    }

    // std.debug.print("D: (1) fence\n", .{});
    // for (0..num_rails) |idx_rail| std.debug.print("-> '{s}'\n", .{fence[idx_rail]});

    var idx_row: usize = 0;
    var direction_row_down: bool = true;
    var idx_col: usize = 0;

    for (msg) |char| {
        fence[idx_row][idx_col] = char;

        idx_col += 1;
        if (direction_row_down) {
            if ((idx_row + 1) < num_rails) {
                idx_row += 1;
            } else {
                direction_row_down = false;
                idx_row -= 1;
            }
        } else {
            if (idx_row > 0) {
                idx_row -= 1;
            } else {
                direction_row_down = true;
                idx_row += 1;
            }
        }

        // std.debug.print("    D: set (idx_row, idx_col)=({d}, {d}) => char={d}\n", .{ idx_row, idx_col, char });
    }

    // std.debug.print("D: (2) fence\n", .{});
    // for (0..num_rails) |idx_rail| std.debug.print("-> '{s}'\n", .{fence[idx_rail]});

    const out = try allocator.alloc(u8, msg.len);
    errdefer allocator.free(out);

    var idx_out: usize = 0;
    for (0..num_rails) |i| {
        for (0..msg.len) |j| {
            const char = fence[i][j];
            if (char != '-') {
                out[idx_out] = char;
                idx_out += 1;
            }
        }
    }

    return out;
}

/// Decodes `msg` using the rail fence cipher. Caller owns the returned memory.
pub fn decode(allocator: mem.Allocator, msg: []const u8, num_rails: u3) mem.Allocator.Error![]u8 {
    const fence = try allocator.alloc([]u8, num_rails);
    defer allocator.free(fence);

    var current_idx_rail: usize = 0;
    defer {
        for (0..current_idx_rail) |i| allocator.free(fence[i]);
    }

    for (0..num_rails) |idx_rail| {
        const rail = try allocator.alloc(u8, msg.len);
        @memset(rail, '-');
        current_idx_rail = idx_rail + 1;
        fence[idx_rail] = rail;
    }

    var idx_row: usize = 0;
    var direction_row_down: bool = true;

    for (0..msg.len) |idx_col| {
        fence[idx_row][idx_col] = '*';

        if (direction_row_down) {
            if ((idx_row + 1) < num_rails) {
                idx_row += 1;
            } else {
                direction_row_down = false;
                idx_row -= 1;
            }
        } else {
            if (idx_row > 0) {
                idx_row -= 1;
            } else {
                direction_row_down = true;
                idx_row += 1;
            }
        }
    }

    var idx_msg: usize = 0;
    for (0..num_rails) |idx_rail| {
        for (0..msg.len) |idx_col| {
            if (fence[idx_rail][idx_col] == '*') {
                fence[idx_rail][idx_col] = msg[idx_msg];
                idx_msg += 1;
            }
        }
    }

    const out = try allocator.alloc(u8, msg.len);
    errdefer allocator.free(out);

    idx_row = 0;
    direction_row_down = true;
    for (0..msg.len) |idx_col| {
        out[idx_col] = fence[idx_row][idx_col];

        if (direction_row_down) {
            if ((idx_row + 1) < num_rails) {
                idx_row += 1;
            } else {
                direction_row_down = false;
                idx_row -= 1;
            }
        } else {
            if (idx_row > 0) {
                idx_row -= 1;
            } else {
                direction_row_down = true;
                idx_row += 1;
            }
        }
    }

    return out;
}

const CipherFunc = *const fn (allocator: mem.Allocator, msg: []const u8, rails: u3) mem.Allocator.Error![]u8;

fn railFenceCipherTest(allocator: mem.Allocator, cipherFunc: CipherFunc, msg: []const u8, rails: u3, expected: []const u8) anyerror!void {
    const actual = try cipherFunc(allocator, msg, rails);
    defer allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "encode with two rails" {
    const phrase: []const u8 = "XOXOXOXOXOXOXOXOXO";
    const expect: []const u8 = "XXXXXXXXXOOOOOOOOO";
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        railFenceCipherTest,
        .{ &encode, phrase, 2, expect },
    );
}

test "encode with three rails" {
    const phrase: []const u8 = "WEAREDISCOVEREDFLEEATONCE";
    const expect: []const u8 = "WECRLTEERDSOEEFEAOCAIVDEN";
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        railFenceCipherTest,
        .{ &encode, phrase, 3, expect },
    );
}

test "encode with ending in the middle" {
    const phrase: []const u8 = "EXERCISES";
    const expect: []const u8 = "ESXIEECSR";
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        railFenceCipherTest,
        .{ &encode, phrase, 4, expect },
    );
}

test "decode with three rails" {
    const phrase: []const u8 = "TEITELHDVLSNHDTISEIIEA";
    const expect: []const u8 = "THEDEVILISINTHEDETAILS";
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        railFenceCipherTest,
        .{ &decode, phrase, 3, expect },
    );
}

test "decode with five rails" {
    const phrase: []const u8 = "EIEXMSMESAORIWSCE";
    const expect: []const u8 = "EXERCISMISAWESOME";
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        railFenceCipherTest,
        .{ &decode, phrase, 5, expect },
    );
}

test "decode with six rails" {
    const phrase: []const u8 = "133714114238148966225439541018335470986172518171757571896261";
    const expect: []const u8 = "112358132134558914423337761098715972584418167651094617711286";
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        railFenceCipherTest,
        .{ &decode, phrase, 6, expect },
    );
}

test "encode alphabet" {
    const phrase: []const u8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const expect: []const u8 = "ACEGIKMOQSUWYBDFHJLNPRTVXZ";
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        railFenceCipherTest,
        .{ &encode, phrase, 2, expect },
    );
}

test "decode alphabet" {
    const phrase: []const u8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const expect: []const u8 = "ANBOCPDQERFSGTHUIVJWKXLYMZ";
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        railFenceCipherTest,
        .{ &decode, phrase, 2, expect },
    );
}
