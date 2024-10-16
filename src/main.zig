const std = @import("std");
const cli = @import("zig-cli");
const print = std.debug.print;
const BoundedArray = std.BoundedArray;
const Arena = std.heap.ArenaAllocator;
const ascii = std.ascii;

/// the default board dimension if none has been passed.
const DEFAULT_DIM: usize = 5;

/// The maximum dimension that can be passed through the board dim
const MAX_BOARD_DIM: usize = 64;

// TODO: make something better of MyError

/// My errors for this project.
const MyError = error{
    notHandledAtTheMoment,
    wrongFmtUsage,
    OverFlow,
    writerError,
    bufNotResized,
};

/// The representation of a Player
/// Either:
/// * An Human
/// * An AI
const Player = enum {
    human,
    ai,
};

/// Representation of the current state of the game
const Game = struct {
    p1: Player,
    p2: Player,
    board: Board,

    /// Initiate the game state
    pub fn init(p1: Player, p2: Player, board: Board) Game {
        return Game{
            .board = board,
            .p2 = p2,
            .p1 = p1,
        };
    }
};

const Board = struct {
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

        const space = notStrLineArray[(notStrLineArray.len - 1)..notStrLineArray.len];

        // We want to build each line at a time
        for (0..dim) |l| {
            // get the number of the line:
            // call lineNUm.buf to get the actual []u8 buf.
            const lineNum = try usizeToStr(allocator, l + 1);

            const lineNumSpace = try appendSliceBuf(allocator, lineNum, space);

            // concat lineNum.buf to noStrLine
            const linePlusNum = try appendSliceBuf(allocator, notStrLine, lineNumSpace);

            // get the number of X on that need to be printed.
            const xsNum = try repeatCharXTime(allocator, 'X', choices.get(l));

            // For now just print the line without the proper formatting.
            // So we just need to concat that to the previous const.
            const fullLine = try appendSliceBuf(allocator, linePlusNum, xsNum);

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

/// used to pass arguments to zig-cli
var commandConfig = struct { player1: Player = Player.human, player2: Player = Player.ai, dim: usize = DEFAULT_DIM }{};

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

/// Main function -> Entry point.
pub fn main() !void {
    var appRunner = try cli.AppRunner.init(std.heap.page_allocator);
    appRunner.deinit();

    const app = cli.App{
        .command = cli.Command{
            // The command is named "zim"
            .name = "zim",
            .options = &.{
                // First option => player1
                .{
                    .long_name = "player1",
                    .short_alias = '1',
                    .help = "Define the type (Human/IA) of the first player",
                    .value_name = "human/ia",
                    //  .required = true,
                    .value_ref = appRunner.mkRef(&commandConfig.player1),
                },

                // Second option => player2
                .{
                    .long_name = "player2",
                    .short_alias = '2',
                    .help = "Define the type (Human/IA) of the second player",
                    .value_name = "human/ia",
                    //  .required = true,
                    .value_ref = appRunner.mkRef(&commandConfig.player2),
                },

                .{
                    .long_name = "board",
                    .short_alias = 'b',
                    .help = "length of the board",
                    .value_ref = appRunner.mkRef(&commandConfig.dim),
                },
            },

            .target = cli.CommandTarget{
                .action = cli.CommandAction{ .exec = subMain },
            },
        },
    };
    try appRunner.run(&app);
}

// TODO: Rename this function properly
// TODO: makes it more idiomatic in function of its new name.

/// Actual main because the Main is just for the declarations of zig-cli.
fn subMain() !void {
    print("Type of p1: {}, and type of p2 is {}\nThe game will start with a board of {}\n", .{ commandConfig.player1, commandConfig.player2, commandConfig.dim });

    const c = &commandConfig;

    const allocator = std.heap.page_allocator;
    var board = try Board.init(allocator, c.dim);
    defer board.deinit();

    const game = Game.init(c.player1, c.player2, board);

    if (game.p1 == Player.ai or game.p2 == Player.ai) {
        print("IA not handled at the moment\n", .{});
        return MyError.notHandledAtTheMoment;
    }

    const writer = std.io.getStdOut().writer();
    try std.fmt.format(writer, "{}\n", .{board});
}
