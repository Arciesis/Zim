const std = @import("std");
const BoundedArray = std.BoundedArray;
const Arena = std.heap.ArenaAllocator;
const utils = @import("utils.zig");

/// The maximum dimension that can be passed through the board dim
const MAX_BOARD_DIM: usize = 64;

pub const Board = struct {
    dim: usize,
    choices: BoundedArray(usize, MAX_BOARD_DIM),
    arena: Arena,
    /// Represent the board line by line
    strRepresentation: [][]u8,

    /// Initiate the Board
    pub fn init(allocator: std.mem.Allocator, dim: usize) !Board {
        var arena = Arena.init(allocator);
        const choices = buildBoard(dim);
        var alloc = arena.allocator();
        const strRep = try buildStr(&alloc, dim, choices);

        return Board{
            .dim = dim,
            .choices = choices,
            .arena = arena,
            .strRepresentation = strRep,
        };
    }

    /// Deinitiate the Board
    pub fn deinit(self: *Board) void {
        self.arena.deinit();
    }

    /// build the representation of the board as a an array.
    /// first dimension is the line of the board.
    /// second dimension is the number of remaining cross on the corresponding line
    fn buildBoard(dim: usize) BoundedArray(usize, MAX_BOARD_DIM) {
        // TODO: Need to check this while, it sound suspicious !
        var tab = while (BoundedArray(usize, MAX_BOARD_DIM).init(dim)) |val| {
            break val;
        } else |_| {
            std.posix.exit(4);
        };

        for (0..dim) |k| {
            tab.set(k, (2 * k + 1));
        }
        return tab;
    }

    /// Build the represnention of the board as bytes of u8 (aka []u8)
    /// In order to be able to print them afterwards.
    fn buildStr(allocator: *std.mem.Allocator, dim: usize, choices: BoundedArray(usize, MAX_BOARD_DIM)) ![][]u8 {
        const bufLine: [][]u8 = try allocator.alloc([]u8, dim);

        var notStrLineArray: [5]u8 = [_]u8{ 'L', 'i', 'n', 'e', ' ' };
        const notStrLine = notStrLineArray[0..];

        // We want to build each line at a time
        for (0..dim) |l| {
            var spaceToAdd: []u8 = undefined;
            const maxSpaceToAdd = utils.nbDigitInNbr(dim);
            if ((l + 1) > 9) {
                const deltaSpace = maxSpaceToAdd - utils.nbDigitInNbr(l);
                spaceToAdd = try utils.repeatCharXTime(allocator, ' ', if (deltaSpace == 0) 1 else deltaSpace);
            } else {
                spaceToAdd = try utils.repeatCharXTime(allocator, ' ', maxSpaceToAdd);
            }
            // get the number of the line:
            const lineNum = try utils.usizeToStr(allocator, l + 1);

            const lineNumSpace = try utils.appendSliceBuf(allocator, lineNum, spaceToAdd);

            // concat lineNum.buf to noStrLine
            const linePlusNum = try utils.appendSliceBuf(allocator, notStrLine, lineNumSpace);

            // get the number of X on that need to be printed.
            const xsNum = try utils.repeatCharXTime(allocator, 'X', choices.get(l));

            // For now just print the line without the proper formatting.
            // So we just need to concat that to the previous const.
            const fullLine = try utils.appendSliceBuf(allocator, linePlusNum, xsNum);

            // We got the full line so it can be pushed to the slice of slice of u8
            //  print("{any}\n", .{fullLine});
            bufLine[l] = fullLine;
        }
        return bufLine;
    }

    /// My implementation of a format to actually print the board.
    pub fn format(value: Board, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;

        comptime var i = 0;
        const startIndex = i;
        while (i < fmt.len) : (i += 1) {
            switch (fmt[i]) {
                '{', '}' => break,
                else => {},
            }
        }
        const endIndex = i;

        // first part of the fmt
        if (startIndex != endIndex) {
            try writer.writeAll(fmt[startIndex..endIndex]);
        }

        // Values of the board.
        for (0..value.strRepresentation.len) |j| {
            for (0..value.strRepresentation[j].len) |k| {
                try writer.writeByte(value.strRepresentation[j][k]);
            }
            try writer.writeAll("\n");
        }

        // end part of the format:
        try writer.writeAll(fmt[endIndex..fmt.len]);
    }
};
