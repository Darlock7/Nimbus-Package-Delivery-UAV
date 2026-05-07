function dfdx = ddx_fwd(f, dx)
%DDX_FWD First derivative in x using first-order forward difference


[nx, ny] = size(f);
dfdx = zeros(nx, ny);

% interior: first-order forward difference
dfdx(1:nx-1, :) = (f(2:nx, :) - f(1:nx-1, :)) / dx;

% right boundary in x: use first-order backward difference
dfdx(nx, :) = (f(nx, :) - f(nx-1, :)) / dx;

end