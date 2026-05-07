function d2fdy2 = d2dy2(f, dy)
%D2DY2 Second derivative in y using second-order finite differences

[nx, ny] = size(f);
d2fdy2 = zeros(nx, ny);

% left boundary in y: second-order forward difference
d2fdy2(:,1) = (2*f(:,1) - 5*f(:,2) + 4*f(:,3) - f(:,4)) / dy^2;

% interior: second-order central difference
d2fdy2(:,2:ny-1) = (f(:,3:ny) - 2*f(:,2:ny-1) + f(:,1:ny-2)) / dy^2;

% right boundary in y: second-order backward difference
d2fdy2(:,ny) = (2*f(:,ny) - 5*f(:,ny-1) + 4*f(:,ny-2) - f(:,ny-3)) / dy^2;

end