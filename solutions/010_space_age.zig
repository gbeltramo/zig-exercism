const std = @import("std");
const testing = std.testing;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;

const seconds_in_one_earth_year: f64 = 31_557_600.0;

pub const Planet = enum {
    mercury,
    venus,
    earth,
    mars,
    jupiter,
    saturn,
    uranus,
    neptune,

    pub fn age(self: Planet, seconds: usize) f64 {
        const float_seconds: f64 = @floatFromInt(seconds);
        return switch (self) {
            Planet.mercury => float_seconds / seconds_in_one_earth_year / 0.2408467,
            Planet.venus => float_seconds / seconds_in_one_earth_year / 0.61519726,
            Planet.earth => float_seconds / seconds_in_one_earth_year,
            Planet.mars => float_seconds / seconds_in_one_earth_year / 1.8808158,
            Planet.jupiter => float_seconds / seconds_in_one_earth_year / 11.862615,
            Planet.saturn => float_seconds / seconds_in_one_earth_year / 29.447498,
            Planet.uranus => float_seconds / seconds_in_one_earth_year / 84.016846,
            Planet.neptune => float_seconds / seconds_in_one_earth_year / 164.79132,
        };
    }
};

fn testAge(planet: Planet, seconds: usize, expected_age_in_earth_years: f64) !void {
    const tolerance = 0.01;

    const actual = planet.age(seconds);

    try expectApproxEqAbs(expected_age_in_earth_years, actual, tolerance);
}

test "age on earth" {
    try testAge(Planet.earth, 1_000_000_000, 31.69);
}

test "age on mercury" {
    try testAge(Planet.mercury, 2_134_835_688, 280.88);
}

test "age on venus" {
    try testAge(Planet.venus, 189_839_836, 9.78);
}

test "age on mars" {
    try testAge(Planet.mars, 2_129_871_239, 35.88);
}

test "age on jupiter" {
    try testAge(Planet.jupiter, 901_876_382, 2.41);
}

test "age on saturn" {
    try testAge(Planet.saturn, 2_000_000_000, 2.15);
}

test "age on uranus" {
    try testAge(Planet.uranus, 1_210_123_456, 0.46);
}

test "age on neptune" {
    try testAge(Planet.neptune, 1_821_023_456, 0.35);
}
