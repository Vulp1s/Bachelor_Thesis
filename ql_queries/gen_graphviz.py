import re

# 1. Read the raw text file
with open('all_function_calls.txt', 'r') as f:
    content = f.read()

# 2. Clean out the annotations safely
clean_content = re.sub(r'\\', '', content)

# 3. Normalize whitespace: replace all newlines/tabs with a single space.
# This prevents rows that were split across multiple lines from breaking the parser.
normalized = re.sub(r'\s+', ' ', clean_content)

# 4. Split strictly by the pipe '|' character
parts = [p.strip() for p in normalized.split('|')]

# If the first element is empty (due to a leading '|'), drop it
if parts and parts[0] == '':
    parts = parts[1:]

# 5. Extract fields in chunks of 4 (scope, caller, called, file)
rows = []
for i in range(0, len(parts) - 3, 4):
    scope = parts[i]
    caller = parts[i+1]
    called = parts[i+2]
    filename = parts[i+3]
    
    # Ignore table headers and divider grids
    if 'scope' in scope or '---' in scope or not scope:
        continue
        
    rows.append((scope, caller, called, filename))

# 6. Filter and group data
driver_nodes = set()
subsystem_nodes = set()
edges = []

# Core kernel functions or helpers to discard entirely from target destinations
kernel_helpers = {
    'dma_alloc_coherent', '_printk', 'readl', 'writel', 'sized_strscpy', 
    'video_drvdata', 'spinlock_check', 'list_empty', '__raw_spin_lock_irqsave',
    'clamp', 'round_power_of_two'
}

for scope, caller, called, filename in rows:
    # Rule 1: Completely discard edges from 3_kernel scope
    if scope == '3_kernel':
        continue
        
    # Rule 2: Discard edges going directly to low-level kernel helper primitives or compiler asserts
    if called in kernel_helpers or called.startswith('__compiletime_assert'):
        continue

    # Allocate nodes into their respective visibility scopes
    if scope == '1_Driver':
        driver_nodes.add(caller)
        driver_nodes.add(called)
    elif scope == '2_Subsystem':
        subsystem_nodes.add(caller)
        subsystem_nodes.add(called)
        
    edges.append((caller, called))

# Helper to format node properties and highlight IOCTLs
def format_node(node_name):
    if node_name.startswith('vidioc_'):
        # Style IOCTL handlers with an orange tint to stand out
        return f'    "{node_name}" [style=filled, fillcolor="#ffe6cc", color="#ff6600", penwidth=2];\n'
    return f'    "{node_name}";\n'

# 7. Generate Graphviz DOT Syntax
dot_output = [
    'digraph G {\n',
    '    rankdir=LR;\n',
    '    node [shape=box, fontname="Courier", fontsize=10];\n',
    '    compound=true;\n\n'
]

# Write Cluster for 1_Driver
dot_output.append('    subgraph cluster_1_Driver {\n')
dot_output.append('        label="1_Driver Scope";\n')
dot_output.append('        color=blue;\n')
dot_output.append('        style=dashed;\n')
for node in sorted(driver_nodes):
    dot_output.append(format_node(node))
dot_output.append('    }\n\n')

# Write Cluster for 2_Subsystem
dot_output.append('    subgraph cluster_2_Subsystem {\n')
dot_output.append('        label="2_Subsystem Scope";\n')
dot_output.append('        color=darkgreen;\n')
dot_output.append('        style=dashed;\n')
for node in sorted(subsystem_nodes):
    # Prevent duplicate definitions if a node overlaps bounds
    if node not in driver_nodes:
        dot_output.append(format_node(node))
dot_output.append('    }\n\n')

# Write Unique Edges
dot_output.append('    # Call Graph Edges\n')
for caller, called in sorted(set(edges)):
    dot_output.append(f'    "{caller}" -> "{called}";\n')

dot_output.append('}\n')

# 8. Save the final map to file
with open('calls_graph.dot', 'w') as f:
    f.writelines(dot_output)

print("Successfully compiled clean 'calls_graph.dot' graph mapping!")
