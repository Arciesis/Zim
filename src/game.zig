const std = @import("std");
const Player = @import("main.zig").Player;
const Board = @import("board.zig").Board;

/// Representation of the current state of the game
pub const Game = struct {
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
