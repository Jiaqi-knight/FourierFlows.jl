#!/usr/bin/env julia

using 
  FourierFlows,
  FFTW,
  LinearAlgebra,
  Test

const rtol_fft = 1e-12

# Run tests

include("createffttestfunctions.jl")

time = @elapsed begin

println("-- Core tests --")

@testset "Grid tests" begin
  include("test_grid.jl")

  # Test 1D grid
  nx, Lx = 4, 2π
  g₁ = OneDGrid(nx, Lx)
  @test testnx(g₁, nx)
  @test testdx(g₁)
  @test testx(g₁)
  @test testk(g₁)
  @test testkr(g₁)

  # Test 2D rectangular grid
  ny, Ly = 6, 4π
  g₂ = TwoDGrid(nx, Lx, ny, Ly)
  @test testnx(g₂, nx)
  @test testny(g₂, ny)
  @test testdx(g₂)
  @test testdy(g₂)
  @test testx(g₂)
  @test testy(g₂)
  @test testk(g₂)
  @test testkr(g₂)
  @test testl(g₂)
  @test testgridpoints(g₂)
end

@testset "FFT tests" begin
  include("test_fft.jl")

  # Test 1D grid
  nx = 32             # number of points
  Lx = 2π             # Domain width
  g1 = OneDGrid(nx, Lx)

  # Test 2D rectangular grid
  nx, ny = 32, 64     # number of points
  Lx, Ly = 2π, 3π     # Domain width
  g2 = TwoDGrid(nx, Lx, ny, Ly)

  @test test_fft_cosmx(g1)
  @test test_rfft_cosmx(g1)
  @test test_rfft_mul_cosmx(g1)

  @test test_fft_cosmxcosny(g2)
  @test test_rfft_cosmxcosny(g2)
  @test test_rfft_mul_cosmxcosny(g2)
  @test test_fft_sinmxny(g2)
  @test test_rfft_sinmxny(g2)
  @test test_rfft_mul_sinmxny(g2)
end

@testset "IFFT tests" begin
  include("test_ifft.jl")

  # Test 1D grid
  nx = 32             # number of points
  Lx = 2π             # Domain width
  g1 = OneDGrid(nx, Lx)

  # Test 2D rectangular grid
  nx, ny = 32, 64     # number of points
  Lx, Ly = 2π, 3π     # Domain width
  g2 = TwoDGrid(nx, Lx, ny, Ly)

  @test test_ifft_cosmx(g1)
  @test test_irfft_cosmx(g1)
  @test test_irfft_mul_cosmx(g1)

  @test test_ifft_cosmxcosny(g2)
  @test test_irfft_cosmxcosny(g2)
  @test test_irfft_mul_cosmxcosny(g2)
  @test test_ifft_sinmxny(g2)
  @test test_irfft_sinmxny(g2)
  @test test_irfft_mul_sinmxny(g2)
end

@testset "Utils tests" begin
  include("test_utils.jl")

  # Test on a rectangular grid
  nx, ny = 64, 128   # number of points
  Lx, Ly = 2π, 3π    # Domain width
  g = TwoDGrid(nx, Lx, ny, Ly)
  x, y = gridpoints(g)
  k0, l0 = 2π/Lx, 2π/Ly

  # Real and complex-valued functions
  σ = 0.5
  f1 = @. exp(-(x^2 + y^2)/(2σ^2))
  f2 = @. exp(im*(2k0*x + 3l0*y^2)) * (exp.(-(x^2 + y^2)/(2σ^2)) + 2im*exp(-(x^2 + y^2)/(5σ^2)))

  # Sine/Exp waves
  k1, l1 = 2*k0, 6*l0
  k2, l2 = 3*k0, -3*l0

  sinkl1 = @. sin(k1*x + l1*y)
  sinkl2 = @. sin(k2*x + l2*y)
  expkl1 = @. exp(im*(k1*x + l1*y))
  expkl2 = @. exp(im*(k2*x + l2*y))

  # Analytical expression for the Jacobian of sin1 and sin2 and of exp1 and exp2
  Jsinkl1sinkl2 = @. (k1*l2-k2*l1)*cos(k1*x + l1*y)*cos.(k2*x + l2*y)
  Jexpkl1expkl2 = @. (k2*l1-k1*l2)*exp(im*((k1+k2)*x + (l1+l2)*y))

  @test test_parsevalsum(f1, g; realvalued=true)   # Real valued f with rfft
  @test test_parsevalsum(f1, g; realvalued=false)  # Real valued f with fft
  @test test_parsevalsum(f2, g; realvalued=false)  # Complex valued f with fft
  @test test_parsevalsum2(f1, g; realvalued=true)  # Real valued f with rfft
  @test test_parsevalsum2(f1, g; realvalued=false) # Real valued f with fft
  @test test_parsevalsum2(f2, g; realvalued=false) # Complex valued f with fft

  @test test_jacobian(sinkl1, sinkl1, 0*sinkl1, g)  # Test J(a, a) = 0
  @test test_jacobian(sinkl1, sinkl2, Jsinkl1sinkl2, g) # Test J(sin1, sin2) = Jsin1sin2
  @test test_jacobian(expkl1, expkl2, Jexpkl1expkl2, g) # Test J(exp1, exp2) = Jexp1exps2

  @test test_createarrays()
  @test test_domainaverage(32; xdir=true)
  @test test_domainaverage(32; xdir=false)
  @test test_structvarsexprFields(g)
  @test test_structvarsexprSpecs(g)

  # Radial spectrum tests. Note that ahρ = ∫ ah ρ dθ.
  n = 128; δ = n/10                 # Parameters
  ahkl(k, l) = exp(-(k^2+l^2)/2δ^2) #  a = exp(-ρ²/2δ²)
      ahρ(ρ) = 2π*ρ*exp(-ρ^2/2δ^2)  # aᵣ = 2π ρ exp(-ρ²/2δ²)
  @test test_radialspectrum(n, ahkl, ahρ)

  ahkl(k, l) = exp(-(k^2+l^2)/2δ^2) * k^2/(k^2+l^2) #  a = exp(-ρ²/2δ²)*cos(θ)²
      ahρ(ρ) = π*ρ*exp(-ρ^2/2δ^2)                   # aᵣ = π ρ exp(-ρ²/2δ²)
  @test test_radialspectrum(n, ahkl, ahρ)
end

#@testset "Timestepper tests" begin
#  include("test_timesteppers.jl")
#end

#@testset "Diagnostics tests" begin
#  include("test_diagnostics.jl")
#end


#=
println("-- Physics tests --")

@testset "Physics: Kuramoto-Sivashinsky" begin
  include("test_kuramotosivashinsky.jl")
end

@testset "Physics: TracerAdvDiff" begin
  include("test_traceradvdiff.jl")
end
=#

end
println("Total test time: ", time)
