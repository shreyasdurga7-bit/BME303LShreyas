# Wound Healing Cellular Automaton

A Python simulation of wound healing dynamics on a 30×30 grid. You draw the wound, hit start, and watch the tissue repair itself over simulated hours.

Built for BME 303 at UT Austin.

## What it models

Cells exist in one of four states: healthy, wound, healing, or scar. Each timestep, cells update based on what their 8 neighbors are doing (Moore neighborhood). The basic rules:

- Healthy cells near a wound get recruited into healing cells
- Healing cells gradually convert wound into scar tissue
- Once the wound clears, healing cells relax back to healthy
- Scar tissue slowly remodels back to healthy over time (~72+ simulated hours)

## How to run

```bash
pip install numpy matplotlib
python wound_healing.py
```

Click and drag on the grid to draw a wound. Drag over existing wound cells to erase. Press **Start Simulation**. Each frame is one simulated hour.

## Dependencies

Python 3.x, NumPy, Matplotlib
