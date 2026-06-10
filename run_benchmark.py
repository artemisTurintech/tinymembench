"""
run_benchmark.py — tinymembench benchmark runner

Runs the compiled tinymembench binary NUMBER × REPEAT times,
parses bandwidth (MB/s) and latency (ns) from its output,
and reports mean ± std across trials.

JSON output (artemis_results.json): array of per-trial measurement objects.
"""

import timeit
import subprocess
import json
import re
import math

# ── Configuration ──────────────────────────────────────────────────────────────
NUMBER = 1   # calls per trial  (keep at 1; each full run takes several minutes)
REPEAT = 3   # number of independent trials

BINARY      = "./tinymembench.exe"
OUTPUT_FILE = "artemis_results.json"

# Block sizes (bytes) to surface as named latency columns
LATENCY_SIZES = [32_768, 524_288, 8_388_608, 67_108_864]  # ~32K / ~512K / ~8M / ~64M

# Bandwidth labels in tinymembench output → JSON key
BW_LABELS = {
    "standard memcpy":       "stdmemcpy_MBps",
    "standard memset":       "stdmemset_MBps",
    "SSE2 nontemporal fill": "sse2_nontemporal_fill_MBps",
    "C fill":                "c_fill_MBps",
    "SSE2 copy":             "sse2_copy_MBps",
}

# ── Parsers ────────────────────────────────────────────────────────────────────
_BW_RE  = re.compile(r"^\s{1,4}(.+?)\s*:\s*([\d.]+)\s*MB/s", re.MULTILINE)
_LAT_RE = re.compile(r"^\s+(\d+)\s*:\s*([\d.]+)\s*ns\s*/\s*([\d.]+)\s*ns", re.MULTILINE)


def _parse(stdout: str) -> dict:
    row: dict = {}

    bw = {m.group(1).strip(): float(m.group(2)) for m in _BW_RE.finditer(stdout)}
    for label, key in BW_LABELS.items():
        if label in bw:
            row[key] = bw[label]

    lat = {
        int(m.group(1)): (float(m.group(2)), float(m.group(3)))
        for m in _LAT_RE.finditer(stdout)
    }
    for size in LATENCY_SIZES:
        if size in lat:
            kb = size // 1024
            tag = f"{kb}k" if kb < 1024 else f"{kb // 1024}m"
            row[f"latency_{tag}_single_ns"] = lat[size][0]
            row[f"latency_{tag}_dual_ns"]   = lat[size][1]

    return row


def _avg_rows(rows: list) -> dict:
    """Average numeric fields across multiple rows (used when NUMBER > 1)."""
    keys = {k for r in rows for k in r}
    result = {}
    for k in keys:
        vals = [r[k] for r in rows if k in r]
        result[k] = sum(vals) / len(vals) if vals else None
    return result


# ── Run benchmark ──────────────────────────────────────────────────────────────
_outputs: list = []


def _run() -> None:
    result = subprocess.run([BINARY], capture_output=True, text=True, check=True)
    _outputs.append(result.stdout)


print(f"tinymembench  |  number={NUMBER}, repeat={REPEAT}")
print("Running … (this may take several minutes per trial)\n")

trial_times = timeit.repeat(
    "_run()",
    globals={"_run": _run},
    number=NUMBER,
    repeat=REPEAT,
)
per_trial_s = [t / NUMBER for t in trial_times]

# Group outputs: REPEAT groups of NUMBER outputs each
trial_outputs = [_outputs[i * NUMBER : (i + 1) * NUMBER] for i in range(REPEAT)]

# ── Build per-trial measurement rows ──────────────────────────────────────────
measurements = []
for t_s, outputs in zip(per_trial_s, trial_outputs):
    parsed = [_parse(o) for o in outputs]
    row = _avg_rows(parsed) if len(parsed) > 1 else parsed[0]
    row["runtime_s"] = round(t_s, 3)
    measurements.append(row)

# ── Statistics ─────────────────────────────────────────────────────────────────
def _stats(values: list) -> tuple:
    n = len(values)
    mean = sum(values) / n
    std  = math.sqrt(sum((v - mean) ** 2 for v in values) / max(n - 1, 1))
    return mean, std


all_keys = list(measurements[0].keys())
summary  = {}
for key in all_keys:
    vals = [m[key] for m in measurements if key in m and m[key] is not None]
    if vals:
        mean, std = _stats(vals)
        summary[key] = {"mean": round(mean, 3), "std": round(std, 3)}

# ── Write JSON ─────────────────────────────────────────────────────────────────
with open(OUTPUT_FILE, "w") as f:
    json.dump(measurements, f, indent=2)

# ── Print summary ──────────────────────────────────────────────────────────────
COL = 36
SEP = "─" * 68
print(SEP)
print(f"  Config: number={NUMBER}, repeat={REPEAT}")
print(SEP)
for key, s in summary.items():
    if key.endswith("_MBps"):
        unit = "MB/s"
    elif key.endswith("_ns"):
        unit = "ns"
    else:
        unit = "s"
    print(f"  {key:<{COL}}  {s['mean']:>10.1f} ± {s['std']:>8.1f}  {unit}")
print(SEP)
print(f"  {len(measurements)} measurement(s) written to {OUTPUT_FILE}")
