import re
from ScanImageTiffReader import ScanImageTiffReader
import datetime
import json
import os

def exportFrameTimeStamp(file_path : str) -> dict:
    props = {}
    tif = ScanImageTiffReader(file_path)
    props['epoch_time'] = re.search("epoch = \[((?:\d+.?\d+,?)+)\]", tif.description(0)).groups()[0].split(',')
    last_second_milisec = props['epoch_time'][-1].split('.')
    last_second_milisec[-1] = '.' + last_second_milisec[-1]
    last_second_milisec[-1] = float(last_second_milisec[-1]) * 1e3
    props['epoch_time'].pop()
    props['epoch_time'] = props['epoch_time'] + last_second_milisec
    props['epoch_time'] = [int(x) for x in props['epoch_time']]
    epoch_time = datetime.datetime(*props['epoch_time'])
    time_array = []
    for i in range(tif.shape()[0]):
        time_array.append(float(re.search("frameTimestamps_sec = (\d+.?\d+)", tif.description(i)).groups()[0]))
    props['time_array'] = time_array
    props['matlab_time_string'] = epoch_time.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
    props['file_name'] = epoch_time.strftime('%m%d%y')
    
    return props

def timePropsToJSON(file_path : str) -> None:
    
    folder_path = os.path.dirname(file_path)
    (file_name, extension) = os.path.splitext(os.path.basename(file_path))
    if extension == '.tif':
        print('.......................')
        props = exportFrameTimeStamp(file_path)
        json_file_name =  folder_path + os.sep + file_name + '.json'
        f = open(json_file_name, 'w')
        json.dump(props, f)
        f.close()
        print(f'Done ✓ {json_file_name}')
        