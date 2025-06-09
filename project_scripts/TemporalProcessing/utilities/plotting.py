import matplotlib.pyplot as plt
import matplotlib.cm as cm
import matplotlib.colors as mcolors
from mpl_toolkits.axes_grid1 import make_axes_locatable
import numpy as np


def plot_example_cell(cell_name, df_celltype):

    df_cell_results = df_celltype[df_celltype['cell_name'] == cell_name]
    frame_rate=60
    label_fontsize = 18
    beta_values = sorted(df_cell_results['beta'].unique())
    norm = mcolors.Normalize(vmin=min(beta_values), vmax=max(beta_values))
    cmap = plt.get_cmap('viridis')
    fig, axes = plt.subplots(1, 3, figsize=(13, 4), sharey=False)
    fig.suptitle(f"Results for cell {cell_name}, {df_cell_results['cell_type'].iloc[0]}", fontsize=16, y=1.03)
    axes[1].sharey(axes[0])
    for beta_value in beta_values:
        row = df_cell_results[df_cell_results['beta'] == beta_value].iloc[0]
        color = cmap(norm(beta_value))

        freqs = row['freq']
        stim_psd = row['stim_psd']
        rs_spikes_psd = row['nr_spikes_psd']
        H_f_power_rs = row['H_f_power_rs']

        # Stimulus PSD (normalized)
        axes[0].loglog(freqs[1:], stim_psd[1:] / np.trapz(stim_psd[1:], freqs[1:]),
                    label=fr"$\beta={beta_value}$", c=color)

        # Spike PSD (normalized)
        axes[1].loglog(freqs[1:], rs_spikes_psd[1:] / np.trapz(rs_spikes_psd[1:], freqs[1:]),
                    label=fr"$\beta={beta_value}$", c=color)

        # Gain |H(f)|² (already squared in this context)
        axes[2].loglog(freqs[1:], H_f_power_rs[1:], label=fr"$\beta={beta_value}$", c=color)

    # Labeling
    titles = ["Stimulus", "Spikes Power Spectrum", r"Estimated Filter $|H(f)|^2$"]
    ylabels = ["PSD norm", "PSD norm", "Gain"]
    for i, ax in enumerate(axes):
        ax.set_title(titles[i], fontsize=label_fontsize)
        ax.set_xlabel("Frequency (Hz)", fontsize=label_fontsize)
        ax.set_ylabel(ylabels[i], fontsize=label_fontsize)
        ax.axvline(frame_rate / 2, color='gray', linestyle='--')
        ax.grid(visible=False)

    # Shared legend
    handles, labels = axes[1].get_legend_handles_labels()
    fig.legend(handles, labels, loc='upper center', bbox_to_anchor=(0.5, .92),
            ncol=len(beta_values), fontsize=12)

    # Colorbar for beta
    sm = cm.ScalarMappable(cmap=cmap, norm=norm)
    sm.set_array([])
    divider = make_axes_locatable(axes[2])
    cax = divider.append_axes("right", size="6%", pad=0.05)
    cbar = plt.colorbar(sm, cax=cax)
    cbar.set_label(r'$\beta$', fontsize=16)

    plt.tight_layout()
    plt.show()

    return fig