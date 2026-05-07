function dfdx = ddx_bwd(f,dx)
    
    % determine field size
    [nx,ny]     = size(f);

    % allocate return field
    dfdx        = zeros(nx,ny);
    
    % backward difference
    for i=2:nx
        for j=1:ny
            dfdx(i,j) = (f(i,j)-f(i-1,j))/dx;
        end
    end

    % forward difference for first point
    i = 1;
    for j=1:ny
        dfdx(i,j) = (f(i+1,j)-f(i,j))/dx;
    end
    
end