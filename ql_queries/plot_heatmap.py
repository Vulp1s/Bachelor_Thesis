import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# 1. Load the CSV (replace with your actual filename)
df = pd.read_csv("recursive_function_calls.csv")

# 2. Pivot the data into a 2D matrix format
# Rows = ioctls, Columns = scope, Values = unique_functions_touched
matrix_df = df.pivot(index="ioctl", columns="scope", values="unique_functions_touched")

# Fill any missing data (NaN) with 0
matrix_df = matrix_df.fillna(0)

# Optional: Sort the matrix by the total number of functions touched so the busiest ioctls are at the top
matrix_df["Total"] = matrix_df.sum(axis=1)
matrix_df = matrix_df.sort_values(by="Total", ascending=False).drop(columns=["Total"])
print(matrix_df)
# 3. Set up the plot
plt.figure(figsize=(12, 10)) # Taller to accommodate the list of ioctls
sns.set_theme(font_scale=1.5)
# 4. Draw the Heatmap
sns.heatmap(matrix_df, 
            annot=True,       # Show the actual numbers in the squares
            fmt="g",          # Format numbers cleanly
            cmap="YlGnBu",    # Use a nice Yellow-Green-Blue color scale
            linewidths=0.5,   # Add gridlines
            cbar_kws={'label': 'Unique Functions Touched'})

plt.title("Ioctl Interaction by Architectural Layer", fontsize=24, pad=15)
plt.xlabel("Subsystem Scope", fontsize=20)
plt.ylabel("Entry Ioctl", fontsize=20)

plt.tight_layout()

# 5. Save the graph
plt.savefig("subsystem_coupling_heatmap.png", dpi=400)
print("Saved subsystem_coupling_heatmap.png")
