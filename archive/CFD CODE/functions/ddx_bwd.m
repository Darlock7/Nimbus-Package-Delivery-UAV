function dfdx = ddx_bwd(f, dx)
%DDX_BWD First derivative in x using first-order backward difference


[nx, ny] = size(f);
dfdx = zeros(nx, ny);

% left boundary in x: use first-order forward difference
dfdx(1, :) = (f(2, :) - f(1, :)) / dx;

% interior: first-order backward difference
dfdx(2:nx, :) = (f(2:nx, :) - f(1:nx-1, :)) / dx;

end