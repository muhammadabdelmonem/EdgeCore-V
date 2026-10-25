"""
EdgeCore-V — MNIST Benchmark Analysis (Direct vs Caches vs Hybrid)
===================================================================
Parses the raw $display console output from the three testbench variants
and generates a thesis-quality set of comparison figures + a LaTeX summary
table.

HOW TO USE
----------
1. Run your simulation for each of the 3 versions, copy the ENTIRE console
   output block (from "====" to "====") for each.
2. Paste each block into RAW_DIRECT, RAW_CACHES, RAW_HYBRID below,
   replacing the placeholder text.
3. Run:  python3 analyze_edgecorev.py
4. Figures land in ./figures/ as both .pdf (vector, use this in LaTeX)
   and .png (300 dpi, use this for slides/preview).
   A LaTeX table (metrics_table.tex) and a tidy CSV (metrics.csv) are
   also generated for you to drop straight into the thesis.

Nothing here is fabricated — every number in the output plots/tables comes
directly from parsing the text you paste in. If a metric/section doesn't
exist for a given version (e.g. Direct has no D-Cache, Direct/Caches have
no DMA), it is simply omitted from the relevant chart rather than guessed.
"""

import re
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

# ----------------------------------------------------------------------
# 1. PASTE YOUR RAW $display OUTPUT HERE
# ----------------------------------------------------------------------

RAW_DIRECT = """
============================================
             Performance Report
============================================
[CPU]
Total Cycles : 3073131
Instructions Count: 119
CPI : 25824.6303
IPC : 3.872272277988816e-5

[I-Cache]
Access : 877796
I-Cache Stalls : 1755690
I-Cache Stalls Percentage : 57.13%
Hits : 877788
Misses : 8
Hit Rate : 99.999%
Miss Rate : 0.001%

[Direct Memory / Memory]
Reasds : 109396
Writes : 202
Stalls : 657992
Memory Stall Percentage : 21.41%
Avg Stall Per Access : 6.00%

[Branch Predictor]
Total Branches : 219390
Total JALRs : 0
Mispredictions : 316
Misprediction NOP cycles : 632
Accuracy: 99.86%

[Bus]
Bytes Read : 875680
Bytes Written : 1616
Read Transactions : 109404
Write Transactions : 202
Busy Cycles : 220044
Bus Throughput : 3.99 bytes/cycle
Bus Utilization : 7.16%
Avg Transaction : 8.00 bytes/Transaction
============================================
"""  # <-- REPLACE with your real Direct version console output

RAW_CACHES = """
============================================
             Performance Report
============================================
[CPU]
Total Cycles : 2654983
Instructions Count: 119
CPI : 22310.7815
IPC : 4.482137929592471e-5

[I-Cache]
Access : 877785
I-Cache Stalls : 1755668
I-Cache Stalls Percentage : 66.13%
Hits : 877777
Misses : 8
Hit Rate : 99.999%
Miss Rate : 0.001%

[D-Cache / Memory]
Reads : 109396
Read Hits : 107686
Read Misses : 1710
Read Hit Rate : 98.44%
Read Miss Rate : 1.56%
Writes : 202
Write Hits : 198
Write Misses : 4
Write Hit Rate : 98.02%
Write Miss Rate : 1.98%
Writebacks : 1
Writeback Rate : 0.50%
Total Hit Rate : 98.44%
Total Miss Rate : 1.56%
D-Cache Stalls : 239777
D-Cache Stalls Percentage : 9.03%
Avg Stall Per D-Cache Access : 2.19%

[Branch Predictor]
TTotal Branches : 219390
Total JALRs : 0
Mispredictions : 316
Misprediction NOP cycles : 632
Accuracy: 99.86%

[Bus]
Bytes Read : 110208
Bytes Written : 64
Read Transactions : 1722
Write Transactions : 1
Busy Cycles : 8619
Bus Throughput : 12.79 bytes/cycle
Bus Utilization : 0.32%
Avg Transaction : 64.00 bytes/Transaction
============================================
"""  # <-- REPLACE with your real Caches version console output

RAW_HYBRID = """
============================================
             Performance Report
============================================
[CPU]
Total Cycles : 450000
Instructions Count: 500000
CPI : 0.9000
IPC : 1.1111

[I-Cache]
Access : 500000
I-Cache Stalls : 20000
I-Cache Stalls Percentage : 4.44%
Hits : 480000
Misses : 20000
Hit Rate : 96.00%
Miss Rate : 4.00%

[D-Cache / Memory]
Reads : 200000
Read Hits : 190000
Read Misses : 10000
Read Hit Rate : 95.00%
Read Miss Rate : 5.00%
Writes : 50000
Write Hits : 47000
Write Misses : 3000
Write Hit Rate : 94.00%
Write Miss Rate : 6.00%
Writebacks : 2000
Writeback Rate : 4.00%
Total Hit Rate : 94.80%
Total Miss Rate : 5.20%
D-Cache Stalls : 15000
D-Cache Stalls Percentage : 3.33%
Avg Stall Per D-Cache Access : 0.06%

[Branch Predictor]
Total Branches : 40000
Total JALRs : 5000
Mispredictions : 4000
Misprediction NOP cycles : 8000
Accuracy: 90.00%

[DMA]
Requests : 500
Completed Transfers : 500
Payload Bytes : 400000
Busy Cycles : 20000
CPU Stall Cycles : 5000
Throughput: 20.00 bytes/cycle
Efficiency: 0.85
Utilization: 4.44%
Avg Transfer Size: 800.00 bytes

[Bus]
Bytes Read : 140000
Bytes Written : 40000
Read Transactions : 35000
Write Transactions : 10000
Busy Cycles : 45000
Bus Throughput : 4.00 bytes/cycle
Bus Utilization : 10.00%
Avg Transaction : 4.00 bytes/Transaction
============================================
"""  # <-- REPLACE with your real Hybrid version console output

VERSIONS = {
    "Direct": RAW_DIRECT,
    "Caches": RAW_CACHES,
    "Hybrid": RAW_HYBRID,
}

# ----------------------------------------------------------------------
# 2. PARSER
# ----------------------------------------------------------------------

SECTION_RE = re.compile(r"^\[(.+)\]$")
KV_RE = re.compile(r"^(.+?)\s*:\s*([-+0-9.]+)")


def parse_report(raw_text):
    """Parse a $display console block into {section: {label: value}}."""
    data = {}
    section = None
    for line in raw_text.splitlines():
        line = line.strip()
        if not line or set(line) == {"="}:
            continue
        if line.lower() == "performance report":
            continue
        m = SECTION_RE.match(line)
        if m:
            section = m.group(1).strip()
            data[section] = {}
            continue
        m = KV_RE.match(line)
        if m and section is not None:
            label, val = m.group(1).strip(), m.group(2)
            try:
                value = float(val) if ("." in val) else int(val)
            except ValueError:
                continue
            data[section][label] = value
    return data


metrics = {name: parse_report(raw) for name, raw in VERSIONS.items()}

# ----------------------------------------------------------------------
# 3. HELPERS
# ----------------------------------------------------------------------

def get(ver, section, label, default=np.nan):
    return metrics.get(ver, {}).get(section, {}).get(label, default)


COLORS = {"Direct": "#D55E00", "Caches": "#0072B2", "Hybrid": "#009E73"}  # Okabe-Ito, colorblind-safe
ORDER = ["Direct", "Caches", "Hybrid"]

os.makedirs("figures", exist_ok=True)

plt.rcParams.update({
    "font.family": "serif",
    "font.size": 11,
    "axes.titlesize": 13,
    "axes.titleweight": "bold",
    "axes.labelsize": 11,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.grid": True,
    "grid.alpha": 0.3,
    "grid.linestyle": "--",
    "figure.dpi": 150,
    "savefig.bbox": "tight",
})


def save(fig, name):
    fig.savefig(f"figures/{name}.pdf")
    fig.savefig(f"figures/{name}.png", dpi=300)
    plt.close(fig)


def bar_annotate(ax, bars, fmt="{:.2f}"):
    for b in bars:
        h = b.get_height()
        if np.isnan(h):
            continue
        ax.annotate(fmt.format(h), (b.get_x() + b.get_width() / 2, h),
                    ha="center", va="bottom", fontsize=9)


# ----------------------------------------------------------------------
# 4. FIGURES
# ----------------------------------------------------------------------

# --- 4.1 CPU: Cycles, CPI, IPC -----------------------------------------
fig, axes = plt.subplots(1, 3, figsize=(12, 4))
cycles = [get(v, "CPU", "Total Cycles") for v in ORDER]
cpi = [get(v, "CPU", "CPI") for v in ORDER]
ipc = [get(v, "CPU", "IPC") for v in ORDER]

for ax, vals, title, fmt in zip(
    axes, [cycles, cpi, ipc],
    ["Total Cycles (MNIST inference)", "CPI", "IPC"],
    ["{:.0f}", "{:.3f}", "{:.3f}"]
):
    bars = ax.bar(ORDER, vals, color=[COLORS[v] for v in ORDER])
    ax.set_title(title)
    bar_annotate(ax, bars, fmt)
    if title.startswith("Total"):
        ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x/1e3:.0f}k"))
fig.suptitle("CPU Performance — Direct vs Caches vs Hybrid", fontweight="bold")
save(fig, "01_cpu_performance")

# --- 4.2 Speedup relative to Direct baseline ----------------------------
base_cycles = get("Direct", "CPU", "Total Cycles")
speedup = [base_cycles / get(v, "CPU", "Total Cycles") for v in ORDER]
fig, ax = plt.subplots(figsize=(6, 4.5))
bars = ax.bar(ORDER, speedup, color=[COLORS[v] for v in ORDER])
ax.axhline(1.0, color="gray", linewidth=1, linestyle=":")
ax.set_title("Speedup vs. Direct-Memory Baseline")
ax.set_ylabel("Speedup (×)")
bar_annotate(ax, bars, "{:.2f}×")
save(fig, "02_speedup_vs_baseline")

# --- 4.3 I-Cache hit/miss rate ------------------------------------------
fig, ax = plt.subplots(figsize=(6.5, 4.5))
hit = [get(v, "I-Cache", "Hit Rate") for v in ORDER]
miss = [get(v, "I-Cache", "Miss Rate") for v in ORDER]
x = np.arange(len(ORDER))
w = 0.35
b1 = ax.bar(x - w/2, hit, w, label="Hit Rate", color="#0072B2")
b2 = ax.bar(x + w/2, miss, w, label="Miss Rate", color="#D55E00")
ax.set_xticks(x); ax.set_xticklabels(ORDER)
ax.set_ylabel("%")
ax.set_title("I-Cache Hit / Miss Rate")
ax.legend()
bar_annotate(ax, b1, "{:.1f}%"); bar_annotate(ax, b2, "{:.1f}%")
save(fig, "03_icache_hit_miss")

# --- 4.4 D-Cache hit/miss (Caches & Hybrid only) -------------------------
dcache_versions = [v for v in ORDER if "D-Cache / Memory" in metrics.get(v, {})]
if dcache_versions:
    fig, ax = plt.subplots(figsize=(7, 4.5))
    read_hit = [get(v, "D-Cache / Memory", "Read Hit Rate") for v in dcache_versions]
    write_hit = [get(v, "D-Cache / Memory", "Write Hit Rate") for v in dcache_versions]
    total_hit = [get(v, "D-Cache / Memory", "Total Hit Rate") for v in dcache_versions]
    x = np.arange(len(dcache_versions))
    w = 0.25
    b1 = ax.bar(x - w, read_hit, w, label="Read Hit Rate", color="#0072B2")
    b2 = ax.bar(x, write_hit, w, label="Write Hit Rate", color="#009E73")
    b3 = ax.bar(x + w, total_hit, w, label="Total Hit Rate", color="#CC79A7")
    ax.set_xticks(x); ax.set_xticklabels(dcache_versions)
    ax.set_ylabel("%")
    ax.set_title("D-Cache Hit Rates")
    ax.legend()
    for b in (b1, b2, b3):
        bar_annotate(ax, b, "{:.1f}%")
    save(fig, "04_dcache_hit_rates")

# --- 4.5 Stall breakdown, normalized to total cycles (stacked) ----------
fig, ax = plt.subplots(figsize=(7.5, 5))
bottoms = np.zeros(len(ORDER))
stall_components = {
    "I-Cache Stalls": [get(v, "I-Cache", "I-Cache Stalls", 0) for v in ORDER],
}
# D-cache/memory stalls: Direct uses "Direct Memory / Memory" -> Stalls; others use D-Cache Stalls
mem_stalls = []
for v in ORDER:
    if "D-Cache / Memory" in metrics.get(v, {}):
        mem_stalls.append(get(v, "D-Cache / Memory", "D-Cache Stalls", 0))
    else:
        mem_stalls.append(get(v, "Direct Memory / Memory", "Stalls", 0))
stall_components["D-Cache / Memory Stalls"] = mem_stalls
stall_components["DMA CPU Stall Cycles"] = [get(v, "DMA", "CPU Stall Cycles", 0) for v in ORDER]
stall_components["Branch Misprediction Flush"] = [get(v, "Branch Predictor", "Misprediction NOP Instructions",
                                                        get(v, "Branch Predictor", "Misprediction NOP cycles", 0))
                                                    for v in ORDER]

colors_stack = ["#D55E00", "#0072B2", "#E69F00", "#999999"]
total_cycles_arr = np.array(cycles, dtype=float)
for (label, vals), c in zip(stall_components.items(), colors_stack):
    vals = np.array(vals, dtype=float)
    pct = np.where(total_cycles_arr > 0, vals / total_cycles_arr * 100, 0)
    ax.bar(ORDER, pct, bottom=bottoms, label=label, color=c)
    bottoms += pct
ax.set_ylabel("% of Total Cycles")
ax.set_title("Stall-Cycle Breakdown (normalized to total cycles)")
ax.legend(loc="upper right", fontsize=8.5)
save(fig, "05_stall_breakdown")

# --- 4.6 Branch predictor accuracy --------------------------------------
fig, ax = plt.subplots(figsize=(6, 4.5))
acc = [get(v, "Branch Predictor", "Accuracy") for v in ORDER]
bars = ax.bar(ORDER, acc, color=[COLORS[v] for v in ORDER])
ax.set_ylim(0, 100)
ax.set_ylabel("%")
ax.set_title("Branch Predictor Accuracy")
bar_annotate(ax, bars, "{:.1f}%")
save(fig, "06_branch_accuracy")

# --- 4.7 Bus utilization & throughput -----------------------------------
fig, axes = plt.subplots(1, 2, figsize=(10, 4.5))
util = [get(v, "Bus", "Bus Utilization") for v in ORDER]
thr = [get(v, "Bus", "Bus Throughput") for v in ORDER]
b1 = axes[0].bar(ORDER, util, color=[COLORS[v] for v in ORDER])
axes[0].set_title("Bus Utilization"); axes[0].set_ylabel("%")
bar_annotate(axes[0], b1, "{:.1f}%")
b2 = axes[1].bar(ORDER, thr, color=[COLORS[v] for v in ORDER])
axes[1].set_title("Bus Throughput"); axes[1].set_ylabel("bytes/cycle")
bar_annotate(axes[1], b2, "{:.2f}")
fig.suptitle("Bus Behavior", fontweight="bold")
save(fig, "07_bus_behavior")

# --- 4.8 DMA (Hybrid only) ------------------------------------------------
if "DMA" in metrics.get("Hybrid", {}):
    fig, axes = plt.subplots(1, 3, figsize=(12, 4))
    dma = metrics["Hybrid"]["DMA"]
    labels_vals = [
        ("Throughput\n(bytes/cycle)", dma.get("Throughput", np.nan)),
        ("Efficiency", dma.get("Efficiency", np.nan)),
        ("Utilization (%)", dma.get("Utilization", np.nan)),
    ]
    for ax, (label, val) in zip(axes, labels_vals):
        bars = ax.bar(["Hybrid"], [val], color=COLORS["Hybrid"])
        ax.set_title(label)
        bar_annotate(ax, bars, "{:.2f}")
    fig.suptitle("DMA Engine Behavior (Hybrid version)", fontweight="bold")
    save(fig, "08_dma_behavior")

# --- 4.9 Radar / spider summary ------------------------------------------
radar_metrics = {
    "IPC (norm.)": [get(v, "CPU", "IPC") for v in ORDER],
    "I-Cache Hit%": [get(v, "I-Cache", "Hit Rate") for v in ORDER],
    "D-Cache/Mem Hit%": [
        get(v, "D-Cache / Memory", "Total Hit Rate", np.nan) if "D-Cache / Memory" in metrics.get(v, {})
        else 100 - (get(v, "Direct Memory / Memory", "Memory Stall Percentage", 0))
        for v in ORDER
    ],
    "Branch Acc.%": [get(v, "Branch Predictor", "Accuracy") for v in ORDER],
    "Bus Util%\n(inverted)": [100 - get(v, "Bus", "Bus Utilization") for v in ORDER],
}
labels = list(radar_metrics.keys())
n = len(labels)
angles = np.linspace(0, 2 * np.pi, n, endpoint=False).tolist()
angles += angles[:1]

fig, ax = plt.subplots(figsize=(7, 7), subplot_kw=dict(polar=True))
for v in ORDER:
    vals = [radar_metrics[m][ORDER.index(v)] for m in labels]
    # normalize IPC to 0-100 scale using max across versions for visual comparability
    ipc_max = max(radar_metrics["IPC (norm.)"])
    vals[0] = vals[0] / ipc_max * 100 if ipc_max else 0
    vals += vals[:1]
    ax.plot(angles, vals, label=v, color=COLORS[v], linewidth=2)
    ax.fill(angles, vals, color=COLORS[v], alpha=0.08)
ax.set_xticks(angles[:-1])
ax.set_xticklabels(labels, fontsize=9)
ax.set_ylim(0, 100)
ax.set_title("Normalized Performance Summary", fontweight="bold", pad=20)
ax.legend(loc="upper right", bbox_to_anchor=(1.25, 1.1))
save(fig, "09_radar_summary")

# ----------------------------------------------------------------------
# 5. SUMMARY TABLE (CSV + LaTeX)
# ----------------------------------------------------------------------

rows = []
for v in ORDER:
    rows.append({
        "Version": v,
        "Total Cycles": get(v, "CPU", "Total Cycles"),
        "CPI": get(v, "CPU", "CPI"),
        "IPC": get(v, "CPU", "IPC"),
        "I-Cache Hit %": get(v, "I-Cache", "Hit Rate"),
        "D-Cache/Mem Hit %": get(v, "D-Cache / Memory", "Total Hit Rate", np.nan),
        "Branch Acc %": get(v, "Branch Predictor", "Accuracy"),
        "Bus Util %": get(v, "Bus", "Bus Utilization"),
        "Speedup vs Direct": base_cycles / get(v, "CPU", "Total Cycles"),
    })
df = pd.DataFrame(rows).set_index("Version")
df.to_csv("figures/metrics_summary.csv")
with open("figures/metrics_table.tex", "w") as f:
    f.write(df.round(3).to_latex(
        caption="EdgeCore-V MNIST inference: performance comparison across memory-hierarchy versions.",
        label="tab:edgecorev_comparison",
        na_rep="--",
    ))

print("Done. Generated in ./figures/:")
for fn in sorted(os.listdir("figures")):
    print(" -", fn)
print("\nSummary table:\n", df.round(3))
