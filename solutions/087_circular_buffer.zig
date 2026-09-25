const std = @import("std");
const testing = std.testing;

pub const BufferError = error{BufferOverflow};

pub fn CircularBuffer(comptime T: type, comptime capacity: usize) type {
    return struct {
        data: [capacity]T,
        idx_left: usize,
        idx_right: usize,

        const Self = @This();

        /// Initializes a CircularBuffer
        pub fn init() Self {
            var data: [capacity]T = undefined;
            std.crypto.secureZero(T, &data);
            return .{ .data = data, .idx_left = 0, .idx_right = 0 };
        }

        /// Discards all items in the buffer.
        pub fn clear(self: *Self) void {
            std.crypto.secureZero(T, &self.data);
            self.idx_left = 0;
            self.idx_right = 0;
        }

        /// Extracts the oldest item from the buffer.
        pub fn read(self: *Self) ?T {
            if (self.idx_left == self.idx_right) return null;

            const idx = self.idx_left % capacity;
            const out = self.data[idx];
            self.data[idx] = 0;
            self.idx_left = (self.idx_left + 1) % (2 * capacity);

            return out;
        }

        /// Write `item` into the buffer.
        pub fn write(self: *Self, item: T) BufferError!void {
            if ((self.idx_right - self.idx_left) >= capacity) return BufferError.BufferOverflow;

            const idx = self.idx_right % capacity;
            self.data[idx] = item;
            self.idx_right = (self.idx_right + 1) % (2 * capacity);
        }

        /// Write `item` into the buffer, replacing the oldest item if necessary.
        pub fn overwrite(self: *Self, item: T) void {
            const idx = self.idx_right % capacity;
            self.data[idx] = item;

            if ((self.idx_right - self.idx_left) >= capacity) {
                self.idx_left = (self.idx_left + 1) % (2 * capacity);
            }
            self.idx_right = (self.idx_right + 1) % (2 * capacity);
        }
    };
}

test "reading empty buffer should fail" {
    var cb = CircularBuffer(i16, 1).init();
    try testing.expectEqual(null, cb.read());
}

test "can read an item just written" {
    var cb = CircularBuffer(i16, 1).init();
    try cb.write(1);
    try testing.expectEqual(1, cb.read());
}

test "each item may only be read once" {
    var cb = CircularBuffer(i16, 1).init();
    try cb.write(1);
    try testing.expectEqual(1, cb.read());
    try testing.expectEqual(null, cb.read());
}

test "items are read in the order they are written" {
    var cb = CircularBuffer(i16, 2).init();
    try cb.write(1);
    try cb.write(2);
    try testing.expectEqual(1, cb.read());
    try testing.expectEqual(2, cb.read());
}

test "full buffer can't be written to" {
    var cb = CircularBuffer(i16, 1).init();
    try cb.write(1);
    try testing.expectError(BufferError.BufferOverflow, cb.write(2));
}

test "a read frees up capacity for another write" {
    var cb = CircularBuffer(i16, 1).init();
    try cb.write(1);
    try testing.expectEqual(1, cb.read());
    try cb.write(2);
    try testing.expectEqual(2, cb.read());
}

test "read position is maintained even across multiple writes" {
    var cb = CircularBuffer(i16, 3).init();
    try cb.write(1);
    try cb.write(2);
    try testing.expectEqual(1, cb.read());
    try cb.write(3);
    try testing.expectEqual(2, cb.read());
    try testing.expectEqual(3, cb.read());
}

test "items cleared out of buffer can't be read" {
    var cb = CircularBuffer(i16, 1).init();
    try cb.write(1);
    cb.clear();
    try testing.expectEqual(null, cb.read());
}

test "clear frees up capacity for another write" {
    var cb = CircularBuffer(i16, 1).init();
    try cb.write(1);
    cb.clear();
    try cb.write(2);
    try testing.expectEqual(2, cb.read());
}

test "clear does nothing on empty buffer" {
    var cb = CircularBuffer(i16, 1).init();
    cb.clear();
    try cb.write(1);
    try testing.expectEqual(1, cb.read());
}

test "overwrite acts like write on non-full buffer" {
    var cb = CircularBuffer(i16, 2).init();
    try cb.write(1);
    cb.overwrite(2);
    try testing.expectEqual(1, cb.read());
    try testing.expectEqual(2, cb.read());
}

test "overwrite replaces the oldest item on full buffer" {
    var cb = CircularBuffer(i16, 2).init();
    try cb.write(1);
    try cb.write(2);
    cb.overwrite(3);
    try testing.expectEqual(2, cb.read());
    try testing.expectEqual(3, cb.read());
}

test "overwrite replaces the oldest item remaining in buffer following a read" {
    var cb = CircularBuffer(i16, 3).init();
    try cb.write(1);
    try cb.write(2);
    try cb.write(3);
    try testing.expectEqual(1, cb.read());
    try cb.write(4);
    cb.overwrite(5);
    try testing.expectEqual(3, cb.read());
    try testing.expectEqual(4, cb.read());
    try testing.expectEqual(5, cb.read());
}

test "initial clear does not affect wrapping around" {
    var cb = CircularBuffer(i16, 2).init();
    cb.clear();
    try cb.write(1);
    try cb.write(2);
    cb.overwrite(3);
    cb.overwrite(4);
    try testing.expectEqual(3, cb.read());
    try testing.expectEqual(4, cb.read());
    try testing.expectEqual(null, cb.read());
}
