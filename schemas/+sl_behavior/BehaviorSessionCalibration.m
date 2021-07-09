%{
# Behavior session calibration table
(session_id) -> sl.AnimalEventSocialBehaviorSession(event_id)
---
inches_per_pixel : float                        # inches per pixel in the video
inner_wall_radius : float                       # inner wall radius in inches
outer_wall_radius_top : float                   # outer wall radius in inches (top of platform)
outer_wall_radius_bottom : float                # outer wall radius in inches (bottom of plotform);
windowa_start : float                           # start position of windowA in radians
windowa_end : float                             # start position of windowA in radians
windowb_start : float                           # start position of windowB in radians
windowb_end : float                             # start position of windowB in radians
windowc_start : float                           # start position of windowC in radians
windowc_end : float                             # start position of windowC in radians
center_position_x : int unsigned                # X pixel location of center (used to compare to raw DLC coords)
center_position_y : int unsigned                # Y pixel location of center (used to compare to raw DLC coords)
positive_radians_direction = 'CW' : enum('CW', 'CCW')  # direction for positive radians (clockwise or counterclockwise)
zero_radians_direction = 'negative X' : enum('positive X', 'positive Y', 'negative X', 'negative Y') # direction considered 0 radians
%}
classdef BehaviorSessionCalibration < dj.Manual
    
end