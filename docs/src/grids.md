# Grids


1D, 2D, and 3D grids are supported. We demonstrate here the construction of a 
one-dimensional grid and how one can use it to perform Fourier transforms and 
compute spatial derivatives.

A one-dimensional grid with $n_x = 64$ grid points and length $L_x = 2\pi$ is 
constructed by

```@meta
DocTestSetup = quote
    using FourierFlows
end
```

```jldoctest
julia> nx, Lx = 64, 2π;

julia> grid = OneDGrid(nx, Lx)
OneDimensionalGrid
  ├─────────── Device: CPU
  ├──────── FloatType: Float64
  ├────────── size Lx: 6.283185307179586
  ├──── resolution nx: 64
  ├── grid spacing dx: 0.09817477042468103
  └─────────── domain: x ∈ [-3.141592653589793, 3.0434178831651124]
```

The grid domain is, by default, constructed symmetrically around $x=0$, but this 
can be altered using the `x0` keyword argument of `OneDGrid` constructor. The grid 
spacing is $L_x/n_x$. Note that the last point of the domain is a grid-spacing 
before $L_x/2$. This is because periodicity implies that the value of any field 
at the end-points of the domain are equal and, therefore, grid-point values at
both these end-points are reduntant.

We can define an array `f` that contains the values of a function $f(x)$ on this 
grid as

```@setup 1
using FourierFlows
using LinearAlgebra: mul!, ldiv!
using Plots
Plots.scalefontsizes(1.25)
Plots.default(lw=2)
nx, Lx = 64, 2π
grid = OneDGrid(nx, Lx)
```

```@example 1
f = @. sin(2 * grid.x) + 1/2 * cos(5 * grid.x)

nothing # hide
```

Note that we chose a function that *is* periodic on our domain. We can visualize
`f` by

```@example 1
plot(grid.x, f, label="f", xlabel="x")
savefig("assets/plot1.svg"); nothing # hide
```

![](assets/plot1.svg)

Function $f(x)$ can be expanded in Fourier series:

```math
f(x) = \sum_{k} \hat{f}(k)\,\mathrm{e}^{\mathrm{i} k x},
```

where $\hat{f}(k)$ is Fourier transform of $f(x)$ and $k$ the discrete set of 
wavenumbers that fit within our finite domain. We can compute $\hat{f}$ via a 
Fast Fourier Transform (FFT). Since our `f` array is real-valued then we should 
use the `real-FFT` algorithm. The real-valued FFT transform only saves the Fourier 
coefficients for $k\ge 0$; the coefficients for negative wavenumbers can be 
obtained via $\hat{f}(-k) = \hat{f}(k)^{*}$.

The `grid` includes the `FFT` plans for both real-valued and complex valued transforms:

```@example 1
grid.fftplan
```

```@example 1
grid.rfftplan
```

We use the convention that variables names with `h` at the end stand for variable-hat, i.e., $\hat{f}$  is the Fourier transform of $f$ and is stored in array `fh`. Since `f` is of size $n_x$, the real-Fourier transform should be of size $n_{kr} = n_x/2+1$.

```@example 1
fh = zeros(FourierFlows.cxeltype(grid), grid.nkr)
mul!(fh, grid.rfftplan, f)

nothing # hide
```

The `FFT` algorithm does not output exactly the Fourier coefficients $\hat{f}(k)$ but
rather due to different normalization, `FFT` outputs something proportional to $\hat{f}(k)$. 
To obtain $\hat{f}$ we need to divide the `FFT` output by the length of the 
original array and by $\mathrm{e}^{-\mathrm{i} k x_0}$, where $x_0$ is the first 
point of our domain array.

```@example 1
fhat = @. fh / (nx * exp(- im * grid.kr * grid.x[1])) # due to normalization of FFT

plot(grid.kr, [real.(fhat), imag.(fhat)],
          label = ["real\\( f̂ \\)" "imag\\( f̂ \\)"],
         xlabel = "k",
          xlims = (-0.5, 10.5),
         xticks = 0:10,
         marker = :auto)

savefig("assets/plot2.svg"); nothing # hide
```

![](assets/plot2.svg)

We can compute its derivative via Fourier transforms. To do that we can use the
`FFTW` plans that are constructed with the grid. First we allocate an empty array
where the values of the derivative will be stored,

```@example 1
∂ₓf = similar(f)
∂ₓfh = similar(fh)
nothing # hide
```

The grid contains the wavenumbers (both for real-value functions `grid.kr` and 
for complex-valued functions `grid.k`). We populate array `∂ₓfh` is with $\mathrm{i} k \hat{f}$:

```@example 1
@. ∂ₓfh = im * grid.kr * fh

nothing # hide
```

Then the derivative in physical space, `∂ₓf`, is obtained with an inverse Fourier 
tranform. The latter is obtained again using the `FFTW` plans but now via `ldiv!`:

```@example 1
ldiv!(∂ₓf, grid.rfftplan, ∂ₓfh)

plot(grid.x, [f ∂ₓf], label=["f" "∂f/∂x"], xlabel="x")

savefig("assets/plot3.svg"); nothing # hide
```

![](assets/plot3.svg)
