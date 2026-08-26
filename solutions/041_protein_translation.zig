const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const TranslationError = error{
    InvalidCodon,
};

pub const Protein = enum {
    methionine,
    phenylalanine,
    leucine,
    serine,
    tyrosine,
    cysteine,
    tryptophan,
};

pub fn proteins(allocator: mem.Allocator, strand: []const u8) (mem.Allocator.Error || TranslationError)![]Protein {
    var found_proteins: []Protein = try allocator.alloc(Protein, @divFloor(strand.len, 3) + 1);
    defer allocator.free(found_proteins);
    var current_codon: [3]u8 = .{ 'Z', 'Z', 'Z' };

    var idx_i: usize = 0;
    var idx_j: usize = 0;
    loop_strand: for (strand) |c| {
        current_codon[idx_j] = c;
        idx_j += 1;

        // NOTE When idx_j == 3 here, we can map the codon to the amino acid
        if (idx_j == 3) {
            var amino_acid = Protein.methionine;
            if (std.mem.eql(u8, &current_codon, "AUG")) {
                amino_acid = Protein.methionine;
            } else if (std.mem.eql(u8, &current_codon, "UUU") or std.mem.eql(u8, &current_codon, "UUC")) {
                amino_acid = Protein.phenylalanine;
            } else if (std.mem.eql(u8, &current_codon, "UUA") or std.mem.eql(u8, &current_codon, "UUG")) {
                amino_acid = Protein.leucine;
            } else if (std.mem.eql(u8, &current_codon, "UCU") or std.mem.eql(u8, &current_codon, "UCC") or std.mem.eql(u8, &current_codon, "UCA") or std.mem.eql(u8, &current_codon, "UCG")) {
                amino_acid = Protein.serine;
            } else if (std.mem.eql(u8, &current_codon, "UAU") or std.mem.eql(u8, &current_codon, "UAC")) {
                amino_acid = Protein.tyrosine;
            } else if (std.mem.eql(u8, &current_codon, "UGU") or std.mem.eql(u8, &current_codon, "UGC")) {
                amino_acid = Protein.cysteine;
            } else if (std.mem.eql(u8, &current_codon, "UGG")) {
                amino_acid = Protein.tryptophan;
            } else if (std.mem.eql(u8, &current_codon, "UAA") or std.mem.eql(u8, &current_codon, "UAG") or std.mem.eql(u8, &current_codon, "UGA")) {
                // STOP
                break :loop_strand;
            } else {
                // NOTE three letters do not make a codon
                return TranslationError.InvalidCodon;
            }
            found_proteins[idx_i] = amino_acid;

            // NOTE Re-init
            idx_j = idx_j % 3;
            current_codon[0] = 'Z';
            current_codon[1] = 'Z';
            current_codon[2] = 'Z';
            if (idx_j == 0) {
                idx_i += 1;
            }
        }
    }

    if ((idx_j % 3) != 0) {
        // NOTE incomplete codon at the end of `loop_strand`
        return TranslationError.InvalidCodon;
    }

    const out = try allocator.alloc(Protein, idx_i);
    @memcpy(out, found_proteins[0..idx_i]);
    return out;
}

test "Empty RNA sequence results in no proteins" {
    const expected = [_]Protein{};
    const actual = try proteins(testing.allocator, "");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Methionine RNA sequence" {
    const expected = [_]Protein{.methionine};
    const actual = try proteins(testing.allocator, "AUG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Phenylalanine RNA sequence 1" {
    const expected = [_]Protein{.phenylalanine};
    const actual = try proteins(testing.allocator, "UUU");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Phenylalanine RNA sequence 2" {
    const expected = [_]Protein{.phenylalanine};
    const actual = try proteins(testing.allocator, "UUC");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Leucine RNA sequence 1" {
    const expected = [_]Protein{.leucine};
    const actual = try proteins(testing.allocator, "UUA");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Leucine RNA sequence 2" {
    const expected = [_]Protein{.leucine};
    const actual = try proteins(testing.allocator, "UUG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Serine RNA sequence 1" {
    const expected = [_]Protein{.serine};
    const actual = try proteins(testing.allocator, "UCU");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Serine RNA sequence 2" {
    const expected = [_]Protein{.serine};
    const actual = try proteins(testing.allocator, "UCC");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Serine RNA sequence 3" {
    const expected = [_]Protein{.serine};
    const actual = try proteins(testing.allocator, "UCA");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Serine RNA sequence 4" {
    const expected = [_]Protein{.serine};
    const actual = try proteins(testing.allocator, "UCG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Tyrosine RNA sequence 1" {
    const expected = [_]Protein{.tyrosine};
    const actual = try proteins(testing.allocator, "UAU");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Tyrosine RNA sequence 2" {
    const expected = [_]Protein{.tyrosine};
    const actual = try proteins(testing.allocator, "UAC");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Cysteine RNA sequence 1" {
    const expected = [_]Protein{.cysteine};
    const actual = try proteins(testing.allocator, "UGU");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Cysteine RNA sequence 2" {
    const expected = [_]Protein{.cysteine};
    const actual = try proteins(testing.allocator, "UGC");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Tryptophan RNA sequence" {
    const expected = [_]Protein{.tryptophan};
    const actual = try proteins(testing.allocator, "UGG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "STOP codon RNA sequence 1" {
    const expected = [_]Protein{};
    const actual = try proteins(testing.allocator, "UAA");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "STOP codon RNA sequence 2" {
    const expected = [_]Protein{};
    const actual = try proteins(testing.allocator, "UAG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "STOP codon RNA sequence 3" {
    const expected = [_]Protein{};
    const actual = try proteins(testing.allocator, "UGA");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Sequence of two protein codons translates into proteins" {
    const expected = [_]Protein{ .phenylalanine, .phenylalanine };
    const actual = try proteins(testing.allocator, "UUUUUU");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Sequence of two different protein codons translates into proteins" {
    const expected = [_]Protein{ .leucine, .leucine };
    const actual = try proteins(testing.allocator, "UUAUUG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Translate RNA strand into correct protein list" {
    const expected = [_]Protein{ .methionine, .phenylalanine, .tryptophan };
    const actual = try proteins(testing.allocator, "AUGUUUUGG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Translation stops if STOP codon at beginning of sequence" {
    const expected = [_]Protein{};
    const actual = try proteins(testing.allocator, "UAGUGG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Translation stops if STOP codon at end of two-codon sequence" {
    const expected = [_]Protein{.tryptophan};
    const actual = try proteins(testing.allocator, "UGGUAG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Translation stops if STOP codon at end of three-codon sequence" {
    const expected = [_]Protein{ .methionine, .phenylalanine };
    const actual = try proteins(testing.allocator, "AUGUUUUAA");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Translation stops if STOP codon in middle of three-codon sequence" {
    const expected = [_]Protein{.tryptophan};
    const actual = try proteins(testing.allocator, "UGGUAGUGG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Translation stops if STOP codon in middle of six-codon sequence" {
    const expected = [_]Protein{ .tryptophan, .cysteine, .tyrosine };
    const actual = try proteins(testing.allocator, "UGGUGUUAUUAAUGGUUU");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Sequence of two non-STOP codons does not translate to a STOP codon" {
    const expected = [_]Protein{ .methionine, .methionine };
    const actual = try proteins(testing.allocator, "AUGAUG");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}

test "Unknown amino acids, not part of a codon, can't translate" {
    try testing.expectError(TranslationError.InvalidCodon, proteins(testing.allocator, "XYZ"));
}

test "Incomplete RNA sequence can't translate" {
    try testing.expectError(TranslationError.InvalidCodon, proteins(testing.allocator, "AUGU"));
}

test "Incomplete RNA sequence can translate if valid until a STOP codon" {
    const expected = [_]Protein{ .phenylalanine, .phenylalanine };
    const actual = try proteins(testing.allocator, "UUCUUCUAAUGGU");
    defer testing.allocator.free(actual);
    try testing.expectEqualSlices(Protein, &expected, actual);
}
