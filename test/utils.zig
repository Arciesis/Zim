const std = @import("std");
const zim = @import("../src/main.zig");
const cli = @import("zig-cli");

const testing = std.testing;

test "UsizeStr should return a valid []u8 representing the ascii of the number" {
    var allocator = std.testing.allocator;

    const val1: usize = 6;
    const res1 = try zim.usizeToStr(&allocator, val1);
    var expectedArray1 = [1]u8{'6'};
    const expectedSlice1 = expectedArray1[0..];

    try testing.expectEqualSlices(u8, expectedSlice1, res1);
}

test "usizeStr should return a valid []u8 for a number of 2 digit" {
    var allocator = std.testing.allocator;

    const val2: usize = 65;
    const res2 = try zim.usizeToStr(&allocator, val2);
    var exepctedArray2 = [2]u8{ '6', '5' };
    const expectedSlice2 = exepctedArray2[0..];

    try testing.expectEqualSlices(u8, expectedSlice2, res2);
}

test "usizeStr should return a valid []u8 of the desired number of digit" {
    var allocator = std.testing.allocator;

    const val3: usize = 87465984375;
    const res3 = try zim.usizeToStr(&allocator, val3);
    var expectedArray3 = [11]u8{ '8', '7', '4', '6', '5', '9', '8', '4', '3', '7', '5' };
    const expectedSlice3 = expectedArray3[0..];

    try testing.expectEqualSlices(u8, expectedSlice3, res3);
}

test "appendSliceBuf should concat 2 slices of different sizes into a third buffer" {
    var allocator = std.testing.allocator;

    var strArray: [7]u8 = [_]u8{ 'a', 's', 'd', 'f', 'g', 'h', 'j' };
    var appendixArray: [2]u8 = [_]u8{ 'k', 'l' };
    var expectedArray: [9]u8 = [_]u8{ 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l' };

    const str: []u8 = strArray[0..];
    const appendix: []u8 = appendixArray[0..];
    const expected: []u8 = expectedArray[0..];

    const concat = try zim.appendSliceBuf(&allocator, str, appendix);

    try testing.expect(concat.len == (str.len + appendix.len));
    try testing.expectEqualSlices(u8, concat, expected);
}

test "nbDigitInNbr should return the correct number" {
    const val1: usize = 7;
    const val2: usize = 100;
    const val3: usize = 765890324;

    const exp1: usize = 1;
    const exp2: usize = 3;
    const exp3: usize = 9;

    const res1: usize = zim.nbDigitInNbr(val1);
    const res2: usize = zim.nbDigitInNbr(val2);
    const res3: usize = zim.nbDigitInNbr(val3);

    try testing.expect(exp1 == res1);
    try testing.expect(exp2 == res2);
    try testing.expect(exp3 == res3);
}
