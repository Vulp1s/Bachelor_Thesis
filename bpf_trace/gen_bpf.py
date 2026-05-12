#!/usr/bin/env python3

import sys
import os


def get_traceable_functions(filepath="/sys/kernel/debug/tracing/available_filter_functions"):
    """Reads the kernel's available filter functions and returns them as a set."""
    traceable = set()
    try:
        with open(filepath, 'r') as f:
            for line in f:
                if line.strip():
                    # The function name is the first word on the line
                    # (ignoring module names like "[videobuf2_vmalloc]" that might follow)
                    func = line.split()[0]
                    traceable.add(func)
        return traceable
    except PermissionError:
        print(f"// ERROR: Permission denied reading {filepath}.", file=sys.stderr)
        print(f"// Please run this python script with sudo.", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"// WARNING: {filepath} not found. Assuming all are traceable.", file=sys.stderr)
        return None


def generate_bpftrace(input_file):
    implementations = set()

    # Parse the text file
    try:
        with open(input_file, 'r') as f:
            for line in f:
                if not line.startswith('|'):
                    continue
                
                parts = [p.strip() for p in line.split('|')]
                if len(parts) < 7:
                    continue
                
                struct_name = parts[1]
                field_name = parts[2]
                func_name = parts[6]
                
                # Skip header row
                if struct_name == 'ops_struct':
                    continue
                
                if struct_name and field_name and func_name:
                    implementations.add((struct_name, field_name, func_name))
                    
    except FileNotFoundError:
        print(f"Error: Could not find file '{input_file}'", file=sys.stderr)
        sys.exit(1)

    # Fetch traceable functions
    traceable_funcs = get_traceable_functions()
    
    valid_implementations = set()
    skipped_functions = set()

    # Filter out untraceable functions
    for struct_name, field_name, func_name in implementations:
        if traceable_funcs is not None and func_name not in traceable_funcs:
            skipped_functions.add((struct_name, field_name, func_name))
        else:
            valid_implementations.add((struct_name, field_name, func_name))

    # Group by struct
    by_struct = {}
    for struct_name, field_name, func_name in valid_implementations:
        if struct_name not in by_struct:
            by_struct[struct_name] = []
        by_struct[struct_name].append((field_name, func_name))

    # --- Generate the bpftrace script output ---
    print("#!/usr/bin/env bpftrace\n")
    
    # Print skipped functions as a comment block
    if skipped_functions:
        print("/*")
        print(" * SKIPPED FUNCTIONS")
        print(" * The following functions were not found in available_filter_functions")
        print(" * and have been excluded to prevent kprobe attach errors:")
        print(" *")
        for struct_name, field_name, func_name in sorted(skipped_functions):
            print(f" * - {struct_name}->{field_name} calls {func_name}")
        print(" */\n")

    print("BEGIN")
    print("{")
    print('    printf("Tracing ops functions... Hit Ctrl-C to view counts.\\n");')
    print("}\n")

    # Generate probes grouped by struct
    for struct_name in sorted(by_struct.keys()):
        print(f"// {struct_name}:")
        for field_name, func_name in sorted(by_struct[struct_name]):
            print(f"kprobe:{func_name}")
            print("{")
            print(f'    @{struct_name}["{field_name} calls    {func_name}"] = count();')
            print("}\n")


if __name__ == '__main__':
    filename = sys.argv[1] if len(sys.argv) > 1 else 'todo.txt'
    generate_bpftrace(filename)
