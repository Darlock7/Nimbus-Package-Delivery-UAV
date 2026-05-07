function dfdx = ddx_fwd(f,dx)
 
    % determine field size
    [nx,ny]     = size(f);

    % allocate return field
    dfdx        = zeros(nx,ny);
    
    % forward difference
    for i=1:nx-1
        for j=1:ny
            dfdx(i,j) = (f(i+1,j)-f(i,j))/dx;
        end
    end
    
    % backward difference for last point
    i = nx;
    for j=1:ny
        dfdx(i,j) = (f(i,j)-f(i-1,j))/dx;
    end
    
end