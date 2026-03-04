# 📊 CSV Accelerator Benchmark

Performance comparison between the native C++17 parser (`csv_accel`) and `pandas.read_csv()`.

## Methodology

- **Tool:** `benchmark.py` — runs 100 iterations per method using `time.perf_counter()`
- **Metric:** Average wall-clock time per read
- **Environment:** Single-threaded, cold cache on first run, warm on subsequent

## How to Reproduce

```bash
# 1. Build the C++ module
cd c++-csv-accelerator
mkdir -p build && cd build
cmake .. && make

# 2. Run the benchmark
cd ..
python benchmark.py
```

## Requirements

- Python 3.10+
- CMake ≥ 3.14
- pybind11 (`pip install pybind11`)
- g++ with C++17 support
- pandas

## Results (Local — Reference Only)

| Method | Avg Time (s) | Speedup |
|---|---|---|
| `pandas.read_csv()` | 0.113 | 1.0x |
| `csv_accel` (C++) | 0.039 | **~2.9x** |

> **Note:** Results will vary by hardware, file size, and system load.
> The speedup ratio increases with larger files due to reduced Python
> interpreter overhead.

## Architecture

```
csv_accel.cpp (C++17)
    ├── detail::parse_csv_line()  — RFC-aware field parsing with quote handling
    ├── detail::trim()            — Whitespace normalization
    ├── read_csv()                — Full parse → (header, rows)
    └── count_rows()              — Fast row counting without full parse
         │
         ▼
    pybind11 bindings
         │
         ▼
    Python: import csv_accel
```

## Why C++ Instead of Just pandas?

For People Analytics pipelines processing **large psychometric datasets** (n > 100K):
1. Python's GIL creates a hard ceiling on single-threaded I/O
2. `pandas.read_csv()` performs type inference on every read — expensive for staging
3. The C++ parser returns raw strings, deferring type casting to the SQL layer (where it belongs in an ELT architecture)

This design follows the **ELT principle**: extract raw → load fast → transform in SQL (dbt).
