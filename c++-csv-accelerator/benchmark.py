#!/usr/bin/env python3
"""
Benchmark: csv_accel (C++) vs pandas.read_csv()

Compares native C++ CSV parsing performance against pandas on the
sample HR dataset. Results are printed as a formatted table.

Usage:
    cd c++-csv-accelerator
    python benchmark.py

Prerequisites:
    - Build the C++ module first: mkdir build && cd build && cmake .. && make
    - Ensure csv_accel.*.so is importable (it'll be in build/)
"""

import sys
import time
import os

# Add build directory to path for the compiled module
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "build"))

import pandas as pd

# ─── Configuration ───────────────────────────────────────────────────────────

CSV_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "sample_hr.csv")
ITERATIONS = 100  # Number of iterations for timing stability


def benchmark_pandas(filepath: str, iterations: int) -> float:
    """Time pandas.read_csv() over N iterations. Returns average in seconds."""
    times = []
    for _ in range(iterations):
        start = time.perf_counter()
        _ = pd.read_csv(filepath)
        elapsed = time.perf_counter() - start
        times.append(elapsed)
    return sum(times) / len(times)


def benchmark_cpp(filepath: str, iterations: int) -> float:
    """Time csv_accel.read_csv() over N iterations. Returns average in seconds."""
    try:
        import csv_accel
    except ImportError:
        print("ERROR: csv_accel module not found.")
        print("Build it first: cd build && cmake .. && make")
        sys.exit(1)

    times = []
    for _ in range(iterations):
        start = time.perf_counter()
        _ = csv_accel.read_csv(filepath)
        elapsed = time.perf_counter() - start
        times.append(elapsed)
    return sum(times) / len(times)


def main():
    if not os.path.exists(CSV_PATH):
        print(f"ERROR: CSV file not found: {CSV_PATH}")
        sys.exit(1)

    # Get row count
    df = pd.read_csv(CSV_PATH)
    rows = len(df)
    cols = len(df.columns)

    print("=" * 60)
    print("  CSV ACCELERATOR BENCHMARK")
    print("=" * 60)
    print(f"  File:       {os.path.basename(CSV_PATH)}")
    print(f"  Rows:       {rows}")
    print(f"  Columns:    {cols}")
    print(f"  Iterations: {ITERATIONS}")
    print("-" * 60)

    # Run benchmarks
    t_pandas = benchmark_pandas(CSV_PATH, ITERATIONS)
    t_cpp = benchmark_cpp(CSV_PATH, ITERATIONS)

    ratio = t_pandas / t_cpp if t_cpp > 0 else float("inf")

    # Print results
    print(f"{'Method':<20} {'Avg Time (s)':<15} {'Speedup':<10}")
    print("-" * 45)
    print(f"{'pandas.read_csv()':<20} {t_pandas:<15.6f} {'1.0x':<10}")
    print(f"{'csv_accel (C++)':<20} {t_cpp:<15.6f} {f'{ratio:.1f}x':<10}")
    print("=" * 60)

    if ratio > 1.0:
        print(f"  ✅ C++ accelerator is {ratio:.1f}x faster than pandas")
    else:
        print(f"  ⚠️  pandas was faster (ratio: {ratio:.1f}x)")

    print()


if __name__ == "__main__":
    main()
