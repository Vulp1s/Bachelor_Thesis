# Analyzing the Hantro VPU Driver 

> Bachelor Thesis · ETH Zurich · 2026  
> Static and dynamic analysis of the Linux Hantro VPU driver on the Rockchip RK3588 SoC,

## Motivation

Extracting hardware drivers from the Linux kernel requires a precise understanding of which kernel subsystems the driver actually depends on at runtime. 

This project takes a finer-grained approach: tracing the **exact kernel call paths triggered
by each ioctl** through the V4L2 → M2M → VB2 → Hantro stack, combining CodeQL static analysis
with eBPF/kprobe runtime confirmation to produce a minimal, verified dependency list.

---

## Target Hardware

| Component     | Details                                        |
|---------------|------------------------------------------------|
| SoC           | Rockchip RK3588                                |
| Board         | Radxa Rock 5B (aarch64, Debian 12)             |
| Driver        | Hantro VPU (`rockchip,rk3588-av1-vpu-dec`)    |
| Kernel        | OpenCCA 6.12 Linux Kernel      |
| Decode format | AV1 stateless (V4L2 Request API)               |

---

## Methodology

### 1 Manual analysis
Trace the call tree by manualy follwing the definitions, using lsp, starting from the "REQBUFS" Ioctl.

### 2 · Static analysis (CodeQL)

CodeQL queries trace the callchain and struct accesses from all Ioctls called by the decoding process.

### 3 · Dynamic confirmation (eBPF / kprobes)

Runtime instrumentation on the Rock 5B confirms and refines the static results.
Concretly the implementations of ops structs are being confirmed. Then unused and undefined functions can be filtered out.

## Results

Found Dependencies:
• 11 driver-implemented ioctls → entry points

• 10 ops struct implementations resolved & confirmed

• 13 cross-boundary dependency edges (DMA, MMIO, VB2, M2M, . . . )

• 34 kernel structs accessed across the boundary

Unused paths: 44 of 208 probed Functions
• unused VB2 buffer allocation

• Post-processor & Filmgrain

• Debug, Recovery, Control paths

[Thesis.pdf](./bachelor_thesis_till_begue.pdf)

## Status

Thesis Completed

- [x] AV1 hardware decode pipeline working on Rock 5B  
- [x] Initial manual call graph for `VIDIOC_REQBUFS` complete
- [x] Static traceing using a custom codeql libary
- [x] Dynamic validation using bpftrace
- [x] Write thesis
- [ ] clean up and refactor code

