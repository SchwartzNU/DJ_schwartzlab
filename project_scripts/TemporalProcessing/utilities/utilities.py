from utilities.setup_environment import *
def autocorr_coeff(x, lags):
    x = x - np.mean(x)  # Zero-center
    xcorr = np.correlate(x, x, mode="full") / (np.var(x) * len(x))  # Normalize by variance and length. Pearson corr
    xcorr = xcorr[xcorr.size // 2:]  # Keep only positive lags
    return xcorr[:lags+1]  
def downsample_vm(vm_responses, factor=10):
    """
    Downsamples voltage responses using anti-aliasing filtering.
    
    Parameters:
    - vm_responses: np.array, shape (num_trials, num_timepoints) - Raw Vm traces
    - factor: int, downsampling factor (default: 10 for 50 kHz → 10 kHz)
    
    Returns:
    - np.array, downsampled Vm responses
    """
    return np.array([decimate(trial, factor, ftype='iir') for trial in vm_responses])

def compute_psd_stats(row, fs=60, nperseg=None, eps=1e-10):
    stim = np.asarray(row['stimulus'])
    spikes = np.asarray(row['spike_train'])

    if nperseg is None:
        nperseg = fs * 2  # default: 2s window

    f_stim, Pxx_stim = welch(stim, fs=fs, nperseg=nperseg)
    f_spikes, Pxx_spikes = welch(spikes, fs=fs, nperseg=nperseg)

    # Avoid DC component (index 0)
    H_pxx = Pxx_spikes[1:] / (Pxx_stim[1:] + eps)
    H_mag = np.sqrt(H_pxx)


    return pd.Series({
        'freqs': f_stim[1:],  
        'Pxx_stim': Pxx_stim[1:],
        'Pxx_spikes': Pxx_spikes[1:],
        'H_f_mag': H_mag,
        'H_f_pxx': H_pxx
    })

def convert_stringified_arrays(df):
    converted_cols = []
    for col in df.columns:
        try:
            sample = df[col].dropna().iloc[0]
            if isinstance(sample, str):
                # Remove surrounding quotes and newlines
                sample_clean = sample.strip().strip('"').replace('\n', ' ')
                if re.match(r'^\[.*\]$', sample_clean):
                    df[col] = df[col].apply(lambda s: np.fromstring(s.strip().strip('"').strip('[]').replace('\n', ' '), sep=' '))
                    converted_cols.append(col)
        except Exception as e:
            print(f"Skipping column {col} due to error: {e}")
    if converted_cols:
        print("Converted the following columns to NumPy arrays:")
        for col in converted_cols:
            print(f"  - {col}")
    else:
        print("No stringified array columns found.")
    return df


