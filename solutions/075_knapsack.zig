const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const Item = struct {
    weight: usize = 0,
    value: usize = 0,
    pub fn init(weight: usize, value: usize) Item {
        return .{ .weight = weight, .value = value };
    }
};

const no_result = std.math.maxInt(usize);

pub fn maximumValue(allocator: mem.Allocator, maximumWeight: usize, items: []const Item) !usize {
    const idx_item_plus_one = items.len;
    // * memo[i][w] = cached result for "first i items, capacity w"
    // * Using maxInt(usize) as the "not computed yet" sentinel (no -1 for unsigned types).
    var memo = try allocator.alloc([]usize, idx_item_plus_one + 1);
    defer allocator.free(memo);
    for (memo, 0..) |_, i| {
        memo[i] = try allocator.alloc(usize, maximumWeight + 1);
        @memset(memo[i], no_result);
    }
    defer for (memo) |row| allocator.free(row);
    return knapsackRecursive(maximumWeight, items, idx_item_plus_one, memo);
}

pub fn knapsackRecursive(
    current_capacity: usize,
    items: []const Item,
    idx_item_plus_one: usize,
    memo: [][]usize,
) usize {
    if ((idx_item_plus_one == 0) or (current_capacity == 0)) return 0;
    if (memo[idx_item_plus_one][current_capacity] != no_result) {
        return memo[idx_item_plus_one][current_capacity];
    }
    var partial_sum_if_I_use_this_item: usize = 0;
    if (items[idx_item_plus_one - 1].weight <= current_capacity) {
        partial_sum_if_I_use_this_item = items[idx_item_plus_one - 1].value + knapsackRecursive(
            current_capacity - items[idx_item_plus_one - 1].weight,
            items,
            idx_item_plus_one - 1,
            memo,
        );
    }
    const partial_sum_if_I_do_not_use_this_item: usize = knapsackRecursive(
        current_capacity,
        items,
        idx_item_plus_one - 1,
        memo,
    );
    const result = @max(partial_sum_if_I_use_this_item, partial_sum_if_I_do_not_use_this_item);
    memo[idx_item_plus_one][current_capacity] = result;
    return result;
}

test "no items" {
    const expected: usize = 0;
    const items: [0]Item = .{};
    const actual = try maximumValue(testing.allocator, 100, &items);
    try testing.expectEqual(expected, actual);
}

test "one item, too heavy" {
    const expected: usize = 0;
    const items: [1]Item = .{
        Item.init(100, 1),
    };
    const actual = try maximumValue(testing.allocator, 10, &items);
    try testing.expectEqual(expected, actual);
}

test "five items (cannot be greedy by weight)" {
    const expected: usize = 21;
    const items: [5]Item = .{
        Item.init(2, 5),
        Item.init(2, 5),
        Item.init(2, 5),
        Item.init(2, 5),
        Item.init(10, 21),
    };
    const actual = try maximumValue(testing.allocator, 10, &items);
    try testing.expectEqual(expected, actual);
}

test "five items (cannot be greedy by value)" {
    const expected: usize = 80;
    const items: [5]Item = .{
        Item.init(2, 20),
        Item.init(2, 20),
        Item.init(2, 20),
        Item.init(2, 20),
        Item.init(10, 50),
    };
    const actual = try maximumValue(testing.allocator, 10, &items);
    try testing.expectEqual(expected, actual);
}

test "example knapsack" {
    const expected: usize = 90;
    const items: [4]Item = .{
        Item.init(5, 10),
        Item.init(4, 40),
        Item.init(6, 30),
        Item.init(4, 50),
    };
    const actual = try maximumValue(testing.allocator, 10, &items);
    try testing.expectEqual(expected, actual);
}

test "8 items" {
    const expected: usize = 900;
    const items: [8]Item = .{
        Item.init(25, 350),
        Item.init(35, 400),
        Item.init(45, 450),
        Item.init(5, 20),
        Item.init(25, 70),
        Item.init(3, 8),
        Item.init(2, 5),
        Item.init(2, 5),
    };
    const actual = try maximumValue(testing.allocator, 104, &items);
    try testing.expectEqual(expected, actual);
}

test "15 items" {
    const expected: usize = 1458;
    const items: [15]Item = .{
        Item.init(70, 135),
        Item.init(73, 139),
        Item.init(77, 149),
        Item.init(80, 150),
        Item.init(82, 156),
        Item.init(87, 163),
        Item.init(90, 173),
        Item.init(94, 184),
        Item.init(98, 192),
        Item.init(106, 201),
        Item.init(110, 210),
        Item.init(113, 214),
        Item.init(115, 221),
        Item.init(118, 229),
        Item.init(120, 240),
    };
    const actual = try maximumValue(testing.allocator, 750, &items);
    try testing.expectEqual(expected, actual);
}
