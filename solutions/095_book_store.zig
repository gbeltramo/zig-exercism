const std = @import("std");
const testing = std.testing;

const cost_one_book: u32 = 800;
const discounts = [6]u32{ 0, 0, 5, 10, 20, 25 };
const hard_coded_max_groups_to_prune_search: usize = 30;

/// Pick the n titles with the most copies remaining.
pub fn isGroupN(counter: [6]u8, n: usize) ?[6]bool {
    std.debug.assert(n >= 1);
    std.debug.assert(n < 6);

    var list = [6]bool{ false, false, false, false, false, false };

    var picked: usize = 0;
    while (picked < n) : (picked += 1) {
        var best_idx: usize = 0;
        var best_count: u8 = 0;
        for (1..6) |idx| {
            if (!list[idx] and counter[idx] > best_count) {
                best_count = counter[idx];
                best_idx = idx;
            }
        }
        if (best_idx == 0) return null;
        list[best_idx] = true;
    }
    return list;
}

pub fn recursiveTotal(counter: [6]u8, n: usize) u32 {
    if (n == 0) {
        return 0;
    }

    var sum_counter: u32 = 0;
    for (1..6) |idx| sum_counter += counter[idx];
    if (sum_counter == 0) return 0;

    if (n == 1) return sum_counter * cost_one_book;

    var best_cost: u32 = std.math.maxInt(u32);
    const group_cost: u32 = (cost_one_book * @as(u32, @intCast(n))) * (100 - discounts[n]) / 100;

    var max_num_groups: usize = 0;
    outer_loop: while (max_num_groups <= hard_coded_max_groups_to_prune_search) : (max_num_groups += 1) {
        var new_counter = counter;
        var new_cost: u32 = 0;
        var num_groups: usize = 0;

        while (num_groups < max_num_groups) {
            const group = isGroupN(new_counter, n) orelse break;
            for (group, 0..) |flag, idx| {
                if (flag) new_counter[idx] -= 1;
            }
            new_cost += group_cost;
            num_groups += 1;
        }
        new_cost += recursiveTotal(new_counter, n - 1);
        if (new_cost < best_cost) best_cost = new_cost;
        if (num_groups < max_num_groups) break :outer_loop;
    }

    return best_cost;
}

pub fn total(basket: []const u32) u32 {
    var counter: [6]u8 = @splat(0);
    for (basket) |val| counter[val] += 1;
    return recursiveTotal(counter, 5);
}

test "Only a single book" {
    const basket = &[_]u32{1};
    try testing.expectEqual(800, total(basket));
}

test "Two of the same book" {
    const basket = &[_]u32{ 2, 2 };
    try testing.expectEqual(1600, total(basket));
}

test "Empty basket" {
    const basket = &[_]u32{};
    try testing.expectEqual(0, total(basket));
}

test "Two different books" {
    const basket = &[_]u32{ 1, 2 };
    try testing.expectEqual(1520, total(basket));
}

test "Three different books" {
    const basket = &[_]u32{ 1, 2, 3 };
    try testing.expectEqual(2160, total(basket));
}

test "Four different books" {
    const basket = &[_]u32{ 1, 2, 3, 4 };
    try testing.expectEqual(2560, total(basket));
}

test "Five different books" {
    const basket = &[_]u32{ 1, 2, 3, 4, 5 };
    try testing.expectEqual(3000, total(basket));
}

test "Two groups of four is cheaper than group of five plus group of three" {
    const basket = &[_]u32{ 1, 1, 2, 2, 3, 3, 4, 5 };
    try testing.expectEqual(5120, total(basket));
}

test "Two groups of four is cheaper than groups of five and three" {
    const basket = &[_]u32{ 1, 1, 2, 3, 4, 4, 5, 5 };
    try testing.expectEqual(5120, total(basket));
}

test "Group of four plus group of two is cheaper than two groups of three" {
    const basket = &[_]u32{ 1, 1, 2, 2, 3, 4 };
    try testing.expectEqual(4080, total(basket));
}

test "Two each of first four books and one copy each of rest" {
    const basket = &[_]u32{ 1, 1, 2, 2, 3, 3, 4, 4, 5 };
    try testing.expectEqual(5560, total(basket));
}

test "Two copies of each book" {
    const basket = &[_]u32{ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5 };
    try testing.expectEqual(6000, total(basket));
}

test "Three copies of first book and two each of remaining" {
    const basket = &[_]u32{ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 1 };
    try testing.expectEqual(6800, total(basket));
}

test "Three each of first two books and two each of remaining books" {
    const basket = &[_]u32{ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 1, 2 };
    try testing.expectEqual(7520, total(basket));
}

test "Four groups of four are cheaper than two groups each of five and three" {
    const basket = &[_]u32{ 1, 1, 2, 2, 3, 3, 4, 5, 1, 1, 2, 2, 3, 3, 4, 5 };
    try testing.expectEqual(10240, total(basket));
}

test "Check that groups of four are created properly even when there are more groups of three than groups of five" {
    const basket = &[_]u32{ 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 5, 5 };
    try testing.expectEqual(14560, total(basket));
}

test "One group of one and four is cheaper than one group of two and three" {
    const basket = &[_]u32{ 1, 1, 2, 3, 4 };
    try testing.expectEqual(3360, total(basket));
}

test "One group of one and two plus three groups of four is cheaper than one group of each size" {
    const basket = &[_]u32{ 1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5 };
    try testing.expectEqual(10000, total(basket));
}
