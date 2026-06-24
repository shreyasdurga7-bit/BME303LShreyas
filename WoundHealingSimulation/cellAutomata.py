import numpy as np
import matplotlib
matplotlib.use('TkAgg')

import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.patches as mpatches
from matplotlib.animation import FuncAnimation
from matplotlib.widgets import Button
import random

# ─────────────────────────────────────────
# STATES
# ─────────────────────────────────────────
HEALTHY = 0
WOUND   = 1
HEALING = 2
SCAR    = 3

# ─────────────────────────────────────────
# PARAMETERS
# ─────────────────────────────────────────
GRID_SIZE = 30
MAX_WOUND_CELLS = 120
MAX_FRAMES = 1000

# animation speed
# 1 frame = 1 simulated hour
FRAME_INTERVAL_MS = 100

# initial extra healing cells away from wound
N_RANDOM_HEALING_CELLS = 10

# spread wound-edge ring recruitment across a few hours
RING_RECRUITMENT_HOURS = 4

# Moore-neighborhood probabilities
# wound -> scar depends on nearby healing cells
P_WOUND_TO_SCAR_PER_HEALING_NEIGHBOR = 0.18

# healthy -> healing depends on nearby wound
P_HEALTHY_TO_HEALING_PER_WOUND_NEIGHBOR = 0.10

# healing persistence
# if no wound nearby, healing cells may relax back to healthy
P_HEALING_TO_HEALTHY_NO_WOUND = 0.08

# scar remodeling
MIN_SCAR_AGE_FOR_HEALTHY = 72
P_SCAR_TO_HEALTHY_BASE = 0.02
P_SCAR_TO_HEALTHY_AGE_BOOST = 0.01

# dynamic x-axis settings, now in HOURS
INITIAL_X_WINDOW = 10
X_WINDOW_GROWTH = 10
X_BUFFER = 1

# ─────────────────────────────────────────
# COLOURS
# ─────────────────────────────────────────
cmap = mcolors.ListedColormap([
    '#6cc36c',  # healthy
    '#8b0000',  # wound
    '#ffd84d',  # healing
    '#b5b5b5',  # scar
])
bounds = [-0.5, 0.5, 1.5, 2.5, 3.5]
norm = mcolors.BoundaryNorm(bounds, cmap.N)

# ─────────────────────────────────────────
# INITIALIZATION
# ─────────────────────────────────────────
def init_grid():
    return np.full((GRID_SIZE, GRID_SIZE), HEALTHY, dtype=int)

def init_metadata():
    scar_age = np.zeros((GRID_SIZE, GRID_SIZE), dtype=int)
    return scar_age

# ─────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────
def get_moore_neighbors(r, c):
    neighbors = []
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            if dr == 0 and dc == 0:
                continue
            nr, nc = r + dr, c + dc
            if 0 <= nr < GRID_SIZE and 0 <= nc < GRID_SIZE:
                neighbors.append((nr, nc))
    return neighbors

def count_neighbors_in_state(grid, r, c, state):
    return sum(1 for nr, nc in get_moore_neighbors(r, c) if grid[nr, nc] == state)

def probability_from_neighbors(base_p, n_neighbors):
    """
    Independent-neighbor Moore rule:
    P = 1 - (1 - base_p)^n
    """
    if n_neighbors <= 0:
        return 0.0
    return 1.0 - (1.0 - base_p) ** n_neighbors

def count_states(grid):
    return {
        'healthy': int(np.sum(grid == HEALTHY)),
        'wound':   int(np.sum(grid == WOUND)),
        'healing': int(np.sum(grid == HEALING)),
        'scar':    int(np.sum(grid == SCAR)),
    }

def all_healthy(grid):
    return np.all(grid == HEALTHY)

# ─────────────────────────────────────────
# INITIAL HEALING SEEDING
# ─────────────────────────────────────────
def prepare_initial_healing(grid):
    """
    At start:
    1. identify the healthy cells touching the wound (ring cells), but do NOT
       convert them all immediately
    2. immediately add a small random scatter of healing cells elsewhere
    3. return the updated grid plus a shuffled list of pending ring cells
    """
    new_grid = grid.copy()

    wound_cells = list(zip(*np.where(grid == WOUND)))

    # collect unique healthy ring cells around wound
    ring_cells = set()
    for r, c in wound_cells:
        for nr, nc in get_moore_neighbors(r, c):
            if new_grid[nr, nc] == HEALTHY:
                ring_cells.add((nr, nc))

    ring_cells = list(ring_cells)
    random.shuffle(ring_cells)

    # add small random scattered healing cells immediately,
    # avoiding pending ring cells so the ring can appear gradually
    ring_cell_set = set(ring_cells)
    healthy_cells = [
        (r, c) for r, c in zip(*np.where(new_grid == HEALTHY))
        if (r, c) not in ring_cell_set
    ]
    random.shuffle(healthy_cells)
    n_to_add = min(N_RANDOM_HEALING_CELLS, len(healthy_cells))

    for i in range(n_to_add):
        r, c = healthy_cells[i]
        new_grid[r, c] = HEALING

    return new_grid, ring_cells

def recruit_ring_cells(grid, pending_ring_cells):
    """
    Convert a fraction of pending wound-edge ring cells into healing cells
    this tick, spreading recruitment over several hours.
    """
    if not pending_ring_cells:
        return grid, pending_ring_cells

    new_grid = grid.copy()
    remaining = len(pending_ring_cells)

    # recruit enough so the whole list tends to finish in RING_RECRUITMENT_HOURS
    n_to_recruit = max(1, int(np.ceil(remaining / RING_RECRUITMENT_HOURS)))

    next_pending = []
    recruited = 0

    for cell in pending_ring_cells:
        if recruited < n_to_recruit:
            r, c = cell
            if new_grid[r, c] == HEALTHY:
                new_grid[r, c] = HEALING
            recruited += 1
        else:
            next_pending.append(cell)

    return new_grid, next_pending

# ─────────────────────────────────────────
# SIMULATION RULES
# ─────────────────────────────────────────
def step_simulation(grid, scar_age):
    old_grid = grid.copy()
    new_grid = grid.copy()
    new_scar_age = scar_age.copy()

    # age existing scar
    for r in range(GRID_SIZE):
        for c in range(GRID_SIZE):
            if old_grid[r, c] == SCAR:
                new_scar_age[r, c] += 1

    # apply rules using Moore neighborhood
    for r in range(GRID_SIZE):
        for c in range(GRID_SIZE):
            state = old_grid[r, c]

            n_wound = count_neighbors_in_state(old_grid, r, c, WOUND)
            n_healing = count_neighbors_in_state(old_grid, r, c, HEALING)
            n_scar = count_neighbors_in_state(old_grid, r, c, SCAR)
            n_healthy = count_neighbors_in_state(old_grid, r, c, HEALTHY)

            # HEALTHY -> HEALING
            if state == HEALTHY:
                p_heal = probability_from_neighbors(
                    P_HEALTHY_TO_HEALING_PER_WOUND_NEIGHBOR,
                    n_wound
                )

                if n_wound > 0 and n_healing > 0:
                    p_heal = min(p_heal + 0.08, 0.95)

                if random.random() < p_heal:
                    new_grid[r, c] = HEALING

            # WOUND -> SCAR
            # healing cells convert nearby wound into scar tissue
            elif state == WOUND:
                p_scar = probability_from_neighbors(
                    P_WOUND_TO_SCAR_PER_HEALING_NEIGHBOR,
                    n_healing
                )

                if n_scar >= 2:
                    p_scar = min(p_scar + 0.06, 0.95)

                if random.random() < p_scar:
                    new_grid[r, c] = SCAR
                    new_scar_age[r, c] = 0

            # HEALING -> stays HEALING unless wound is gone nearby
            elif state == HEALING:
                if n_wound == 0 and random.random() < P_HEALING_TO_HEALTHY_NO_WOUND:
                    new_grid[r, c] = HEALTHY

            # SCAR -> HEALTHY slowly over time
            elif state == SCAR:
                if new_scar_age[r, c] >= MIN_SCAR_AGE_FOR_HEALTHY:
                    p_remodel = (
                        P_SCAR_TO_HEALTHY_BASE
                        + P_SCAR_TO_HEALTHY_AGE_BOOST
                        * (new_scar_age[r, c] - MIN_SCAR_AGE_FOR_HEALTHY + 1)
                    )

                    p_remodel += 0.02 * n_healthy
                    p_remodel -= 0.03 * n_wound
                    p_remodel = max(0.0, min(p_remodel, 0.80))

                    if random.random() < p_remodel:
                        new_grid[r, c] = HEALTHY
                        new_scar_age[r, c] = 0

    # reset age where cells are no longer scar
    new_scar_age[new_grid != SCAR] = 0

    return new_grid, new_scar_age

# ─────────────────────────────────────────
# MAIN INTERACTIVE APP
# ─────────────────────────────────────────
def run_interactive_wound_healing():
    grid = init_grid()
    scar_age = init_metadata()

    started = {'value': False}
    finished = {'value': False}
    wound_count = {'value': 0}
    tick_counter = {'value': 0}

    # store pending wound-edge ring cells to recruit over time
    pending_ring_cells = []

    history_counts = [count_states(grid)]

    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    plt.subplots_adjust(bottom=0.30)

    ax_grid = axes[0]
    ax_plot = axes[1]

    im = ax_grid.imshow(grid, cmap=cmap, norm=norm, interpolation='nearest')
    ax_grid.set_title(f"Select wound cells: {wound_count['value']} / {MAX_WOUND_CELLS}")
    ax_grid.set_xlabel("X")
    ax_grid.set_ylabel("Y")

    ax_grid.set_xticks(np.arange(-0.5, GRID_SIZE, 1), minor=True)
    ax_grid.set_yticks(np.arange(-0.5, GRID_SIZE, 1), minor=True)
    ax_grid.grid(which='minor', color='black', linestyle='-', linewidth=0.2)
    ax_grid.tick_params(which='minor', bottom=False, left=False)

    legend_patches = [
        mpatches.Patch(color='#6cc36c', label='Healthy Tissue'),
        mpatches.Patch(color='#8b0000', label='Open Wound'),
        mpatches.Patch(color='#ffd84d', label='Healing Cells'),
        mpatches.Patch(color='#b5b5b5', label='Scar Tissue'),
    ]
    ax_grid.legend(
        handles=legend_patches,
        loc='upper right',
        bbox_to_anchor=(.9, -0.12),
        ncol=2,
        fontsize=8
    )

    # time-series plot
    hours = [0]
    n_healthy = [history_counts[0]['healthy']]
    n_wound = [history_counts[0]['wound']]
    n_healing = [history_counts[0]['healing']]
    n_scar = [history_counts[0]['scar']]

    line_healthy, = ax_plot.plot([], [], lw=2, label='Healthy', color='#2ca02c')
    line_wound,   = ax_plot.plot([], [], lw=2, label='Wound', color='#8b0000')
    line_healing, = ax_plot.plot([], [], lw=2, label='Healing', color='#d9b300')
    line_scar,    = ax_plot.plot([], [], lw=2, label='Scar', color='gray')

    ax_plot.set_xlim(0, INITIAL_X_WINDOW)
    ax_plot.set_ylim(0, GRID_SIZE * GRID_SIZE)
    ax_plot.set_xlabel("Time (hours)")
    ax_plot.set_ylabel("Number of Cells")
    ax_plot.set_title("Tissue State Counts Over Time")
    ax_plot.legend(loc='upper right', fontsize=8)
    ax_plot.grid(True, alpha=0.3)

    vline = ax_plot.axvline(x=0, color='black', linestyle=':', lw=1)

    def refresh_plot():
        line_healthy.set_data(hours, n_healthy)
        line_wound.set_data(hours, n_wound)
        line_healing.set_data(hours, n_healing)
        line_scar.set_data(hours, n_scar)
        vline.set_xdata([hours[-1], hours[-1]])

    # button
    ax_button = plt.axes([0.47, 0.05, 0.18, 0.08])
    start_button = Button(ax_button, 'Start Simulation')

    # drag selection state
    mouse_dragging = {'value': False}
    drag_mode = {'value': None}   # 'add' or 'erase'
    last_drag_cell = {'value': None}

    def get_cell_from_event(event):
        if event.inaxes != ax_grid:
            return None
        if event.xdata is None or event.ydata is None:
            return None

        c = int(np.floor(event.xdata + 0.5))
        r = int(np.floor(event.ydata + 0.5))

        if not (0 <= r < GRID_SIZE and 0 <= c < GRID_SIZE):
            return None

        return r, c

    def apply_cell_change(r, c, mode):
        if mode == 'add':
            if grid[r, c] != WOUND:
                if wound_count['value'] >= MAX_WOUND_CELLS:
                    ax_grid.set_title(f"Max wound cells reached: {MAX_WOUND_CELLS}")
                    return
                grid[r, c] = WOUND
                wound_count['value'] += 1

        elif mode == 'erase':
            if grid[r, c] == WOUND:
                grid[r, c] = HEALTHY
                wound_count['value'] -= 1

        ax_grid.set_title(f"Select wound cells: {wound_count['value']} / {MAX_WOUND_CELLS}")
        im.set_data(grid)

    def on_mouse_press(event):
        if started['value']:
            return

        cell = get_cell_from_event(event)
        if cell is None:
            return

        r, c = cell
        mouse_dragging['value'] = True
        last_drag_cell['value'] = cell

        if grid[r, c] == WOUND:
            drag_mode['value'] = 'erase'
        else:
            drag_mode['value'] = 'add'

        apply_cell_change(r, c, drag_mode['value'])
        fig.canvas.draw_idle()

    def on_mouse_move(event):
        if started['value']:
            return
        if not mouse_dragging['value']:
            return

        cell = get_cell_from_event(event)
        if cell is None:
            return

        if cell == last_drag_cell['value']:
            return

        r, c = cell
        apply_cell_change(r, c, drag_mode['value'])
        last_drag_cell['value'] = cell
        fig.canvas.draw_idle()

    def on_mouse_release(event):
        mouse_dragging['value'] = False
        drag_mode['value'] = None
        last_drag_cell['value'] = None

    def on_start(event):
        nonlocal grid, pending_ring_cells

        if started['value']:
            return

        if wound_count['value'] == 0:
            ax_grid.set_title("Select at least 1 wound cell before starting")
            fig.canvas.draw_idle()
            return

        grid, pending_ring_cells = prepare_initial_healing(grid)
        started['value'] = True
        im.set_data(grid)
        ax_grid.set_title("Simulation Running: Hour 0")
        fig.canvas.draw_idle()

    fig.canvas.mpl_connect('button_press_event', on_mouse_press)
    fig.canvas.mpl_connect('motion_notify_event', on_mouse_move)
    fig.canvas.mpl_connect('button_release_event', on_mouse_release)
    start_button.on_clicked(on_start)

    def update(frame):
        nonlocal grid, scar_age, pending_ring_cells

        if not started['value']:
            return im, line_healthy, line_wound, line_healing, line_scar, vline

        if finished['value']:
            return im, line_healthy, line_wound, line_healing, line_scar, vline

        # gradually recruit wound-edge ring cells over the first few hours
        grid, pending_ring_cells = recruit_ring_cells(grid, pending_ring_cells)

        grid, scar_age = step_simulation(grid, scar_age)
        tick_counter['value'] += 1

        counts = count_states(grid)
        history_counts.append(counts)

        current_hour = tick_counter['value']

        hours.append(current_hour)
        n_healthy.append(counts['healthy'])
        n_wound.append(counts['wound'])
        n_healing.append(counts['healing'])
        n_scar.append(counts['scar'])

        im.set_data(grid)
        refresh_plot()

        current_xlim = ax_plot.get_xlim()[1]
        if current_hour >= current_xlim - X_BUFFER:
            ax_plot.set_xlim(0, current_xlim + X_WINDOW_GROWTH)

        if all_healthy(grid):
            finished['value'] = True
            ax_grid.set_title(f"Finished: All Tissue Healthy at Hour {current_hour}")
            print(f"Simulation complete at hour {current_hour}.")
            ani.event_source.stop()
        else:
            ax_grid.set_title(f"Simulation running: Hour {current_hour}")

        return im, line_healthy, line_wound, line_healing, line_scar, vline

    ani = FuncAnimation(
        fig,
        update,
        frames=MAX_FRAMES,
        interval=FRAME_INTERVAL_MS,
        blit=False,
        repeat=False
    )

    plt.show()

# ─────────────────────────────────────────
# RUN
# ─────────────────────────────────────────
if __name__ == "__main__":
    print("Click and drag to create the initial wound.")
    print(f"Maximum wound cells allowed: {MAX_WOUND_CELLS}")
    print("Drag over wound cells again to erase them.")
    print("Then press 'Start Simulation'.")
    print("Each tick represents 1 simulated hour.")
    run_interactive_wound_healing()
