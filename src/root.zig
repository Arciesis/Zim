const std = @import("std");
const cli = @import("zig-cli");
const zim = @import("main.zig");

const testing = std.testing;

test "usizeToStr must return a valid digit for any usize" {
    var allocator = std.heap.page_allocator;
    const size: usize = 8;
    const char: u8 = '8';
    const slice = try zim.usizeToStr(&allocator, size);
    try testing.expect(slice[0] == char);
}
