const std = @import("std");
const testing = std.testing;

pub const TriangleError = error{Invalid};

pub const Triangle = struct {
    a: f64,
    b: f64,
    c: f64,

    pub fn init(a: f64, b: f64, c: f64) TriangleError!Triangle {
        if ((a + b < c) or (a + c < b) or (b + c < a) or (a == 0.0) or (b == 0.0) or (c == 0.0)) {
            return TriangleError.Invalid;
        }
        return Triangle{
            .a = a,
            .b = b,
            .c = c,
        };
    }

    pub fn isEquilateral(self: Triangle) bool {
        return (self.a == self.b) and (self.b == self.c);
    }

    pub fn isIsosceles(self: Triangle) bool {
        return (self.a == self.b) or (self.b == self.c) or (self.a == self.c);
    }

    pub fn isScalene(self: Triangle) bool {
        return (self.a != self.b) and (self.b != self.c) and (self.a != self.c);
    }
};

fn makeTriangle(a: f64, b: f64, c: f64) TriangleError!Triangle {
    return Triangle.init(a, b, c);
}

test "equilateral all sides are equal" {
    const actual = try makeTriangle(2, 2, 2);

    try testing.expect(actual.isEquilateral());
}

test "equilateral any side is unequal" {
    const actual = try makeTriangle(2, 3, 2);

    try testing.expect(!actual.isEquilateral());
}

test "equilateral no sides are equal" {
    const actual = try makeTriangle(5, 4, 6);

    try testing.expect(!actual.isEquilateral());
}

test "equilateral all zero sides is not a triangle" {
    try testing.expectError(TriangleError.Invalid, makeTriangle(0, 0, 0));
}

test "equilateral sides may be floats" {
    const actual = try makeTriangle(0.5, 0.5, 0.5);

    try testing.expect(actual.isEquilateral());
}

test "isosceles last two sides are equal" {
    const actual = try makeTriangle(3, 4, 4);

    try testing.expect(actual.isIsosceles());
}

test "isosceles first two sides are equal" {
    const actual = try makeTriangle(4, 4, 3);

    try testing.expect(actual.isIsosceles());
}

test "isosceles first and last sides are equal" {
    const actual = try makeTriangle(4, 3, 4);

    try testing.expect(actual.isIsosceles());
}

test "equilateral triangles are also isosceles" {
    const actual = try makeTriangle(4, 4, 4);

    try testing.expect(actual.isIsosceles());
}

test "isosceles no sides are equal" {
    const actual = try makeTriangle(2, 3, 4);

    try testing.expect(!actual.isIsosceles());
}

test "isosceles first triangle inequality violation" {
    try testing.expectError(TriangleError.Invalid, makeTriangle(1, 1, 3));
}

test "isosceles second triangle inequality violation" {
    try testing.expectError(TriangleError.Invalid, makeTriangle(1, 3, 1));
}

test "isosceles third triangle inequality violation" {
    try testing.expectError(TriangleError.Invalid, makeTriangle(3, 1, 1));
}

test "isosceles sides may be floats" {
    const actual = try makeTriangle(0.5, 0.4, 0.5);

    try testing.expect(actual.isIsosceles());
}

test "scalene no sides are equal" {
    const actual = try makeTriangle(5, 4, 6);

    try testing.expect(actual.isScalene());
}

test "scalene all sides are equal" {
    const actual = try makeTriangle(4, 4, 4);

    try testing.expect(!actual.isScalene());
}

test "scalene first and second sides are equal" {
    const actual = try makeTriangle(4, 4, 3);

    try testing.expect(!actual.isScalene());
}

test "scalene first and third sides are equal" {
    const actual = try makeTriangle(3, 4, 3);

    try testing.expect(!actual.isScalene());
}

test "scalene second and third sides are equal" {
    const actual = try makeTriangle(4, 3, 3);

    try testing.expect(!actual.isScalene());
}

test "scalene may not violate triangle inequality" {
    try testing.expectError(TriangleError.Invalid, makeTriangle(7, 3, 2));
}

test "scalene sides may be floats" {
    const actual = try makeTriangle(0.5, 0.4, 0.6);

    try testing.expect(actual.isScalene());
}
