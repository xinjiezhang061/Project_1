# GPU Command Processor Verification Project

This project demonstrates a small, portfolio-ready verification environment for a GPU command processor.

The design accepts 32-bit command words through a ready/valid interface and updates a small set of GPU-style registers:

- `SET_STATE`: update a state register
- `DRAW`: emit a draw event with vertex count and instance count
- `BARRIER`: emit a completion event
- invalid opcodes: raise an error without changing state

The testbench includes a constrained-random command stream, a reference model, a scoreboard, functional coverage counters, reset testing, malformed-command testing, and a Python regression wrapper.

## Repository layout

```text
rtl/command_processor.sv   synthesizable DUT
tb/tb_command_processor.sv self-checking SystemVerilog testbench
scripts/run_regression.py  simulator discovery and regression summary
Makefile                   one-command entry point
```

## Run

The testbench is compatible with common event-driven simulators. With Icarus Verilog installed:

```bash
make
```

Or run the Python wrapper directly:

```bash
python3 scripts/run_regression.py
```

The wrapper looks for `iverilog`/`vvp`, then prints a clear message if no simulator is installed. The intended verification flow is deliberately simple enough to inspect, while demonstrating the same thinking used in a larger UVM environment: transactions, a predictor/reference model, checking, coverage, and regression automation.

## Verification strategy

The testbench drives legal and illegal commands, including zero-count draws, maximum-width fields, back-to-back commands, reset during idle, and reset between transactions. A reference model predicts state, draw events, barrier events, and error responses. Every response is checked cycle-by-cycle. Coverage counters track opcode classes, legal/illegal commands, zero-count draws, maximum-count draws, and reset recovery.

## Next steps

Natural extensions would be replacing the procedural testbench with UVM components, adding an AXI-stream adapter, introducing command FIFO backpressure, and connecting the command processor to a rasterisation or memory-subsystem model.
