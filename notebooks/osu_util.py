import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter

def read_osu_log(filename, skiprows=3):
    """Read OSU micro-benchmark log as pandas series.

    filename : str
    skiprows : int, Use 3 for bcast and 2 for bw/latency.
    """
    df = pd.read_csv(
        filename, index_col=0, squeeze=True, names=['size', None],
        delim_whitespace=True, skiprows=skiprows, header=None
    )
    return df


def read_osu_log_multi(filename_list, columns=None, **kwargs):
    """Read multiple OSU micro-benchmark logs as pandas dataframe.

    filename_list : list of str
    """
    df_list = []
    for filename in filename_list:
        df_list.append(read_osu_log(filename, **kwargs))

    df_all = pd.concat(df_list, axis=1, keys=columns)

    return df_all


def plot_osu(df, ax=None, x_start=0, x_freq=4, **kwargs):
    """Standard OSU plot

    df : pandas series or dataframe
    """
    if ax is None:
        fig, ax = plt.subplots(1, 1, figsize=[6, 4])
    df.plot(ax=ax, marker='o', logx=True, xticks=df.index[x_start::x_freq], grid=True, **kwargs)
    ax.xaxis.set_major_formatter(ScalarFormatter())
    ax.minorticks_off()
    ax.set_xlabel('Message Size (Bytes)')
