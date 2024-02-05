from calciumImaging import timePropsToJSON
import os


def writeFrameTimesForDir(FILE_DIR : str)
    #FILE_DIR = '/Users/gregschwartz/working/vid_alignment_test/020124Bc2'
    img_files = os.listdir(FILE_DIR)
    [timePropsToJSON(os.path.join(FILE_DIR, x)) for x in img_files]
    #timePropsToJSON('/Users/gregschwartz/working/vid_alignment_test/test/020124Bc2_region1_00001.tif')

