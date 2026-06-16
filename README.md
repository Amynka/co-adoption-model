# Co-adoption of Low-Carbon Household Energy Technologies — Python Port

Python reimplementation of the agent-based model (ABM) from:

> van der Kam, M., Lagomarsino, M., Azar, E., Hahnel, U.J.J., & Parra, D. (2024).
> **An empirical agent-based model of consumer co-adoption of low-carbon technologies to inform energy policy.**
> *Cell Reports Sustainability*, 1, 100268.
> https://doi.org/10.1016/j.crsus.2024.100268

The original model was written in NetLogo. This port was created by **Claude Sonnet 4.6** (Anthropic, model ID `claude-sonnet-4-6`), June 2025.

---

## What the model does

Simulates how 1,469 Swiss households (each mapped 1-to-1 to a real survey respondent) decide to adopt three low-carbon technologies between 2022 and 2051:

| Technology | Abbrev |
|---|---|
| PV solar panels | PV |
| Electric vehicles (small / medium / large) | EV |
| Heat pumps | HP |

Each year agents update adoption decisions based on falling prices, improving EV ranges, GHG reductions, word-of-mouth from neighbours, and co-adoption bonuses (owning one technology raises the probability of adopting a complementary one). The model tests 14 binary policy levers (subsidies, bundle bonuses, GHG standards, tenant support, etc.) and tracks co-adoption outcomes.

---

## Repository structure

```
co-adoption-model/
├── co_adoption_model.py   # Core ABM — Config, House, Person, Simulation
├── make_figures.py        # Runs policy scenarios and reproduces Figures 2, 3, 5
├── requirements.txt       # Python dependencies
├── LICENSE                # CC BY 4.0 (inherited from original model)
├── data/
│   └── surveyData.csv     # Survey data: 1,469 Swiss respondents (original study)
└── README.md
```

The survey data (`surveyData.csv`, 1,469 real Swiss respondents) is included in this repository:

```
data/surveyData.csv
```

---

## Environment

**Python 3.10+** required.

### Option A — conda (recommended)

```bash
conda create -n co-adoption python=3.10
conda activate co-adoption
pip install -r requirements.txt
```

### Option B — venv (built-in)

```bash
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### Option C — install directly

```bash
pip install pandas numpy matplotlib scipy scikit-learn
```

### Dependencies

| Package | Version | Purpose |
|---|---|---|
| `pandas` | ≥ 1.5 | Load and process the survey CSV |
| `numpy` | ≥ 1.23 | Array operations used in figure generation |
| `matplotlib` | ≥ 3.6 | All figure rendering |
| `scipy` | ≥ 1.9 | Statistical utilities (optional fallback) |
| `scikit-learn` | ≥ 1.1 | Linear regression for Figure 3 policy impact slopes |

All dependencies are pinned in [`requirements.txt`](requirements.txt).

---

## How to run

### 1. Run the simulation and generate all figures

Full replication (1,469 agents, 256 policy scenarios — ~30–60 min depending on CPU):

```bash
python3 make_figures.py --scenarios 256 --households 1469 --workers 4 --save-cache results.pkl
```

Quick test (300 agents, 20 scenarios — ~2 min):

```bash
python3 make_figures.py --scenarios 20 --households 300 --workers 1
```

Re-generate figures from cached results (no re-simulation):

```bash
python3 make_figures.py --cache results.pkl
```

Figures are saved to `figures/`:
- `figure2_diffusion_curves.png` — PV / EV / HP / co-adoption diffusion across all policy scenarios
- `figure3_policy_impacts.png` — regression coefficients of each policy on adoption in 2030 vs 2050
- `figure5_demographics.png` — adoption shares by income group and home ownership

### 2. Run the simulation directly (no figures)

```bash
python3 co_adoption_model.py --households 1469 --years 29 --seed 42 --csv output.csv
```

Key options:

| Flag | Default | Description |
|---|---|---|
| `--households` | 1469 | Number of agents |
| `--years` | 29 | Simulation length (2022 → 2051) |
| `--runs` | 1 | Number of independent runs |
| `--seed` | random | Random seed |
| `--csv` | — | Save results to CSV |
| `--plot` | off | Show adoption curves (requires matplotlib) |
| `--subsidy-pv` | 0 | PV subsidy % |
| `--subsidy-ev` | 0 | EV subsidy % |
| `--subsidy-hp` | 33 | Heat pump subsidy % |
| `--bundle-bonus` | 100 | Bundle discount % |
| `--savings-ev` | low | EV savings level: `low` / `medium` / `high` |
| `--no-wom` | — | Disable word-of-mouth |
| `--no-neighbour` | — | Disable neighbourhood effect |

### 3. Policy scenario example

Test the effect of a 30 % PV subsidy + tenant support:

```bash
python3 co_adoption_model.py \
  --subsidy-pv 30 \
  --no-tenants  # remove this flag to enable tenants
  --csv scenario_pv_subsidy.csv \
  --plot
```

---

## License

This repository inherits the license of the original model.

**Creative Commons Attribution 4.0 International (CC BY 4.0)**

You are free to share and adapt this material for any purpose, including commercially, as long as you give appropriate credit to the original authors, provide a link to the license, and indicate if changes were made.

See [`LICENSE`](LICENSE) for the full license text, or visit https://creativecommons.org/licenses/by/4.0/

---

## Original model

The original NetLogo model and survey data are available at:
https://doi.org/10.5281/zenodo.13364990

---

## Citation

If you use this Python port, please cite the original paper:

```bibtex
@article{vanderkam2024,
  title   = {An empirical agent-based model of consumer co-adoption of
             low-carbon technologies to inform energy policy},
  author  = {van der Kam, Mart and Lagomarsino, Maria and Azar, Elie and
             Hahnel, Ulf J.J. and Parra, David},
  journal = {Cell Reports Sustainability},
  volume  = {1},
  pages   = {100268},
  year    = {2024},
  doi     = {10.1016/j.crsus.2024.100268}
}
```

---

## Conversion notes

The NetLogo-to-Python conversion was performed by **Claude Sonnet 4.6** (`claude-sonnet-4-6`, Anthropic) in June 2025. Key translation decisions:

- NetLogo `breeds` → Python classes (`House`, `Person`, `Simulation`)
- NetLogo `turtles-own` / `patches-own` → dataclass fields
- NetLogo `link-neighbors` social network → each `Person` holds a `neighbours` list built from K-nearest agents by survey index order
- NetLogo `rnd` / `csv` extensions → `random` / `pandas`
- NetLogo GUI sliders → `Config` dataclass with CLI overrides via `argparse`
- All 14 policy dimensions from the paper are implemented as binary toggles in `make_figures.py`
