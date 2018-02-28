# Vinyl

[![Build Status](https://travis-ci.org/MikeInnes/Vinyl.jl.svg?branch=master)](https://travis-ci.org/MikeInnes/Vinyl.jl)

Before [Cassette](https://github.com/jrevels/Cassette.jl/) was invented, we had to go without fancy tapes and put up with scratches and skips. Some would say it makes for a warmer sound.

This package (approximately) implements Cassette's API using interpretation rather than compilation. While very slow, it works on current Julia and has low compiler overhead, so is suitable for code-tracing and debugging use cases.

Hook functions before they run:

```julia
julia> using Vinyl: @overdub, @hook

julia> struct TraceCtx end

julia> @hook TraceCtx (f::Any)(xs...) = println("Called $(:($f($(xs...))))")

julia> @overdub TraceCtx() 1+1.0
Called (+)(1, 1.0)
Called (promote)(1, 1.0)
Called (promote_type)(Int64, Float64)
Called (promote_rule)(Int64, Float64)
Called (promote_rule)(Float64, Int64)
Called (Base.promote_result)(Int64, Float64, Union{}, Float64)
Called (promote_type)(Union{}, Float64)
Called (convert)(Float64, 1)
Called (sitofp)(Float64, 1)
Called (promote_type)(Int64, Float64)
Called (promote_rule)(Int64, Float64)
Called (promote_rule)(Float64, Int64)
Called (Base.promote_result)(Int64, Float64, Union{}, Float64)
Called (promote_type)(Union{}, Float64)
Called (convert)(Float64, 1.0)
Called (tuple)(1.0, 1.0)
Called (Core._apply)(+, (1.0, 1.0))
Called (add_float)(1.0, 1.0)
2.0
```

Alter the behaviour of a function:

```julia
julia> using Vinyl: @overdub, @primitive

julia> prod([1,2,3,4,5])
120

julia> sum([1,2,3,4,5])
15

julia> @primitive MulCtx a * b = a + b

julia> @overdub MulCtx() prod([1,2,3,4,5])
15
```
