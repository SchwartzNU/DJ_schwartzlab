import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import periodogram

def getStim(dataset):
    noiseGen = np.random.RandomState(seed=int(dataset.noise_seed))
    
    preFrames = int(dataset.frame_rate * dataset.pre_time / 1000)
    stimFrames = int(dataset.frame_rate * dataset.stim_time / 1000)
    tailFrames = int(dataset.frame_rate * dataset.tail_time / 1000)
    nFrames = stimFrames // int(dataset.frame_dwell)
    randVals = noiseGen.rand(nFrames, 2)
    randVals = np.sqrt(-2*np.log(randVals[:,0])) * np.cos(2*np.pi*randVals[:,1])

    contrast = randVals * dataset.contrast 
    luminance = dataset.spot_mean_level * (1 + contrast)

    if dataset.mean_level:
        contrast_c = (luminance - dataset.mean_level) / dataset.mean_level
        mean_c = (dataset.spot_mean_level - dataset.mean_level) / dataset.mean_level
    else:
        contrast_c = luminance
        mean_c = dataset.spot_mean_level

    contrast_c = np.clip(contrast_c, -1, 1)

    # Construct the full stimulus including pre and tail periods
    full_stim = np.concatenate((
        np.ones(preFrames) * mean_c,  # Pre-stimulus period
        np.repeat(contrast_c, dataset.frame_dwell),  # Actual stimulus
        np.ones(tailFrames) * mean_c  # Tail period
    ))

    # Generate the corresponding time vector
    full_time = np.linspace(-dataset.pre_time / 1000, 
                            (dataset.stim_time + dataset.tail_time) / 1000, 
                            len(full_stim))

    return full_stim

    # return np.repeat(contrast_c, dataset.frame_dwell)

def getStim_pink(dataset):
    # print("Seed:", dataset.noise_seed)
    noiseGen = np.random.RandomState(seed=int(dataset.noise_seed))
    
    preFrames = int(dataset.frame_rate * dataset.pre_time / 1000)
    stimFrames = int(dataset.frame_rate * dataset.stim_time / 1000)
    tailFrames = int(dataset.frame_rate * dataset.tail_time / 1000)
    num_samples = stimFrames 
    freqs = np.fft.rfftfreq(num_samples, d=1/dataset.frame_rate)
    amplitudes = np.zeros_like(freqs)
    amplitudes[1:] = np.power(freqs[1:], - dataset.beta / 2)  # Avoid divide by zero

    phases = np.exp(2j * np.pi * noiseGen.rand(len(freqs)))  # Random phase
    spectrum = amplitudes * phases  # Complex spectrum
    
    # Transform back to time 
    raw_noise = np.fft.irfft(spectrum, n=num_samples) #Check equivalence with real(ifft([spectrum, conj(spectrum(end-1:-1:2))]))
    raw_noise /= np.std(raw_noise)  # Normalize to unit variance. Necessary so that the contrast is an effective std

    # Apply contrast scaling
    noise_intensity_adj = dataset.spot_mean_level * (1 + dataset.contrast * raw_noise) # I = I_mean * (1 + C * Noise) 
                                                                                       # Scales the noise fluctuations so that their 
                                                                                       #std relative to the mean intensity is equal                                                                                    # to contrast.
    if dataset.mean_level:
        # print("Mean level not none")
        contrast_values = (noise_intensity_adj - dataset.mean_level) / dataset.mean_level
        mean_c = (dataset.spot_mean_level - dataset.mean_level) / dataset.mean_level
    else:
        # print("Mean level none")
        contrast_values = noise_intensity_adj
        mean_c = dataset.spot_mean_level
    
    contrast_values = np.clip(contrast_values, -1, 1)
    full_stim = np.concatenate((
        np.ones(preFrames) * mean_c,  # Pre-stimulus period
        np.repeat(contrast_values, dataset.frame_dwell),  # Relative intensity fluctuations
        np.ones(tailFrames) * mean_c  # Tail period
    ))
        
    return full_stim

def custom_randn(rng, size):
    """
    Generates random normal values using the Box-Muller transform.
    Mimics the MATLAB implementation of `sa_labs.util.randn`.
    """
    r1 = rng.rand(*size)
    r2 = rng.rand(*size)
    r = np.sqrt(-2 * np.log(r1))
    o1 = r * np.cos(2 * np.pi * r2)
    return o1

def generate_stimulus(ds):
    """
    Mimics the exact implementation that was used in the current experiment.
    Convolved, inefficient, but works.
    Generates noise for all n_stimpoints at the full sample_rate.
    Down-samples and up-samples explicitly to match frequency.
    """
    # Calculate the pre and tail sections
    preFrames = int(ds['pre_time'] * ds['sample_rate'] / 1E3)
    tailFrames = int(ds['tail_time'] * ds['sample_rate'] / 1E3)
    prestim_wave = np.zeros(preFrames)
    tailstim_wave = np.zeros(tailFrames)
    
    # Calculate the rate for downsampling
    rate = 1
    if ds['sample_rate'] > ds['frequency']:
        rate = int(np.ceil(ds['sample_rate'] / ds['frequency']))
    
    # Generate the white noise wave
    n_stimpoints = int(ds['stim_time'] * ds['sample_rate'] / 1E3)
    rng = np.random.RandomState(seed=ds['random_seed'])  # Equivalent to MATLAB's RandStream("twister", "Seed", seed)
    white_noise_wave = custom_randn(rng, (n_stimpoints,)) * ds['std'] + ds['amplitude']
    
    # Downsample the white noise wave
    down_sample_wave = white_noise_wave[::rate]
    
    # Upsample the downsampled wave
    stim_wave = np.repeat(down_sample_wave, rate)
    
    # Truncate if the upsampled wave exceeds the required length
    if len(stim_wave) > n_stimpoints:
        stim_wave = stim_wave[:n_stimpoints]
    
    stim_wave = np.round(stim_wave, 4)
    full_wave = np.concatenate((prestim_wave, stim_wave, tailstim_wave))
    print("Downsampling rate:", rate)
    return full_wave

# def getStim_current(ds):
#     """
#     Generates fewer random values (nPulses), directly aligned with the frequency.
#     Skips explicit downsampling and creates a lower-resolution wave upfront.
#     Does not work with the current experiment.  
#     """
#     # Initialize random generator
#     noiseGen = np.random.RandomState(seed=int(ds['random_seed']))
    
#     # Calculate pulse counts
#     sample_rate = ds['sample_rate']
#     preFrames = int(ds['pre_time'] * sample_rate / 1000)
#     stimFrames = int(ds['stim_time'] * sample_rate / 1000)
#     tailFrames = int(ds['tail_time'] * sample_rate / 1000)
    
#     # Generate Gaussian random values
#     nPulses = int(ds['stim_time'] * ds['frequency'] / 1000)  # Total pulses based on frequency
#     randVals = noiseGen.rand(nPulses, 2)
#     randVals = np.sqrt(-2 * np.log(randVals[:, 0])) * np.cos(2 * np.pi * randVals[:, 1])
    
#     # Scale with std and amplitude
#     variance = randVals * ds['std']
#     amplitude = ds['amplitude'] + variance #absolute noise
#     # because white_noise_wave = sa_labs.util.randn(random_stream, 1, n_stimpoints) .* obj.std + obj.amplitude;
    
#     # Expand the wave efficiently
#     pulse_duration = int(np.ceil(ds['sample_rate'] / ds['frequency'])) # Samples per pulse
#     stim_wave = np.repeat(amplitude, pulse_duration)[:stimFrames]
#     # stim_wave = np.round(stim_wave, 4)
    
#     # Concatenate pre, stim, and tail periods
#     full_stim = np.concatenate((
#         np.zeros(preFrames),
#         stim_wave,
#         np.zeros(tailFrames)
#     ))
#     total_frames = preFrames + stimFrames + tailFrames
#     # stim_times = np.arange(total_frames) / sample_rate
#     return full_stim

def stim_plotter(df, min=None, max=None):
    trial = df
    pre = trial['pre_time'] / 1000
    stim = trial['stim_time'] / 1000
    tail = trial['tail_time'] / 1000
    total = pre + stim + tail
    sample_rate = trial['sample_rate']
    stimulus = generate_stimulus(df)
    print(stimulus)
    # Time vector for the stimulus
    time = np.arange(len(stimulus)) / trial['sample_rate']  # Convert to seconds
    
    freq_stim, power_stim = periodogram(stimulus, fs=sample_rate)
    
    fig = plt.figure(figsize=(12, 6))

    from matplotlib.gridspec import GridSpec
    gs = GridSpec(2, 2, height_ratios=[2, 2], width_ratios=[1, 1])
    # Top-left: Power Spectrum
    ax1 = fig.add_subplot(gs[:2, 0])
    ax1.loglog(freq_stim, power_stim)
    ax1.set_title('Power Spectrum')
    ax1.set_ylabel('Power (dB)')
    ax1.vlines(60, 0, power_stim.max()+2e3,color='r', linestyle='--', label='60 Hz')
    ax1.vlines(0.1, 0 , power_stim.max()+2e3 ,color='r', linestyle='--', label='0.1 Hz')
    ax1.legend()
    # ax1.set_xlim([-10, 1000])
    # ax1.set_ylim([power_stim.min(), power_stim.max()+2e3])
    # if min is not None and max is not None:
    #     ax1.set_xlim([min, max])
    
    # Top-right: Stimulus
    ax2 = fig.add_subplot(gs[:2, 1])
    ax2.plot(time, stimulus)
    ax2.set_title('Stimulus')
    ax2.set_ylabel('Injected Current (pA)')
    # if min is not None and max is not None:
    #     ax2.set_xlim([min, max])

    plt.show()


    
def convert_spike_indices_to_times(trial):
    if trial['spike_indices'] is None or len(trial['spike_indices']) == 0:
        return []  

    spike_times = [np.array(indices) / trial['sample_rate'] for indices in trial['spike_indices']]
    
    # # Adjust for the pre-time offset
    # start_time = -trial['pre_time'] / 1000  
    # spike_times = [spikes + start_time for spikes in spike_times]

    return spike_times
