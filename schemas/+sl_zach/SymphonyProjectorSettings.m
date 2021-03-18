%{
  # Settings for a Stage Protocol
  settings_id: int unsigned auto_increment           # unique settings id
  ---
  rstar_foreground : float
  rstar_background : float

  mstar_foreground : float
  mstar_background : float

  sstar_foreground : float
  sstar_background : float

  red_led: tinyint unsigned      # assumes bitDepth == 8
  green_led : tinyint unsigned
  blue_led : tinyint unsigned

  NDF : tinyint unsigned
  
  frame_rate : float
  intensity : decimal(1,2)  # a decimal from 0.00 to 1.00
  mean_level: decimal(1,2)  # a decimal from 0.00 to 1.00

  prerender : enum('on', 'off')
  force_prerender : enum('auto', 'on', 'off')

  microns_per_pixel : float
  angle_offset : float

%}

classdef SymphonyProjectorSettings < dj.Imported
end