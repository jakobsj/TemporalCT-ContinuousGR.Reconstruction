function [deviations_unsorted] = compute_deviations(sino,sort_idx,det_idx,doplot)

% Sort sinogram.
sino_sorted = sino(:,sort_idx);

% Extract top band with edge in.
sino_sorted_top = sino_sorted(det_idx,:);

% Determine edge as pixel where largest (negative), so min, difference
% occurs.
[minval,minidx] = min(diff(sino_sorted_top));

% If desired, display the top band, the diff'ed top band as images along
% with and the determined edge indeces.
if doplot
    figure
    imagesc(sino_sorted_top)
    
    figure
    imagesc(diff(sino_sorted_top))
    
    figure, plot(-minidx)
end

% Fit and evaluate spline to edge. The edge of the sorted sinogram should
% ideally be smooth, but due to individual misalignments at each projection
% the edge is not smooth. The spline is a smooth approximation.
xx = 1:size(sino,2);
pp1 = splinefit(xx,-minidx,10,'p'); %periodic boundary condition
y2 = ppval(pp1,xx);

% If desired make plot to assess the spline.
if doplot
    figure, plot(xx,-minidx);
    hold on
    plot(xx,y2)
end

% Compute offsets as deviations between measured edge and spline.
deviations = -minidx-y2;

% Plot deviations if desired
if doplot
    figure
    plot(xx,deviations)
end

% Unsort to get deviations for correct angles.
deviations_unsorted = zeros(size(deviations));
deviations_unsorted(sort_idx) = deviations;

% If desired, plot unsorted deviations.
if doplot
    figure
    plot(deviations_unsorted)
end