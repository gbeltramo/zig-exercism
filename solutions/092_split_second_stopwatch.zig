const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const StopwatchError = error{
    AlreadyRunning,
    NotRunning,
    NotStopped,
};

pub const StopwatchState = enum {
    ready,
    running,
    stopped,
};

pub fn intToTime(total_seconds: u64) [8]u8 {
    var time = [8]u8{ '0', '0', ':', '0', '0', ':', '0', '0' };
    const seconds = total_seconds % 60;
    const minutes = total_seconds / 60 % 60;
    const hours = total_seconds / 3_600;

    _ = std.fmt.bufPrint(time[0..2], "{d:0>2}", .{hours}) catch unreachable;
    _ = std.fmt.bufPrint(time[3..5], "{d:0>2}", .{minutes}) catch unreachable;
    _ = std.fmt.bufPrint(time[6..8], "{d:0>2}", .{seconds}) catch unreachable;

    return time;
}

pub fn timeToInt(time: [8]u8) u64 {
    const seconds: u64 = @as(u64, time[6] - '0') * 10 + @as(u64, time[7] - '0');
    const minutes: u64 = @as(u64, time[3] - '0') * 10 + @as(u64, time[4] - '0');
    const hours: u64 = @as(u64, time[0] - '0') * 10 + @as(u64, time[1] - '0');

    return hours * 3600 + minutes * 60 + seconds;
}

pub const Stopwatch = struct {
    allocator: mem.Allocator,
    state: StopwatchState,
    prev_laps: std.ArrayList(u64),
    cur_lap: u64,

    pub fn init(allocator: mem.Allocator) Stopwatch {
        const prev_laps: std.ArrayList(u64) = .empty;
        return .{
            .allocator = allocator,
            .state = .ready,
            .prev_laps = prev_laps,
            .cur_lap = 0,
        };
    }

    pub fn deinit(self: *Stopwatch) void {
        self.prev_laps.deinit(self.allocator);
    }

    pub fn currentLap(self: *Stopwatch) [8]u8 {
        return intToTime(self.cur_lap);
    }

    pub fn previousLaps(self: *Stopwatch) mem.Allocator.Error![][8]u8 {
        const out = try self.allocator.alloc([8]u8, self.prev_laps.items.len);

        for (self.prev_laps.items, 0..) |prev_lap, idx| {
            out[idx] = intToTime(prev_lap);
        }

        return out;
    }

    pub fn total(self: *Stopwatch) [8]u8 {
        var total_laps: u64 = 0;
        for (self.prev_laps.items) |prev_lap| {
            total_laps += prev_lap;
        }
        total_laps += self.cur_lap;
        return intToTime(total_laps);
    }

    pub fn start(self: *Stopwatch) StopwatchError!void {
        if (self.state == .running) return StopwatchError.AlreadyRunning;
        self.state = .running;
    }

    pub fn stop(self: *Stopwatch) StopwatchError!void {
        if (self.state != .running) return StopwatchError.NotRunning;
        self.state = .stopped;
    }

    pub fn reset(self: *Stopwatch) StopwatchError!void {
        if (self.state != .stopped) return StopwatchError.NotStopped;
        self.prev_laps.clearRetainingCapacity();
        self.cur_lap = 0;
        self.state = .ready;
    }

    pub fn advanceTime(self: *Stopwatch, by: []const u8) !void {
        if (self.state != .running) return;
        self.cur_lap += timeToInt(by[0..8].*);
    }

    pub fn lap(self: *Stopwatch) (mem.Allocator.Error || StopwatchError)!void {
        if (self.state != .running) return StopwatchError.NotRunning;
        try self.prev_laps.append(self.allocator, self.cur_lap);
        self.cur_lap = 0;
    }
};

test "new stopwatch starts in ready state" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try testing.expectEqual(.ready, stopwatch.state);
}

test "new stopwatch's current lap has no elapsed time" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try testing.expectEqualStrings("00:00:00", &stopwatch.currentLap());
}

test "new stopwatch's total has no elapsed time" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try testing.expectEqualStrings("00:00:00", &stopwatch.total());
}

test "new stopwatch does not have previous laps" {
    var previous: [][8]u8 = undefined;
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(0, previous.len);
    testing.allocator.free(previous);
}

test "start from ready state changes state to running" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try testing.expectEqual(.running, stopwatch.state);
}

test "start does not change previous laps" {
    var previous: [][8]u8 = undefined;
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(0, previous.len);
    testing.allocator.free(previous);
}

test "start initiates time tracking for current lap" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:05");
    try testing.expectEqualStrings("00:00:05", &stopwatch.currentLap());
}

test "start initiates time tracking for total" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:23");
    try testing.expectEqualStrings("00:00:23", &stopwatch.total());
}

test "start cannot be called from running state" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try testing.expectError(StopwatchError.AlreadyRunning, stopwatch.start());
}

test "stop from running state changes state to stopped" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.stop();
    try testing.expectEqual(.stopped, stopwatch.state);
}

test "stop pauses time tracking for current lap" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:05");
    try stopwatch.stop();
    try stopwatch.advanceTime("00:00:08");
    try testing.expectEqualStrings("00:00:05", &stopwatch.currentLap());
}

test "stop pauses time tracking for total" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:13");
    try stopwatch.stop();
    try stopwatch.advanceTime("00:00:44");
    try testing.expectEqualStrings("00:00:13", &stopwatch.total());
}

test "stop cannot be called from ready state" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try testing.expectError(StopwatchError.NotRunning, stopwatch.stop());
}

test "stop cannot be called from stopped state" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.stop();
    try testing.expectError(StopwatchError.NotRunning, stopwatch.stop());
}

test "start from stopped state changes state to running" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.stop();
    try stopwatch.start();
    try testing.expectEqual(.running, stopwatch.state);
}

test "start from stopped state resumes time tracking for current lap" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:01:20");
    try stopwatch.stop();
    try stopwatch.advanceTime("00:00:20");
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:08");
    try testing.expectEqualStrings("00:01:28", &stopwatch.currentLap());
}

test "start from stopped state resumes time tracking for total" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:23");
    try stopwatch.stop();
    try stopwatch.advanceTime("00:00:44");
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:09");
    try testing.expectEqualStrings("00:00:32", &stopwatch.total());
}

test "lap adds current lap to previous laps" {
    var previous: [][8]u8 = undefined;
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:01:38");
    try stopwatch.lap();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(1, previous.len);
    try testing.expectEqualStrings("00:01:38", &previous[0]);
    testing.allocator.free(previous);
    try stopwatch.advanceTime("00:00:44");
    try stopwatch.lap();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(2, previous.len);
    try testing.expectEqualStrings("00:01:38", &previous[0]);
    try testing.expectEqualStrings("00:00:44", &previous[1]);
    testing.allocator.free(previous);
}

test "lap resets current lap and resumes time tracking" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:08:22");
    try stopwatch.lap();
    try testing.expectEqualStrings("00:00:00", &stopwatch.currentLap());
    try stopwatch.advanceTime("00:00:15");
    try testing.expectEqualStrings("00:00:15", &stopwatch.currentLap());
}

test "lap continues time tracking for total" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:22");
    try stopwatch.lap();
    try stopwatch.advanceTime("00:00:33");
    try testing.expectEqualStrings("00:00:55", &stopwatch.total());
}

test "lap cannot be called from ready state" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try testing.expectError(StopwatchError.NotRunning, stopwatch.lap());
}

test "lap cannot be called from stopped state" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.stop();
    try testing.expectError(StopwatchError.NotRunning, stopwatch.lap());
}

test "stop does not change previous laps" {
    var previous: [][8]u8 = undefined;
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:11:22");
    try stopwatch.lap();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(1, previous.len);
    try testing.expectEqualStrings("00:11:22", &previous[0]);
    testing.allocator.free(previous);
    try stopwatch.stop();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(1, previous.len);
    try testing.expectEqualStrings("00:11:22", &previous[0]);
    testing.allocator.free(previous);
}

test "reset from stopped state changes state to ready" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.stop();
    try stopwatch.reset();
    try testing.expectEqual(.ready, stopwatch.state);
}

test "reset resets current lap" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:10");
    try stopwatch.stop();
    try stopwatch.reset();
    try testing.expectEqualStrings("00:00:00", &stopwatch.currentLap());
}

test "reset clears previous laps" {
    var previous: [][8]u8 = undefined;
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("00:00:10");
    try stopwatch.lap();
    try stopwatch.advanceTime("00:00:20");
    try stopwatch.lap();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(2, previous.len);
    try testing.expectEqualStrings("00:00:10", &previous[0]);
    try testing.expectEqualStrings("00:00:20", &previous[1]);
    testing.allocator.free(previous);
    try stopwatch.stop();
    try stopwatch.reset();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(0, previous.len);
    testing.allocator.free(previous);
}

test "reset cannot be called from ready state" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try testing.expectError(StopwatchError.NotStopped, stopwatch.reset());
}

test "reset cannot be called from running state" {
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try testing.expectError(StopwatchError.NotStopped, stopwatch.reset());
}

test "supports very long laps" {
    var previous: [][8]u8 = undefined;
    var stopwatch = Stopwatch.init(testing.allocator);
    defer stopwatch.deinit();
    try stopwatch.start();
    try stopwatch.advanceTime("01:23:45");
    try testing.expectEqualStrings("01:23:45", &stopwatch.currentLap());
    try stopwatch.lap();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(1, previous.len);
    try testing.expectEqualStrings("01:23:45", &previous[0]);
    testing.allocator.free(previous);
    try stopwatch.advanceTime("04:01:40");
    try testing.expectEqualStrings("04:01:40", &stopwatch.currentLap());
    try testing.expectEqualStrings("05:25:25", &stopwatch.total());
    try stopwatch.lap();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(2, previous.len);
    try testing.expectEqualStrings("01:23:45", &previous[0]);
    try testing.expectEqualStrings("04:01:40", &previous[1]);
    testing.allocator.free(previous);
    try stopwatch.advanceTime("08:43:05");
    try testing.expectEqualStrings("08:43:05", &stopwatch.currentLap());
    try testing.expectEqualStrings("14:08:30", &stopwatch.total());
    try stopwatch.lap();
    previous = try stopwatch.previousLaps();
    try testing.expectEqual(3, previous.len);
    try testing.expectEqualStrings("01:23:45", &previous[0]);
    try testing.expectEqualStrings("04:01:40", &previous[1]);
    try testing.expectEqualStrings("08:43:05", &previous[2]);
    testing.allocator.free(previous);
}
