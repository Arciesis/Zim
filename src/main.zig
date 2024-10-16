const std = @import("std");
const cli = @import("zig-cli");
const print = std.debug.print;
const BoundedArray = std.BoundedArray;
const Arena = std.heap.ArenaAllocator;
const utils = @import("utils.zig");
const Board = @import("board.zig").Board;
const Game = @import("game.zig").Game;

/// My errors for this project.
pub const ZimError = error{
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
pub const Player = enum {
    human,
    ai,
};

/// used to pass arguments to zig-cli
var commandConfig = struct { player1: Player = Player.human, player2: Player = Player.ai, dim: usize = 5 }{};

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
        return ZimError.notHandledAtTheMoment;
    }

    const writer = std.io.getStdOut().writer();
    try std.fmt.format(writer, "{}\n", .{board});
}
