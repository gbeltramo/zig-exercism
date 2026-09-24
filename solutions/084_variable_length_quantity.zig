const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const DecodeError = error{
    IncompleteSequence,
};

pub fn encode(allocator: mem.Allocator, integers: []const u32) mem.Allocator.Error![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    for (integers) |value| {
        var bytes: std.ArrayList(u8) = .empty;
        defer bytes.deinit(allocator);
        var bits: std.ArrayList(bool) = .empty;
        defer bits.deinit(allocator);

        if (value == 0) {
            try bytes.append(allocator, 0);
        } else {
            var current_value = value;
            while (current_value > 0) : (current_value = current_value >> 1) {
                try bits.append(allocator, (current_value & 1) == 1);
            }

            const num_chunks: usize = std.math.divCeil(usize, bits.items.len, 7) catch unreachable;
            for (0..num_chunks) |idx_chunk| {
                const idx_start: usize = 7 * idx_chunk;
                const idx_end: usize = @min(bits.items.len, 7 * idx_chunk + 7);
                const chunk = bits.items[idx_start..idx_end];

                var vl_integer: u8 = 0;
                for (chunk, 0..) |bit, i| {
                    vl_integer |= @as(u8, @intFromBool(bit)) << @intCast(i);
                }
                try bytes.append(allocator, vl_integer);
            }
            std.mem.reverse(u8, bytes.items);
        }

        for (0..bytes.items.len - 1) |idx| bytes.items[idx] |= 128;
        try out.appendSlice(allocator, bytes.items);
    }

    return out.toOwnedSlice(allocator);
}

pub fn decode(allocator: mem.Allocator, integers: []const u8) (mem.Allocator.Error || DecodeError)![]u32 {
    var out: std.ArrayList(u32) = .empty;
    errdefer out.deinit(allocator);

    var current_bits: std.ArrayList(bool) = .empty;
    defer current_bits.deinit(allocator);
    for (integers) |value| {
        // * 0 in bit-7 means "the end"
        const is_end_of_sequence = (value & 128) == 0;
        const powers_to_mask_bits = [7]u8{ 64, 32, 16, 8, 4, 2, 1 };
        for (powers_to_mask_bits) |mask| {
            try current_bits.append(allocator, (value & mask) != 0);
        }

        if (is_end_of_sequence) {
            // * This was the last u8 in a sequence of u8
            // * that corresponds to a single u32
            var out_value: u32 = 0;
            for (0..current_bits.items.len) |rev_idx| {
                const idx = current_bits.items.len - 1 - rev_idx;
                const bit = current_bits.items[idx];

                // * ERROR: more than 32 bits are needed to represent decoded sequence
                if (rev_idx >= 32) {
                    if (bit) return DecodeError.IncompleteSequence;
                } else {
                    const pow_of_two: u5 = @intCast(rev_idx);
                    out_value += (@as(u32, @intFromBool(bit)) << pow_of_two);
                }
            }
            try out.append(allocator, out_value);
            current_bits.clearRetainingCapacity();
        }
    }

    if (current_bits.items.len != 0) return DecodeError.IncompleteSequence;

    return out.toOwnedSlice(allocator);
}

fn testDecodeError(integers: []const u8) !void {
    const actual = decode(testing.allocator, integers);
    defer if (actual) |slice| testing.allocator.free(slice) else |_| {};
    try testing.expectError(DecodeError.IncompleteSequence, actual);
}

test "encode - zero" {
    const expected = [_]u8{0};
    const integers = [_]u32{0};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - arbitrary single byte" {
    const expected = [_]u8{64};
    const integers = [_]u32{64};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - asymmetric single byte" {
    const expected = [_]u8{83};
    const integers = [_]u32{83};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - largest single byte" {
    const expected = [_]u8{127};
    const integers = [_]u32{127};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - smallest double byte" {
    const expected = [_]u8{ 129, 0 };
    const integers = [_]u32{128};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - arbitrary double byte" {
    const expected = [_]u8{ 192, 0 };
    const integers = [_]u32{8_192};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - asymmetric double byte" {
    const expected = [_]u8{ 129, 45 };
    const integers = [_]u32{173};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - largest double byte" {
    const expected = [_]u8{ 255, 127 };
    const integers = [_]u32{16_383};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - smallest triple byte" {
    const expected = [_]u8{ 129, 128, 0 };
    const integers = [_]u32{16_384};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - arbitrary triple byte" {
    const expected = [_]u8{ 192, 128, 0 };
    const integers = [_]u32{1_048_576};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - asymmetric triple byte" {
    const expected = [_]u8{ 135, 171, 28 };
    const integers = [_]u32{120_220};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - largest triple byte" {
    const expected = [_]u8{ 255, 255, 127 };
    const integers = [_]u32{2_097_151};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - smallest quadruple byte" {
    const expected = [_]u8{ 129, 128, 128, 0 };
    const integers = [_]u32{2_097_152};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - arbitrary quadruple byte" {
    const expected = [_]u8{ 192, 128, 128, 0 };
    const integers = [_]u32{134_217_728};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - asymmetric quadruple byte" {
    const expected = [_]u8{ 129, 213, 238, 4 };
    const integers = [_]u32{3_503_876};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - largest quadruple byte" {
    const expected = [_]u8{ 255, 255, 255, 127 };
    const integers = [_]u32{268_435_455};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - smallest quintuple byte" {
    const expected = [_]u8{ 129, 128, 128, 128, 0 };
    const integers = [_]u32{268_435_456};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - arbitrary quintuple byte" {
    const expected = [_]u8{ 143, 248, 128, 128, 0 };
    const integers = [_]u32{4_278_190_080};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - asymmetric quintuple byte" {
    const expected = [_]u8{ 136, 179, 149, 194, 5 };
    const integers = [_]u32{2_254_790_917};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - maximum 32-bit integer input" {
    const expected = [_]u8{ 143, 255, 255, 255, 127 };
    const integers = [_]u32{4_294_967_295};
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - two single-byte values" {
    const expected = [_]u8{ 64, 127 };
    const integers = [_]u32{ 64, 127 };
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - two multi-byte values" {
    const expected = [_]u8{ 129, 128, 0, 200, 232, 86 };
    const integers = [_]u32{ 16_384, 1_193_046 };
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "encode - many multi-byte values" {
    const expected = [_]u8{ 192, 0, 200, 232, 86, 255, 255, 255, 127, 0, 255, 127, 129, 128, 0 };
    const integers = [_]u32{ 8_192, 1_193_046, 268_435_455, 0, 16_383, 16_384 };
    const actual = try encode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u8, &expected, actual);
}

test "decode - one byte" {
    const expected = [_]u32{127};
    const integers = [_]u8{127};
    const actual = try decode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u32, &expected, actual);
}

test "decode - two bytes" {
    const expected = [_]u32{8_192};
    const integers = [_]u8{ 192, 0 };
    const actual = try decode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u32, &expected, actual);
}

test "decode - three bytes" {
    const expected = [_]u32{2_097_151};
    const integers = [_]u8{ 255, 255, 127 };
    const actual = try decode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u32, &expected, actual);
}

test "decode - four bytes" {
    const expected = [_]u32{2_097_152};
    const integers = [_]u8{ 129, 128, 128, 0 };
    const actual = try decode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u32, &expected, actual);
}

test "decode - maximum 32-bit integer" {
    const expected = [_]u32{4_294_967_295};
    const integers = [_]u8{ 143, 255, 255, 255, 127 };
    const actual = try decode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u32, &expected, actual);
}

test "decode - incomplete sequence causes error" {
    const integers = [_]u8{255};
    try testDecodeError(&integers);
}

test "decode - incomplete sequence causes error, even if value is zero" {
    const integers = [_]u8{128};
    try testDecodeError(&integers);
}

test "decode - multiple values" {
    const expected = [_]u32{ 8_192, 1_193_046, 268_435_455, 0, 16_383, 16_384 };
    const integers = [_]u8{ 192, 0, 200, 232, 86, 255, 255, 255, 127, 0, 255, 127, 129, 128, 0 };
    const actual = try decode(testing.allocator, &integers);
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(u32, &expected, actual);
}
