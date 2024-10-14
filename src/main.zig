const std = @import("std");
const cli = @import("zig-cli");
const print = std.debug.print;
const BoundedArray = std.BoundedArray;
const Arena = std.heap.ArenaAllocator;
const ascii = std.ascii;

const DEFAULT_DIM: usize = 5;
const MAX_BOARD_DIM: usize = 64;

const MyError = error{
    notHandledAtTheMoment,
    wrongFmtUsage,
    OverFlow,
    writerError,
};

const Quantity = enum {
    one,
    multiple,
};

const ByteOrBytes = union(Quantity) {
    one: u8,
    multiple: []u8,
};

const DigitStr = struct {
    bufType: ByteOrBytes,
    buf: []u8,

    pub fn init(bufType: ByteOrBytes) DigitStr {
        return DigitStr{
            .buf = switch (bufType) {
                Quantity.one => {
                const byteArray: [1]u8 = [1]u8{bufType.one};
                byteArray[0..];
            },
                Quantity.multiple => bufType.multiple,
            }
        };
    }
};

const Player = enum {
    human,
    ia,
};

const Game = struct {
    p1: Player,
    p2: Player,
    board: Board,

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
    strRepresnetation: [][]u8,

    pub fn init(dim: usize) Board {
        return Board{
            .dim = dim,
            .choices = buildBoard(dim),
            .arena = Arena.init(std.heap.page_allocator),
            .strRepresentation = buildStr(.arena, .dim, .choices),
        };
    }

    fn buildBoard(dim: usize) BoundedArray(usize, MAX_BOARD_DIM) {
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

    fn buildStr(allocator: *std.mem.Allocator, dim: usize, choices: BoundedArray(usize, MAX_BOARD_DIM)) ![][]u8 {
        const notStrLine = try allocator.alloc(&allocator, u8, ("Line ".len + 2) * @sizeOf(u8));
        notStrLine[0] = 'L';
        notStrLine[1] = 'i';
        notStrLine[2] = 'n';
        notStrLine[3] = 'e';
        notStrLine[4] = ' ';
        
        const testAppend = try appendSliceBuf(&allocator, notStrLine, undefined);
        // We want to build each line at a time
        for (0..dim) |l| {
            var bufSizeStr: []u8 = undefined;
            const sizeStr = try usizeToStr(&allocator, (l + 1));

            // No need of this if it works !!!
            if (sizeStr.isUnique) {
                bufSizeStr = sizeStr.buf[0..0];
            } else {
                bufSizeStr = sizeStr.buf;
            }

            const newChoiceLine = try repeatCharXTime(&allocator, 'X', choices.get(l));
            const linesNum = try appendSliceBuf(&allocator, testAppend, bufSizeStr);
            const fullLine = try appendSliceBuf(&allocator, linesNum, newChoiceLine);
        }
    }


    pub fn format(value: Board, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = value;
        //  const line = "Line ";
        // const notStrLine = allocator.alloc(u8, (line.len + 2) * @sizeOf(u8)) catch |err| switch (err) {
        //     error.OutOfMemory => return error.WriteError,
        //     else => return err,
        // };

        // const testAppend = appendSliceBuf(&allocator, notStrLine, undefined) catch |err| switch (err) {
        //     error.OutOfMemory => return error.WriteError,
        //     else => return err,
        // };

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


            // for (0..lines.get(l).len) |j| {
            //     try writer.writeByte(lines.get(l)[j]);
            // }
            //  _ = try writer.write(fullLine);
            // if (bytesWrittenX != fullLine.len) {
            //     return std.fmt.BufPrintError.NoSpaceLeft;
            // }

            try writer.writeAll("\n");

        // end part of the format:
        try writer.writeAll(fmt[endIndex..fmt.len]);
    }
};

var commandConfig = struct { player1: Player = Player.human, player2: Player = Player.ia, dim: usize = DEFAULT_DIM }{};

pub fn usizeToStr(allocator: *std.mem.Allocator, k: usize) !DigitStr {
    const allocSize: usize = maxIntToNbDigit(comptime usize);
    const buf = try allocator.alloc(u8, @sizeOf(u8) * allocSize);

    var isUnique: bool = true;
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
        isUnique = false;
    } else {
        const r: u8 = @intCast(usizeVal);
        const res: u8 = r + '0';
        buf[0] = res;
    }

    return DigitStr{ .buf = buf[0..cpt], .isUnique = isUnique };
}

pub fn maxIntToNbDigit(comptime T: type) usize {
    var i: usize = 0;
    const valMax: comptime_int = std.math.maxInt(T);
    var cpt = @as(u128, valMax);
    while (cpt > 0) : (cpt /= 10) {
        i += 1;
    }
    return i;
}

fn repeatCharXTime(allocator: *std.mem.Allocator, c: u8, x: usize) ![]u8 {
    var buf = try allocator.alloc(u8, x);
    for (0..buf.len) |i| {
        buf[i] = c;
    }
    return buf;
}

fn appendSliceBuf(allocator: *std.mem.Allocator, str: []u8, appendix: []u8) ![]u8 {
    var buf = try allocator.alloc(u8, (str.len + appendix.len) * @sizeOf(u8));

    //  print("Line is: {any}\n nb Allu is: {any}\n", .{ str, appendix });

    // Need to do a memcpy !!!
    @memcpy(buf, str);
    @memcpy(buf[str.len..], appendix);

    // std.mem.copyForwards(u8, buf, appendix);
    // std.mem.copyForwards(u8, buf, str);
    return buf;
}

fn dynStr(allocator: *std.mem.Allocator, str: []const u8) ![]u8 {
    const buf = try allocator.alloc(u8, str.len);
    std.mem.copyForwards(u8, buf, str);
    return buf;
}

pub fn main() !void {
    //  const reader = std.io.getStdIn().read();
    //  const writer = std.io.getStdOut().write();

    var appRunner = try cli.AppRunner.init(std.heap.page_allocator);
    //  defer appRunner.deinit();
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

fn subMain() !void {
    print("Type of p1: {}, and type of p2 is {}\nThe game will start with a board of {}\n", .{ commandConfig.player1, commandConfig.player2, commandConfig.dim });

    const c = &commandConfig;

    const board = Board.init(c.dim);
    const game = Game.init(c.player1, c.player2, board);

    if (game.p1 == Player.ia or game.p2 == Player.ia) {
        print("IA not handled at the moment\n", .{});
        return MyError.notHandledAtTheMoment;
    }

    const writer = std.io.getStdOut().writer();
    try std.fmt.format(writer, "{}\n", .{board});
    //  try std.io.getStdOut().writer().print("before   {}  after\n", .{board});

    //  print("{}", .{board});
}
