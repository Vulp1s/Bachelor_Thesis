#!/usr/bin/env python3
"""
gen_bpf.py — bpftrace script generator

Usage:
  gen_bpf.py ops   <input>   Parse a multi-column ops-field table (original format)
  gen_bpf.py calls <input>   Parse a single-column called_func table (CodeQL output)

When no sub-command is given, 'ops' is assumed for backward compatibility.
"""

import sys


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

def get_traceable_functions(filepath="/sys/kernel/debug/tracing/available_filter_functions"):
    """Return the set of kprobe-attachable functions, or None if the file is absent."""
    traceable = set()
    try:
        with open(filepath, 'r') as f:
            for line in f:
                if line.strip():
                    # First word only — ignore trailing module annotations like [videobuf2_vmalloc]
                    traceable.add(line.split()[0])
        return traceable
    except PermissionError:
        print(f"// ERROR: Permission denied reading {filepath}.", file=sys.stderr)
        print("// Please run this script with sudo.", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"// WARNING: {filepath} not found. Assuming all functions are traceable.",
              file=sys.stderr)
        return None


def partition_by_traceability(func_names, traceable_funcs):
    """Split an iterable of function names into (valid, skipped) sets."""
    valid, skipped = set(), set()
    for fn in func_names:
        if traceable_funcs is not None and fn not in traceable_funcs:
            skipped.add(fn)
        else:
            valid.add(fn)
    return valid, skipped


def emit_header():
    print("#!/usr/bin/env bpftrace\n")


def emit_begin(msg="Tracing functions... Hit Ctrl-C to view counts."):
    print("BEGIN")
    print("{")
    print(f'    printf("{msg}\\n");')
    print("}\n")


# ---------------------------------------------------------------------------
# 'calls' mode  — single-column CodeQL output
# ---------------------------------------------------------------------------

def parse_calls_table(input_file):
    """
    Parse a CodeQL result table with a single 'called_func' column, e.g.:

        Running query: recursive_function_calls.ql on database ...
        |                  called_func                   |
        +------------------------------------------------+
        | __builtin_constant_p                           |
        | list_empty                                     |
        ...

    Returns a set of function names.
    """
    funcs = set()
    try:
        with open(input_file, 'r') as f:
            for line in f:
                line = line.strip()
                # Only data rows: start and end with '|', not the separator (+---+)
                if not (line.startswith('|') and line.endswith('|')):
                    continue
                value = line.strip('|').strip()
                # Skip the header row
                if value == 'called_func':
                    continue
                if value:
                    funcs.add(value)
    except FileNotFoundError:
        print(f"Error: Could not find file '{input_file}'", file=sys.stderr)
        sys.exit(1)
    return funcs


def generate_calls(input_file):
    funcs = parse_calls_table(input_file)
    if not funcs:
        print("// No functions found in input.", file=sys.stderr)
        sys.exit(1)

    traceable_funcs = get_traceable_functions()
    valid, skipped = partition_by_traceability(funcs, traceable_funcs)

    emit_header()

    if skipped:
        print("/*")
        print(" * SKIPPED FUNCTIONS")
        print(" * Not found in available_filter_functions; excluded to prevent attach errors:")
        print(" *")
        for fn in sorted(skipped):
            print(f" *   {fn}")
        print(" */\n")

    emit_begin()

    for fn in sorted(valid):
        print(f"kprobe:{fn}")
        print("{")
        print(f'    @calls["{fn}"] = count();')
        print("}\n")


# ---------------------------------------------------------------------------
# 'ops' mode  — original multi-column ops-field table
# ---------------------------------------------------------------------------

def parse_ops_table(input_file):
    """
    Parse the original multi-column table produced by the ops-field CodeQL query.
    Returns a set of (struct_name, field_name, func_name) triples.
    """
    implementations = set()
    try:
        with open(input_file, 'r') as f:
            for line in f:
                if not line.startswith('|'):
                    continue
                parts = [p.strip() for p in line.split('|')]
                if len(parts) < 7:
                    continue
                struct_name = parts[1]
                field_name  = parts[2]
                func_name   = parts[6]
                if struct_name == 'ops_struct':   # header row
                    continue
                if struct_name and field_name and func_name:
                    implementations.add((struct_name, field_name, func_name))
    except FileNotFoundError:
        print(f"Error: Could not find file '{input_file}'", file=sys.stderr)
        sys.exit(1)
    return implementations


def generate_ops(input_file):
    implementations = parse_ops_table(input_file)

    traceable_funcs = get_traceable_functions()

    valid, skipped_tuples = set(), set()
    for triple in implementations:
        struct_name, field_name, func_name = triple
        if traceable_funcs is not None and func_name not in traceable_funcs:
            skipped_tuples.add(triple)
        else:
            valid.add(triple)

    # Group valid entries by struct
    by_struct = {}
    for struct_name, field_name, func_name in valid:
        by_struct.setdefault(struct_name, []).append((field_name, func_name))

    emit_header()

    if skipped_tuples:
        print("/*")
        print(" * SKIPPED FUNCTIONS")
        print(" * Not found in available_filter_functions; excluded to prevent attach errors:")
        print(" *")
        for struct_name, field_name, func_name in sorted(skipped_tuples):
            print(f" *   {struct_name}->{field_name} calls {func_name}")
        print(" */\n")

    emit_begin("Tracing ops functions... Hit Ctrl-C to view counts.")

    for struct_name in sorted(by_struct.keys()):
        print(f"// {struct_name}:")
        for field_name, func_name in sorted(by_struct[struct_name]):
            print(f"kprobe:{func_name}")
            print("{")
            print(f'    @{struct_name}["{field_name} calls {func_name}"] = count();')
            print("}\n")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

USAGE = """\
Usage:
  gen_bpf.py ops   <input>   ops-field table (original multi-column format)
  gen_bpf.py calls <input>   called_func table (single-column CodeQL output)
  gen_bpf.py <input>         shorthand for 'ops' mode (backward compat)
"""

if __name__ == '__main__':
    args = sys.argv[1:]

    if not args:
        print(USAGE, file=sys.stderr)
        sys.exit(1)

    if args[0] in ('ops', 'calls'):
        mode = args[0]
        if len(args) < 2:
            print(f"Error: missing input file for '{mode}' mode.", file=sys.stderr)
            sys.exit(1)
        input_file = args[1]
    else:
        # backward-compat: no subcommand → ops mode
        mode = 'ops'
        input_file = args[0]

    if mode == 'calls':
        generate_calls(input_file)
    else:
        generate_ops(input_file)
