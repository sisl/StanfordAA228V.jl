# AA228V/CS238V: Validation of Safety-Critical Systems
[![website](https://img.shields.io/badge/website-stanford-b31b1b.svg)](https://aa228v.stanford.edu/)

<!-- Testing update -->

## Install Julia
**Requires Julia 1.11+**: https://julialang.org/downloads/

- Windows users:
    - `winget install julia -s msstore`
- Linux/macOS users:
    - `curl -fsSL https://install.julialang.org | sh`

This will give you the `julia` command in your terminal.

## Install Packages
1. Install `Pluto` and `PlutoUI`
    - Open `julia`
    - Go into `pkg` mode: `]`
    - Run: `add Pluto PlutoUI`
1. Clone this git repo:
    - Open a terminal and navigate to where you want the code to live.
    - Run: `git clone https://github.com/sisl/AA228V.jl`
    - Navigate to the code: `cd AA228V.jl`
    - Open Julia: `julia`
    - Open Julia's `pkg` mode: `]`
    - Add the `AA228V` package in `pkg` mode: `dev .`

## Update AA228V (if necessary)
- Open `julia` in a terminal.
- Open Julia's `pkg` mode: `]`
- In `pkg` mode, run: `up AA228V`

# Projects
- **[Project 0](./projects/project0)** — _A light-weight introduction to falsification._
- **[Project 1](./projects/project1)** — _TODO._
- **[Project 2](./projects/project2)** — _TODO._
- **[Project 3](./projects/project3)** — _TODO._
