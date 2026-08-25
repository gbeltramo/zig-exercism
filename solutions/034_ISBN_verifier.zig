const std = @import("std");
const testing = std.testing;

pub fn isValidIsbn10(s: []const u8) bool {
    if (s.len < 10) {
        return false;
    }

    var digits: [10]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    var idx: usize = 0;
    for (s) |c| {
        if (idx >= 10) {
            return false;
        }

        if (c == '-') {
            continue;
        } else if (c == 'X') {
            if (idx == 9) {
                digits[9] = 10;
            } else {
                return false;
            }
        } else if (std.ascii.isDigit(c)) {
            digits[idx] = c - '0';
            idx += 1;
        } else {
            return false;
        }
    }

    var total: usize = 0;
    for (digits, 0..) |d, f| {
        total += (10 - f) * d;
    }

    return (total % 11) == 0;
}

test "valid ISBN" {
    try testing.expect(isValidIsbn10("3-598-21508-8"));
}

test "invalid ISBN check digit" {
    try testing.expect(!isValidIsbn10("3-598-21508-9"));
}

test "valid ISBN with a check digit of 10" {
    try testing.expect(isValidIsbn10("3-598-21507-X"));
}

test "check digit is a character other than X" {
    try testing.expect(!isValidIsbn10("3-598-21507-A"));
}

test "invalid check digit in ISBN is not treated as zero" {
    try testing.expect(!isValidIsbn10("4-598-21507-B"));
}

test "invalid character in ISBN is not treated as zero" {
    try testing.expect(!isValidIsbn10("3-598-P1581-X"));
}

test "X is only valid as a check digit" {
    try testing.expect(!isValidIsbn10("3-598-2X507-9"));
}

test "only one check digit is allowed" {
    try testing.expect(!isValidIsbn10("3-598-21508-96"));
}

test "X is not substituted by the value 10" {
    try testing.expect(!isValidIsbn10("3-598-2X507-5"));
}

test "valid ISBN without separating dashes" {
    try testing.expect(isValidIsbn10("3598215088"));
}

test "ISBN without separating dashes and X as check digit" {
    try testing.expect(isValidIsbn10("359821507X"));
}

test "ISBN without check digit and dashes" {
    try testing.expect(!isValidIsbn10("359821507"));
}

test "too long ISBN and no dashes" {
    try testing.expect(!isValidIsbn10("3598215078X"));
}

test "too short ISBN" {
    try testing.expect(!isValidIsbn10("00"));
}

test "ISBN without check digit" {
    try testing.expect(!isValidIsbn10("3-598-21507"));
}

test "check digit of X should not be used for 0" {
    try testing.expect(!isValidIsbn10("3-598-21515-X"));
}

test "empty ISBN" {
    try testing.expect(!isValidIsbn10(""));
}

test "input is 9 characters" {
    try testing.expect(!isValidIsbn10("134456729"));
}

test "invalid characters are not ignored after checking length" {
    try testing.expect(!isValidIsbn10("3132P34035"));
}

test "invalid characters are not ignored before checking length" {
    try testing.expect(!isValidIsbn10("3598P215088"));
}

test "input is too long but contains a valid ISBN" {
    try testing.expect(!isValidIsbn10("98245726788"));
}
