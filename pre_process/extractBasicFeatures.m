function [mu, sigma, medAbDev, maxVal, minVal,energy,interqRange,entrop,varargout] = extractBasicFeatures(signal, domain)
% domain: 'time' - for rime domain, 'freq' for freq domain. default is
% time.
% time domain will calculte the arburg of order 4
% frequency domain calculates 
if nargin < 2
    domain = 'time';
end

sigLen = length(signal);
mu = mean(signal,2);
sigma = std(signal,[],2);
medAbDev = mad(signal')';
maxVal = max(signal, [], 2);
minVal = min(signal, [], 2);
energy = sum(signal.^2, 2) / sigLen;
interqRange = iqr(signal, 2);    
entrop = calcEntropy(signal);       % Result dependent in the number of bins!!
[arBurg] = arburg(signal',4);              %%        Autorregresion coefficients with Burg order equal to 4
if strcmp(domain, 'time')
    varargout{1} = arBurg(:, 2);
    varargout{2} = arBurg(:, 3);
    varargout{3} = arBurg(:, 4);
    varargout{4} = arBurg(:, 5);
end
if strcmp(domain, 'freq')

end
end


function entrop = calcEntropy(signal)
entrop = zeros(size(signal, 1), 1);
k=1+log2(size(signal, 2)); %determine numbeer of bins!!
bins = round(k);
for j = 1:size(signal, 1)
    n = hist(signal(j,:), bins);
    p = n(find(n))./sum(n);
    entrop(j) = -sum(p .*log2(p), 2);
end

end



