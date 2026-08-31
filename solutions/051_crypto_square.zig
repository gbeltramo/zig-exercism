const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn Matrix(comptime T: type) type {
    return struct {
        num_rows: usize,
        num_cols: usize,
        data: []T,

        pub fn init(allocator: mem.Allocator, num_rows: usize, num_cols: usize) !Matrix(T) {
            return .{
                .num_rows = num_rows,
                .num_cols = num_cols,
                .data = try allocator.alloc(T, num_rows * num_cols),
            };
        }

        pub fn get(self: Matrix(T), i: usize, j: usize) T {
            return self.data[i * self.num_cols + j];
        }

        pub fn set(self: Matrix(T), i: usize, j: usize, new_value: T) void {
            self.data[i * self.num_cols + j] = new_value;
        }

        pub fn debugPrint(self: Matrix(T)) void {
            for (0..self.num_rows) |i| {
                std.debug.print("[", .{});
                for (0..self.num_cols) |j| {
                    std.debug.print("{d}", .{self.get(i, j)});
                    if (j != (self.num_cols - 1)) std.debug.print(" ", .{});
                }
                std.debug.print("]\n", .{});
            }
        }

        pub fn deinit(self: Matrix(T), allocator: mem.Allocator) void {
            allocator.free(self.data);
        }
    };
}

/// Encodes `plaintext` using the square code. Caller owns the returned memory.
pub fn ciphertext(allocator: mem.Allocator, plaintext: []const u8) mem.Allocator.Error![]u8 {
    var list = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer list.deinit(allocator);

    for (plaintext) |c| {
        if (std.ascii.isAlphanumeric(c)) try list.append(allocator, std.ascii.toLower(c));
    }
    // std.debug.print("D: list.items={s}\n", .{list.items});

    if (list.items.len == 0) return "";

    var num_cols: usize = std.math.sqrt(list.items.len);
    if (num_cols * num_cols < list.items.len) num_cols += 1;
    const num_rows = if (num_cols * (num_cols - 1) >= list.items.len) num_cols - 1 else num_cols;

    const M = try Matrix(u8).init(allocator, num_rows, num_cols);
    defer M.deinit(allocator);

    for (0..M.data.len) |i| M.data[i] = ' ';

    for (list.items, 0..) |c, idx| {
        const i = idx / num_cols;
        const j = idx % num_cols;
        // std.debug.print("    D: setting c={d} in (i, j)=({d}, {d}) in M\n", .{ c, i, j });
        M.set(i, j, c);
    }
    // M.debugPrint();
    // std.debug.print("---\n", .{});

    const out = try allocator.alloc(u8, M.num_rows * M.num_cols + num_cols - 1);
    // std.debug.print("D: INITIAL out={s}\n", .{out});
    var idx_out: usize = 0;
    for (0..num_cols) |idx_j| {
        for (0..num_rows) |idx_i| {
            const v = M.get(idx_i, idx_j);
            out[idx_out] = v;
            idx_out += 1;
            // std.debug.print("    D: Out => (i, j)=({d}, {d}) => idx_out={d} | v={d}\n", .{ idx_i, idx_j, idx_out, v });
        }
        if (idx_j != (num_cols - 1)) {
            out[idx_out] = ' ';
            idx_out += 1;
        }
    }
    // std.debug.print("D: FINAL out={s}\n", .{out});

    return out;
}

test "empty plaintext results in an empty ciphertext" {
    const expected: []const u8 = "";
    const actual = try ciphertext(testing.allocator, "");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "normalization results in empty plaintext" {
    const expected: []const u8 = "";
    const actual = try ciphertext(testing.allocator, "... --- ...");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "Lowercase" {
    const expected: []const u8 = "a";
    const actual = try ciphertext(testing.allocator, "A");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "Remove spaces" {
    const expected: []const u8 = "b";
    const actual = try ciphertext(testing.allocator, "  b ");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "Remove punctuation" {
    const expected: []const u8 = "1";
    const actual = try ciphertext(testing.allocator, "@1,%!");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "9 character plaintext results in 3 chunks of 3 characters" {
    const expected: []const u8 = "tsf hiu isn";
    const actual = try ciphertext(testing.allocator, "This is fun!");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "8 character plaintext results in 3 chunks, the last one with a trailing space" {
    const expected: []const u8 = "clu hlt io ";
    const actual = try ciphertext(testing.allocator, "Chill out.");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}

test "54 character plaintext results in 8 chunks, the last two with trailing spaces" {
    const expected: []const u8 = "imtgdvs fearwer mayoogo anouuio ntnnlvt wttddes aohghn  sseoau ";
    const actual = try ciphertext(testing.allocator, "If man was meant to stay on the ground, god would have given us roots.");
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings(expected, actual);
}
