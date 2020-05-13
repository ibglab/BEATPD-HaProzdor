function segments = segmentData(signal, winLen, overlap)
% segment data with specific windown length and overlapping
% useSegments - use only specified segments, throw all other segments
% firstTimeStamp - first time stamp to use. Throw everything before (that's
% how the data is se..)
% winLen, overlap - number of samples
segments = buffer(signal, winLen, overlap)';
segments = segments(2:end-1, :);   %throw padded first and last
% segments = segments(useSegments, :);

end

