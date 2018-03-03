using Vinyl: overdub, @overdub, @hook, @primitive
using Base.Test

mutable struct CountCtx
  count
end

@hook c::CountCtx function sin(x)
  c.count += 1
end

struct SinCtx end
@primitive SinCtx sin(x) = -1

@testset "Vinyl" begin

@test @overdub(nothing,sum([1,2,3])) == 6

test(x) = sin(x)+cos(x)
test2(x) = test(x) + test(x+1)

ctx = CountCtx(0)
overdub(ctx, test2, 5.0)
@test ctx.count == 2

@test overdub(SinCtx(), test, 5) == cos(5)-1

include("continuations.jl")

end
