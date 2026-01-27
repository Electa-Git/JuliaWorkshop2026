import matplotlib.pyplot as plt
import pandas as pd

df = pd.read_csv("result.csv")
df.plot(x="time", xlabel="time [s]")
plt.savefig("plot.png")
