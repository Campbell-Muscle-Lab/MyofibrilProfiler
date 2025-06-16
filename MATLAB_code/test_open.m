function test_open


image_string = '../data/heart3003.nd2'


d = bfopen(image_string)

h = d{1,2};

h.get('Global dCalibration1to1')










end