function sma = signalMagnitudeArea(signalX, signalY, signalZ)
    sma = (sum(abs(signalX),2) + sum(abs(signalY),2) + sum(abs(signalZ),2)) / length(signalX);
end