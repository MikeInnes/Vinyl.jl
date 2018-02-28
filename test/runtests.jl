using Vinyl: @hook, @overdub
using Base.Test

mutable struct CountCtx
  count
end

@testset "Vinyl" begin

@hook c::CountCtx function sin(x)
  c.count += 1
end

test(x) = sin(x)+cos(x)
test2(x) = test(x) + test(x+1)

ctx = CountCtx(0)
@overdub ctx test2(5.0)
@test ctx.count == 2

end
