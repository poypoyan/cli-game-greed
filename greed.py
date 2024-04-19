# Greed game in Python
# Note: uses 3rd-party libraries numpy and readchar
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>. 

from dataclasses import dataclass
import os
import numpy as np
import readchar


@dataclass
class GameState:
    HEIGHT: int
    WIDTH: int
    CELLS: int
    arr: np.ndarray
    curr: np.ndarray
    score: int = 0


DIRS = np.array([(-1, -1), (-1, 0), (-1, 1),
    (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)])


def percentage(gs: GameState) -> str:
    return f'{gs.score * 100 / gs.CELLS:0.2f}%'


def init(h: int, w: int) -> GameState:
    curr = np.random.randint(0, (h, w))   # current location (the '@')
    arr = np.random.randint(1, high=10, size=(h, w))
    arr[curr[0], curr[1]] = 0
    return GameState(h, w, h * w, arr, curr)


def disp(gs: GameState, hl: dict, palette: list, cls: str) -> None:
    line = ''
    for i in range(gs.HEIGHT):
        for j in range(gs.WIDTH):
            if i == gs.curr[0] and j == gs.curr[1]:
                line += '@'
            elif gs.arr[i, j] == 0:
                line += ' '
            elif is_in_highlight(hl, (i, j)):
                line += f'{ansi_color(palette[0])}{gs.arr[i, j]}{ansi_color(0)}'
            else:
                line += f'{ansi_color(palette[gs.arr[i, j]])}{gs.arr[i, j]}{ansi_color(0)}'
        line += '\n'
    os.system(cls)
    print(f'{line}{ansi_color(0)}')


def is_in_highlight(hl: dict, coord: tuple) -> bool:
    for i in hl:
        if coord in hl[i]:
            return True
    else:
        return False


def ansi_color(code):
    return f'\u001b[{code}m'


def get_moves(gs: GameState) -> dict:
    highlight = {}
    for i in range(len(DIRS)):
        check_coord = (gs.curr[0] + DIRS[i][0], gs.curr[1] + DIRS[i][1])
        if not is_in_grid(gs, check_coord):
            continue
        dir_cells = []
        num_beside = gs.arr[check_coord[0], check_coord[1]]

        for j in range(num_beside):
            if not is_in_grid(gs, check_coord) or gs.arr[check_coord[0], check_coord[1]] == 0:
                break
            dir_cells.insert(0, check_coord)
            check_coord = (check_coord[0] + DIRS[i][0], check_coord[1] + DIRS[i][1])
        else:
            if num_beside > 0:
                highlight[i] = dir_cells
    return highlight


def is_in_grid(gs: GameState, coord: tuple) -> bool:
    return 0 <= coord[0] and coord[0] < gs.HEIGHT and 0 <= coord[1] and coord[1] < gs.WIDTH


def update(gs: GameState, hl: dict, upd_dir: int) -> None:
    clear_coords = hl[upd_dir]
    for i in clear_coords:
        gs.arr[i] = 0
    gs.curr[0] = clear_coords[0][0]
    gs.curr[1] = clear_coords[0][1]
    gs.score += len(clear_coords)


def exit_game() -> None:
    print()   # have last new line before exit
    exit()


if __name__ == '__main__':
    HEIGHT = 22
    WIDTH = 79
    PALETTE = ['90;47', '33', '31', '32', '34', '35', '93', '91', '92', '96']
    CONTROL = ['q', 'w', 'e', 'a', 'd', 'z', 'x', 'c']
    QUITKEY = ' '

    if os.name == 'nt':
        CLEAR_SCREEN = 'cls'
    else:
        CLEAR_SCREEN = 'clear'

    gs = init(HEIGHT, WIDTH)

    while True:
        hl = get_moves(gs)
        disp(gs, hl, PALETTE, CLEAR_SCREEN)
        print(f'Score: {gs.score}   Percentage: {percentage(gs)}', end=' ', flush=True)
        if len(hl) == 0:
            print('   Game over! Press any key to quit.', end=' ', flush=True)
            readchar.readkey()
            break
        chosen_dir = 0
        while True:
            key = readchar.readkey()
            if key == QUITKEY:
                exit_game()
            if not key in CONTROL:
                continue

            chosen_dir = CONTROL.index(key)
            if chosen_dir in hl:
               break
        update(gs, hl, chosen_dir)
    exit_game()
