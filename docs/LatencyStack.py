# AI/Steen python code : 
# Stacked contribution bar chart showing latency contribution per memory level

import matplotlib.pyplot as plt

# Latencies in ns
latencies = {
    "L1": 1.0,
    "L2": 4.0,
    "L3": 12.0,
    "Near": 80.0,
    "Far": 500.0
}

# Workload hit probabilities
workloads = {
    "Core-Intensive\n(Cache-Friendly)": {
        "L1": 0.90,
        "L2": 0.07,
        "L3": 0.02,
        "Near": 0.01,
        "Far": 0.00
    },
    "Memory-Heavy\n(Database / KV)": {
        "L1": 0.30,
        "L2": 0.20,
        "L3": 0.20,
        "Near": 0.25,
        "Far": 0.05
    }
}

levels = list(latencies.keys())
workload_names = list(workloads.keys())

# Compute contribution (probability * latency)
contributions = {
    wl: [workloads[wl][lvl] * latencies[lvl] for lvl in levels]
    for wl in workload_names
}

# Plot stacked bars
plt.figure()
bottom = [0] * len(workload_names)

for i, lvl in enumerate(levels):
    values = [contributions[wl][i] for wl in workload_names]
    plt.bar(workload_names, values, bottom=bottom, label=lvl)
    bottom = [bottom[j] + values[j] for j in range(len(values))]

plt.ylabel("Average Read Latency Contribution (ns)")
plt.title("Stacked Latency Contributions by Memory Level")
plt.yscale("log")
plt.legend()
plt.tight_layout()
plt.show()

