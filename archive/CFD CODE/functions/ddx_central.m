function dfdx = ddx_central(f, dx)
%DDX_CENTRAL First derivative in x using second-order central difference


[nx, ny] = size(f);
dfdx = zeros(nx, ny);

% left boundary: second-order forward difference
dfdx(1, :) = (-3*f(1, :) + 4*f(2, :) - f(3, :)) / (2*dx);

% interior: second-order central difference
dfdx(2:nx-1, :) = (f(3:nx, :) - f(1:nx-2, :)) / (2*dx);

% right boundary: second-order backward difference
dfdx(nx, :) = (3*f(nx, :) - 4*f(nx-1, :) + f(nx-2, :)) / (2*dx);

end