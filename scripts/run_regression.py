#!/usr/bin/env python3
"""Small simulator-agnostic regression launcher for the portfolio project."""
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"

def main() -> int:
    iverilog = shutil.which("iverilog")
    vvp = shutil.which("vvp")
    if not iverilog or not vvp:
        print("No Icarus Verilog installation found.")
        print("Install iverilog, then rerun: python3 scripts/run_regression.py")
        return 2
    BUILD.mkdir(exist_ok=True)
    image = BUILD / "simv"
    compile_cmd = [iverilog, "-g2012", "-s", "tb_command_processor", "-o", str(image),
                   str(ROOT / "rtl/command_processor.sv"), str(ROOT / "tb/tb_command_processor.sv")]
    subprocess.run(compile_cmd, check=True)
    result = subprocess.run([vvp, str(image)], cwd=ROOT)
    return result.returncode

if __name__ == "__main__":
    sys.exit(main())
