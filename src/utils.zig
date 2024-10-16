const std = @import("std");

/// Gives the bytes in ascii of a number
/// e.g: 22 => {'2', '2'}
pub fn usizeToStr(allocator: *std.mem.Allocator, k: usize) ![]u8 {
    const allocSize: usize = maxIntToNbDigit(comptime usize);
    const buf = try allocator.alloc(u8, allocSize);

    var usizeVal: usize = k;
    var cpt: usize = 0;
    if (usizeVal > 9) {
        while (usizeVal > 0) : (usizeVal /= 10) {
            const r: usize = (usizeVal % 10);
            const res: u8 = @intCast(r);

            switch (res) {
                0...9 => buf[cpt] = (res + '0'),
                else => unreachable,
            }

            cpt += 1;
        }
        std.mem.reverse(u8, buf[0..cpt]);

        return buf[0..cpt];
    } else {
        const r: u8 = @intCast(usizeVal);
        const res: u8 = (r + '0');
        buf[0] = res;
        return buf[0..1];
    }
}

pub fn nbDigitInNbr(nbr: usize) usize {
    var cpt: usize = 0;
    var number = nbr;
    // need to check the type is integer (And maybe float ???)

    while (number > 0) : (number /= 10) {
        cpt += 1;
    }
    return cpt;
}

/// Gives the number of digit to code a number in ascii.
/// AKA the number of byte to code this number.
pub fn maxIntToNbDigit(comptime T: type) usize {
    var i: usize = 0;
    const valMax: comptime_int = std.math.maxInt(T);
    var cpt = @as(u128, valMax);
    while (cpt > 0) : (cpt /= 10) {
        i += 1;
    }
    return i;
}

/// returns a buffer of u8 (aka []u8) of a repeated character
pub fn repeatCharXTime(allocator: *std.mem.Allocator, c: u8, x: usize) ![]u8 {
    var buf = try allocator.alloc(u8, x);
    for (0..buf.len) |i| {
        buf[i] = c;
    }
    return buf;
}

/// Concats two slices of u8 (aka []u8) and return a third slice of the concataned slices
pub fn appendSliceBuf(allocator: *std.mem.Allocator, str: []u8, appendix: []u8) ![]u8 {
    var buf = try allocator.alloc(u8, (str.len + appendix.len));

    for (0..buf.len) |i| {
        if (i < str.len) {
            buf[i] = str[i];
        } else {
            buf[i] = appendix[i - str.len];
        }
    }

    return buf;
}
