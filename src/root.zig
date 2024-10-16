const std = @import("std");
const cli = @import("zig-cli");
const zim = @import("main.zig");

const testing = std.testing;

// test "usizeToStr must return a valid digit for any usize" {
//     var allocator = std.testing.allocator;
//     const size: usize = 8;
//     const char: u8 = '8';
//     const slice = try zim.usizeToStr(&allocator, size);
//     try testing.expect(slice[0] == char);
// }

// test "maxIntToNbDigit should return the correct nbr of digit" {
//     const val1: usize = 4;
//     const val2: usize = 4567;
//     const val3: usize = 12;
//
//     const exp1: usize = 1;
//     const exp2: usize = 4;
//     const exp3: usize = 2;
//
//     const res1: usize = zim.maxIntToNbDigit(usize);
//     const res2: usize = zim.maxIntToNbDigit(usize);
//     const res3: usize = zim.maxIntToNbDigit(usize);
//
//
// }

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
