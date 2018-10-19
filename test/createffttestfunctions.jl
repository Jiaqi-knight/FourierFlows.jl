function create_testfuncs(g::OneDGrid)
    if nx <= 8; error("nx must be > 8"); end

    m = 5
    k0 = g.k[2] # Fundamental wavenumber

    # Test function
    φ = π/3
    f1 = cos.(m*k0*g.x .+ φ)
    f1h = fft(f1)
    f1hr = rfft(f1)

    f1hr_mul = zeros(Complex{eltype(g.x)}, g.nkr)
    mul!(f1hr_mul, g.rfftplan, f1)

    # Theoretical values of the fft and rfft
    f1h_th = zeros(Complex{Float64}, size(f1h))
    f1hr_th = zeros(Complex{Float64}, size(f1hr))

    for i in 1:g.nk
      if abs(real(g.k[i])) == m*k0
        f1h_th[i] = -exp(sign(real(g.k[i]))*im*φ)*g.nx/2
      end
    end

    for i in 1:g.nkr
      if abs(real(g.k[i]))==m*k0
        f1hr_th[i] = -exp(sign(real(g.kr[i]))*im*φ)*g.nx/2
      end
    end

    f1, f1h, f1hr, f1hr_mul, f1h_th, f1hr_th
end


function create_testfuncs(g::TwoDGrid)
    if nx <= 8; error("nx must be > 8"); end

    m, n = 5, 2
    k0 = g.k[2] # fundamental wavenumber
    l0 = g.l[2] # fundamental wavenumber

    # some test functions
    f1 = @. cos(m*k0*g.X) * cos(n*l0*g.Y)
    f2 = @. sin(m*k0*g.X + n*l0*g.Y)

    f1h = fft(f1)
    f2h = fft(f2)
    f1hr = rfft(f1)
    f2hr = rfft(f2)

    f1hr_mul = zeros(Complex{eltype(g.x)}, (g.nkr, g.nl))
    f2hr_mul = zeros(Complex{eltype(g.x)}, (g.nkr, g.nl))
    mul!(f1hr_mul, g.rfftplan, f1)
    mul!(f2hr_mul, g.rfftplan, f2)

    # Theoretical results
    f1h_th = zeros(Complex{eltype(g.x)}, size(f1h))
    f2h_th = zeros(Complex{eltype(g.x)}, size(f2h))
    f1hr_th = zeros(Complex{eltype(g.x)}, size(f1hr))
    f2hr_th = zeros(Complex{eltype(g.x)}, size(f2hr))

    for j in 1:g.nl, i in 1:g.nk
      if ( abs(real(g.K[i, j])) == m*k0 && abs(real(g.L[i, j])) == n*l0 )
        f1h_th[i, j] = - g.nx*g.ny/4
      end
      if ( real(g.K[i, j]) == m*k0 && real(g.L[i, j]) == n*l0 )
        f2h_th[i, j] = -g.nx*g.ny/2
      elseif ( real(g.K[i, j]) == -m*k0 && real(g.L[i, j]) == -n*l0 )
        f2h_th[i, j] = g.nx*g.ny/2
      end
    end
    f2h_th = -im*f2h_th;

    for j in 1:g.nl, i in 1:g.nkr
      if ( abs(g.Kr[i, j])==m*k0 && abs(g.L[i, j])==n*l0 )
        f1hr_th[i, j] = - g.nx*g.ny/4
      end
      if ( real(g.Kr[i, j]) == m*k0 && real(g.L[i, j]) == n*l0 )
        f2hr_th[i, j] = -g.nx*g.ny/2
      elseif ( real(g.Kr[i, j]) == -m*k0 && real(g.L[i, j]) == -n*l0 )
        f2hr_th[i, j] = g.nx*g.ny/2
      end
    end
    f2hr_th = -im*f2hr_th;

    f1, f2, f1h, f2h, f1hr, f2hr, f1hr_mul, f2hr_mul,
      f1h_th, f1hr_th, f2h_th, f2hr_th
end
