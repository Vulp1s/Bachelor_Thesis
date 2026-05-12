# Hantro VPU Driver — Kernel Dependency Analysis

> Bachelor thesis · ETH Zurich · 2025  
> Static and dynamic analysis of the Linux Hantro VPU driver on the Rockchip RK3588 SoC,

## Motivation

Extracting hardware drivers from the Linux kernel for bare-metal or emulated environments
requires a precise understanding of which kernel subsystems the driver actually depends on at
runtime. 

This project takes a finer-grained approach: tracing the **exact kernel call paths triggered
by each ioctl** through the V4L2 → M2M → VB2 → Hantro stack, combining CodeQL static analysis
with eBPF/kprobe runtime confirmation to produce a minimal, verified dependency graph.

---

## Target Hardware

| Component     | Details                                        |
|---------------|------------------------------------------------|
| SoC           | Rockchip RK3588                                |
| Board         | Radxa Rock 5B (aarch64, Debian 12)             |
| Driver        | Hantro VPU (`rockchip,rk3588-av1-vpu-dec`)    |
| Kernel        | OpenCCA        |
| Decode format | AV1 stateless (V4L2 Request API)               |

---

## Methodology

### 1 Manual analysis
Trace the call tree by manualy follwing the definitions, using lsp, starting from the "REQBUFS" Ioctl.

### 2 · Static analysis (CodeQL)

CodeQL queries trace the callchain from a predefinded Ioctrl 

### 2 · Dynamic confirmation (eBPF / kprobes)

Runtime instrumentation on the Rock 5B confirms and refines the static results.
Concretly the implementations of ops structs are being confirmed. Then unused and undefined functions can be filtered out.

### 3 · Call graph visualisation

Use tool to visualize call tree


## Status

🚧 **Work in progress** — bachelor thesis ongoing.

- [x] AV1 hardware decode pipeline working on Rock 5B  
- [x] Initial manual call graph for `VIDIOC_REQBUFS` complete
- [x] CodeQL database built from kernel source
- [x] Recursive Queries
- [x] Add filter logic to queries
- [x] Add query to find structs not filtered yet
- [x] Improved ql queries 
- [x] BPF struct check
- [x] automate dynamic validation
- [ ] find driver structs modified by kernel

