// Greed game in Zig
// Note: compile with zig build-exe -lc
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const builtin = @import("builtin");
const c_stdlib = @cImport({@cInclude("stdlib.h");});
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

// Get a character (Getch). This only works on Linux.
// Source: https://www.reddit.com/r/Zig/comments/j77jgs/comment/g83cm4c/
// TODO: simple Zig package for getch (atleast Linux and Windows)
fn getch() !u8 {
    const c = @cImport({
        @cInclude("termios.h");
        @cInclude("unistd.h");
        @cInclude("stdlib.h");
    });

    // save current mode
    var orig_termios: c.termios = undefined;
    _ = c.tcgetattr(c.STDIN_FILENO, &orig_termios);

    // set new "raw" mode
    var raw: c.termios = undefined;
    raw.c_lflag &= ~(@as(u8, c.ECHO) | @as(u8, c.ICANON));
    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &raw);

    const char = try stdin.readByte();

    // restore old mode
    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &orig_termios);
    return char;
}

fn GameState(comptime h: u8, comptime w: u8) type {
    return struct {
        arr: [h][w]u8,
        score: u64,
        curr: [2]u8
    };
}

const Highlight = std.AutoArrayHashMap(u8, std.BoundedArray([2]u8, 9));

const dirs = [_][2]i8{
    [2]i8{ -1, -1 },
    [2]i8{ -1,  0 },
    [2]i8{ -1,  1 },
    [2]i8{  0, -1 },
    [2]i8{  0,  1 },
    [2]i8{  1, -1 },
    [2]i8{  1,  0 },
    [2]i8{  1,  1 },
};

fn percentage(h: u8, w: u8, score: u64) f64 {
    return @as(f64, @floatFromInt(score * 100)) / (@as(f64, @floatFromInt(h)) * @as(f64, @floatFromInt(w)));
}

fn init(comptime h: u8, comptime w: u8) GameState(h, w) {
    var rand_impl = std.rand.DefaultPrng.init(@as(u64, @bitCast(std.time.milliTimestamp())));
    const curr = [2]u8{rand_impl.random().int(u8) % h, rand_impl.random().int(u8) % w};
    var arr: [h][w]u8 = undefined;
    for (&arr) |*row| {
        for (row) |*cell| {
            cell.* = rand_impl.random().int(u8) % 9 + 1;
        }
    }
    arr[curr[0]][curr[1]] = 0;
    return GameState(h, w) {
        .arr = arr,
        .score = 0,
        .curr = curr,
    };
}

fn disp(allocator: std.mem.Allocator, comptime h: u8, comptime w: u8, gs: *GameState(h, w), hl: Highlight,
        palette: [10][:0]const u8, cls: [:0]const u8) !void {
    var line = try allocator.alloc(u8, @as(u64, 23) * h * w);
    defer allocator.free(line);
    var track_len: u64 = 0;

    for (0..h) |i| {
        for (0..w) |j| {
            if (i == gs.curr[0] and j == gs.curr[1]) {
                try place_in_str(&line, "@", &track_len);
            } else if (gs.arr[i][j] == 0) {
                try place_in_str(&line, " ", &track_len);
            } else if (is_in_highlight(hl, [2]u8{ @as(u8, @truncate(i)), @as(u8, @truncate(j)) })) {
                const digit = try std.fmt.allocPrintZ(allocator, "\u{001b}[{s}m{d}\u{001b}[0m", .{ palette[0], gs.arr[i][j] });
                defer allocator.free(digit);
                try place_in_str(&line, digit, &track_len);
            } else {
                const digit = try std.fmt.allocPrintZ(allocator, "\u{001b}[{s}m{d}\u{001b}[0m", .{ palette[gs.arr[i][j]], gs.arr[i][j] });
                defer allocator.free(digit);
                try place_in_str(&line, digit, &track_len);
            }
        }
        try place_in_str(&line, "\n", &track_len);
    }

    _ = c_stdlib.system(cls);
    try stdout.print("{s}\n", .{ line[0..track_len] });
}

fn is_in_highlight(hl: Highlight, coord: [2]u8) bool {
    for (hl.keys()) |i| {
        for (hl.get(i).?.slice()) |j| {
            if (std.mem.eql(u8, &coord, &j)) return true;
        }
    } else return false;
}

fn place_in_str(str: *[]u8, input: [:0]const u8, curr_len: *u64) !void {
    for (0..input.len) |i| {
        str.*[curr_len.* + i] = input[i];
    }
    curr_len.* += input.len;
}

fn get_moves(comptime h: u8, comptime w: u8, gs: *GameState(h, w), hl: *Highlight) !void {
    for (0..dirs.len) |i| {
        var check_coord: [2]i8 = undefined;
        var adj_coord: [2]u8 = undefined;
        try add_coords_to_i8(gs.curr, dirs[i], &check_coord);
        if (!is_in_grid(h, w, check_coord)) continue;
        try coord_to_u8(check_coord, &adj_coord);

        var dir_cells: std.BoundedArray([2]u8, 9) = .{};
        const num_beside = gs.arr[adj_coord[0]][adj_coord[1]];

        for(0..num_beside) |_| {
            if (!is_in_grid(h, w, check_coord)) break;
            try coord_to_u8(check_coord, &adj_coord);
            if (gs.arr[adj_coord[0]][adj_coord[1]] == 0) break;
            try dir_cells.insert(0, adj_coord);
            try add_coords_to_i8(adj_coord, dirs[i], &check_coord);
        } else {
            if (num_beside > 0) try hl.put(@as(u8, @truncate(i)), dir_cells);
        }
    }
}

fn add_coords_to_i8(coord: [2]u8, dir: [2]i8, res: *[2]i8) !void {
    res[0] = @as(i8, @intCast(coord[0])) + dir[0];
    res[1] = @as(i8, @intCast(coord[1])) + dir[1];
}

fn coord_to_u8(coord: [2]i8, res: *[2]u8) !void {
    res[0] = @as(u8, @intCast(coord[0]));
    res[1] = @as(u8, @intCast(coord[1]));
}

fn is_in_grid(h: u8, w: u8, coord: [2]i8) bool {
    return 0 <= coord[0] and coord[0] < h and 0 <= coord[1] and coord[1] < w;
}

fn update(comptime h: u8, comptime w: u8, gs: *GameState(h, w), hl: Highlight, upd_dir: u8) void {
    const clear_coords = hl.get(upd_dir).?.slice();
    for (clear_coords) |i| gs.arr[i[0]][i[1]] = 0;
    gs.curr[0] = clear_coords[0][0];
    gs.curr[1] = clear_coords[0][1];
    gs.score += clear_coords.len;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const clear_screen =
        if (builtin.os.tag == .windows)
            "cls"
        else
            "clear";

    const h = 22;
    const w = 79;
    const palette = [_][:0]const u8{"90;47", "33", "31", "32", "34", "35", "93", "91", "92", "96"};
    const control  = [_]u8{'q', 'w', 'e', 'a', 'd', 'z', 'x', 'c'};
    const quitkey = ' ';

    var gs = init(h, w);   // width and height must be known in comptime

    while (true) {
        var hl = Highlight.init(allocator);
        defer hl.deinit();

        try get_moves(h, w, &gs, &hl);
        try disp(allocator, h, w, &gs, hl, palette, clear_screen);

        try stdout.print("Score: {d}   Percentage: {d:.2} ", .{ gs.score, percentage(h, w, gs.score) });

        if (hl.count() == 0) {
            try stdout.print("   Game over! Press any key to quit.", .{});
            _ = try getch();
            try stdout.print("\n", .{});
            return;
        }

        var chosen_dir: u8 = undefined;
        while (true) {
            const key = try getch();
            if (key == quitkey) {
                try stdout.print("\n", .{});
                return;
            }

            for (0..control.len, control) |i, j| {
                if (j == key) {
                    chosen_dir = @as(u8, @truncate(i)); break;
                }
            } else continue;

            var valid = false;
            for (hl.keys()) |i| {
                if (i == chosen_dir) {
                    valid = true; break;
                }
            }
            if (valid) break;
        }
        update(h, w, &gs, hl, chosen_dir);
    }
}
