import pandas as pd
import matplotlib.pyplot as plt

# 1. Load the CSV (replace with your actual filename)
df = pd.read_csv("recursive_function_calls_numioctl.csv")

# 2. Keep only the top 15 functions so the graph isn't cluttered
top_funcs = df.head(15).copy()

# Sort ascending so the largest bar ends up at the top of the chart
top_funcs = top_funcs.sort_values(by="unique_ioctls_calling_this", ascending=True)

# 3. Set up the plot
plt.figure(figsize=(10, 6))
bars = plt.barh(top_funcs["target_function"], top_funcs["unique_ioctls_calling_this"], color="steelblue")

# 4. Add formatting and labels
plt.title("Most Heavily Relied-Upon Target Functions", fontsize=14, pad=15)
plt.xlabel("Number of Unique Calling Ioctls", fontsize=12)
plt.ylabel("Target Function", fontsize=12)

# Add the exact numbers to the end of each bar
for bar in bars:
    plt.text(bar.get_width() + 0.1, bar.get_y() + bar.get_height()/2, 
             f'{int(bar.get_width())}', 
             va='center', ha='left', fontsize=10)

plt.tight_layout()

# 5. Save the graph as a high-res image for your thesis
plt.savefig("utility_functions_chart.png", dpi=300)
print("Saved utility_functions_chart.png")
