const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const ChangeError = error{
    NegativeTarget,
    UnreachableTarget,
};

const SliceContext = struct {
    pub fn hash(_: SliceContext, key: []const u64) u64 {
        var hasher = std.hash.Wyhash.init(0);
        for (key) |x| hasher.update(std.mem.asBytes(&x));
        return hasher.final();
    }
    pub fn eql(_: SliceContext, a: []const u64, b: []const u64) bool {
        return std.mem.eql(u64, a, b);
    }
};

const ComboMap = std.HashMap([]const u64, void, SliceContext, std.hash_map.default_max_load_percentage);

pub fn findFewestCoins(
    allocator: mem.Allocator,
    coins: []const u64,
    target: i64,
) (mem.Allocator.Error || ChangeError)![]u64 {
    if (target < 0) {
        return ChangeError.NegativeTarget;
    } else if (target == 0) {
        return try allocator.alloc(u64, 0);
    }

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const utarget: u64 = @intCast(target);

    // We use three different strategies to initialize the search
    //   1) if the utarget is one coin values, then return it directly
    //   2) if max(coins) < (utarget / 3), then only append max(coins) (utarget / max(coins) - 2) times. This is my heuristic
    //   3) else append all values in coins, and search all possible combinations

    // 1) trivial case
    for (coins) |c| {
        if (c == utarget) {
            const out = try allocator.alloc(u64, 1);
            out[0] = c;
            return out;
        }
    }

    var current = ComboMap.init(arena_allocator);
    const max_coin_value: u64 = std.mem.max(u64, coins);
    const mult = @divFloor(utarget, max_coin_value);
    if (mult > 2) { // 2) heuristic to prune search
        const length: usize = mult - 2;
        const combo = try arena_allocator.alloc(u64, length);
        @memset(combo, max_coin_value);
        try current.put(combo, {});
    } else { // 3) try all paths
        for (coins) |c| {
            if (c < utarget) {
                const combo = try arena_allocator.alloc(u64, 1);
                combo[0] = c;
                try current.put(combo, {});
            }
        }
    }

    const max_iter_while_loop: usize = 100;
    var count: usize = 0;
    while (current.count() > 0 and count < max_iter_while_loop) : (count += 1) {
        var next = ComboMap.init(arena_allocator);

        var it = current.keyIterator();
        while (it.next()) |combo_ptr| {
            const combo = combo_ptr.*;
            for (coins) |c| {
                var total: u64 = c;
                for (combo) |x| total += x;

                if (total == utarget) {
                    const out = try allocator.alloc(u64, combo.len + 1);
                    @memcpy(out[0..combo.len], combo);
                    out[combo.len] = c;
                    std.mem.sort(u64, out, {}, std.sort.asc(u64));
                    return out;
                } else if (total < utarget) {
                    const branch = try arena_allocator.alloc(u64, combo.len + 1);
                    @memcpy(branch[0..combo.len], combo);
                    branch[combo.len] = c;
                    std.mem.sort(u64, branch, {}, std.sort.asc(u64));
                    try next.put(branch, {});
                }
            }
        }

        current = next;
    }

    return ChangeError.UnreachableTarget;
}

test "change for 1 cent" {
    const expected = [_]u64{1};
    const coins = [_]u64{ 1, 5, 10, 25 };
    const actual = try findFewestCoins(testing.allocator, &coins, 1);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "single coin change" {
    const expected = [_]u64{25};
    const coins = [_]u64{ 1, 5, 10, 25, 100 };
    const actual = try findFewestCoins(testing.allocator, &coins, 25);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "multiple coin change" {
    const expected = [_]u64{ 5, 10 };
    const coins = [_]u64{ 1, 5, 10, 25, 100 };
    const actual = try findFewestCoins(testing.allocator, &coins, 15);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "change with Lilliputian Coins" {
    const expected = [_]u64{ 4, 4, 15 };
    const coins = [_]u64{ 1, 4, 15, 20, 50 };
    const actual = try findFewestCoins(testing.allocator, &coins, 23);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "change with Lower Elbonia Coins" {
    const expected = [_]u64{ 21, 21, 21 };
    const coins = [_]u64{ 1, 5, 10, 21, 25 };
    const actual = try findFewestCoins(testing.allocator, &coins, 63);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "large target values" {
    const expected = [_]u64{ 2, 2, 5, 20, 20, 50, 100, 100, 100, 100, 100, 100, 100, 100, 100 };
    const coins = [_]u64{ 1, 2, 5, 10, 20, 50, 100 };
    const actual = try findFewestCoins(testing.allocator, &coins, 999);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "possible change without unit coins available" {
    const expected = [_]u64{ 2, 2, 2, 5, 10 };
    const coins = [_]u64{ 2, 5, 10, 20, 50 };
    const actual = try findFewestCoins(testing.allocator, &coins, 21);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "another possible change without unit coins available" {
    const expected = [_]u64{ 4, 4, 4, 5, 5, 5 };
    const coins = [_]u64{ 4, 5 };
    const actual = try findFewestCoins(testing.allocator, &coins, 27);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "a greedy approach is not optimal" {
    const expected = [_]u64{ 10, 10 };
    const coins = [_]u64{ 1, 10, 11 };
    const actual = try findFewestCoins(testing.allocator, &coins, 20);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "no coins make 0 change" {
    const expected = [_]u64{};
    const coins = [_]u64{ 1, 5, 10, 21, 25 };
    const actual = try findFewestCoins(testing.allocator, &coins, 0);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u64, &expected, actual);
}

test "error testing for change smaller than the smallest of coins" {
    const coins = [_]u64{ 5, 10 };
    const actual = findFewestCoins(testing.allocator, &coins, 3);
    try testing.expectError(ChangeError.UnreachableTarget, actual);
}

test "error if no combination can add up to target" {
    const coins = [_]u64{ 5, 10 };
    const actual = findFewestCoins(testing.allocator, &coins, 94);
    try testing.expectError(ChangeError.UnreachableTarget, actual);
}

test "cannot find negative change values" {
    const coins = [_]u64{ 1, 2, 5 };
    const actual = findFewestCoins(testing.allocator, &coins, -5);
    try testing.expectError(ChangeError.NegativeTarget, actual);
}
