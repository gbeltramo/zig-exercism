const std = @import("std");
const testing = std.testing;

pub const BucketId = enum {
    one,
    two,
};

pub const Result = struct {
    moves: u64,
    goal_bucket: BucketId,
    other_bucket: u64,
};

pub fn measure(bucket_one: u64, bucket_two: u64, goal: u64, start_bucket: BucketId) ?Result {
    // Unreachable goal checks
    if (goal > bucket_one and goal > bucket_two) return null;
    if (goal % std.math.gcd(bucket_one, bucket_two) != 0) return null;

    // Initialize
    var num_moves: u64 = 0;
    var state = [2]u64{ 0, 0 };
    const capacity = [2]u64{ bucket_one, bucket_two };
    var idx_cur_bucket: usize = 0;
    switch (start_bucket) {
        .one => {
            state[0] = bucket_one;
            idx_cur_bucket = 0;
            num_moves += 1;
        },
        .two => {
            state[1] = bucket_two;
            idx_cur_bucket = 1;
            num_moves += 1;
        },
    }

    // Loop: fill idx_cur, fill 1-idx_cur, empty 1-idx_cur, or pour current into other
    while ((state[0] != goal) and (state[1] != goal)) {
        if (state[idx_cur_bucket] == 0) {
            // std.debug.print("({d}) empty to full\n", .{idx_cur_bucket});
            state[idx_cur_bucket] = capacity[idx_cur_bucket];
        } else if (capacity[1 - idx_cur_bucket] == goal) {
            // std.debug.print("({d}) to solution\n", .{1 - idx_cur_bucket});
            state[1 - idx_cur_bucket] = capacity[1 - idx_cur_bucket];
        } else if (state[1 - idx_cur_bucket] == capacity[1 - idx_cur_bucket]) {
            // std.debug.print("({d}) full to empty\n", .{1 - idx_cur_bucket});
            state[1 - idx_cur_bucket] = 0;
        } else {
            const quantity_can_puor = capacity[1 - idx_cur_bucket] - state[1 - idx_cur_bucket];
            const quantity_that_will_be_poured = @min(state[idx_cur_bucket], quantity_can_puor);
            state[idx_cur_bucket] -= quantity_that_will_be_poured;
            state[1 - idx_cur_bucket] += quantity_that_will_be_poured;
        }
        num_moves += 1;
    }

    // Build output
    var goal_bucket: BucketId = .one;
    var other = state[1];
    if (state[1] == goal) {
        goal_bucket = .two;
        other = state[0];
    }
    return Result{
        .moves = num_moves,
        .goal_bucket = goal_bucket,
        .other_bucket = other,
    };
}

test "Measure using bucket one of size 3 and bucket two of size 5 - start with bucket one" {
    if (measure(3, 5, 1, .one)) |result| {
        try testing.expectEqual(4, result.moves);
        try testing.expectEqual(.one, result.goal_bucket);
        try testing.expectEqual(5, result.other_bucket);
    } else {
        try testing.expect(false);
    }
}

test "Measure using bucket one of size 3 and bucket two of size 5 - start with bucket two" {
    if (measure(3, 5, 1, .two)) |result| {
        try testing.expectEqual(8, result.moves);
        try testing.expectEqual(.two, result.goal_bucket);
        try testing.expectEqual(3, result.other_bucket);
    } else {
        try testing.expect(false);
    }
}

test "Measure using bucket one of size 7 and bucket two of size 11 - start with bucket one" {
    if (measure(7, 11, 2, .one)) |result| {
        try testing.expectEqual(14, result.moves);
        try testing.expectEqual(.one, result.goal_bucket);
        try testing.expectEqual(11, result.other_bucket);
    } else {
        try testing.expect(false);
    }
}

test "Measure using bucket one of size 7 and bucket two of size 11 - start with bucket two" {
    if (measure(7, 11, 2, .two)) |result| {
        try testing.expectEqual(18, result.moves);
        try testing.expectEqual(.two, result.goal_bucket);
        try testing.expectEqual(7, result.other_bucket);
    } else {
        try testing.expect(false);
    }
}

test "Measure one step using bucket one of size 1 and bucket two of size 3 - start with bucket two" {
    if (measure(1, 3, 3, .two)) |result| {
        try testing.expectEqual(1, result.moves);
        try testing.expectEqual(.two, result.goal_bucket);
        try testing.expectEqual(0, result.other_bucket);
    } else {
        try testing.expect(false);
    }
}

test "Measure using bucket one of size 2 and bucket two of size 3 - start with bucket one and end with bucket two" {
    if (measure(2, 3, 3, .one)) |result| {
        try testing.expectEqual(2, result.moves);
        try testing.expectEqual(.two, result.goal_bucket);
        try testing.expectEqual(2, result.other_bucket);
    } else {
        try testing.expect(false);
    }
}

test "Measure using bucket one much bigger than bucket two" {
    if (measure(5, 1, 2, .one)) |result| {
        try testing.expectEqual(6, result.moves);
        try testing.expectEqual(.one, result.goal_bucket);
        try testing.expectEqual(1, result.other_bucket);
    } else {
        try testing.expect(false);
    }
}

test "Measure using bucket one much smaller than bucket two" {
    if (measure(3, 15, 9, .one)) |result| {
        try testing.expectEqual(6, result.moves);
        try testing.expectEqual(.two, result.goal_bucket);
        try testing.expectEqual(0, result.other_bucket);
    } else {
        try testing.expect(false);
    }
}

test "Not possible to reach the goal" {
    const result = measure(6, 15, 5, .one);
    try testing.expectEqual(result, null);
}

test "With the same buckets but a different goal, then it is possible" {
    if (measure(6, 15, 9, .one)) |result| {
        try testing.expectEqual(10, result.moves);
        try testing.expectEqual(.two, result.goal_bucket);
        try testing.expectEqual(0, result.other_bucket);
    } else {
        try testing.expect(false);
    }
}

test "Goal larger than both buckets is impossible" {
    const result = measure(5, 7, 8, .one);
    try testing.expectEqual(result, null);
}
