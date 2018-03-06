using Vinyl: @reset, shift
using Base.Test

struct FakeArray end
Base.length(::FakeArray) = shift(k -> k)

@testset "Continuations" begin

k = @reset shift(k -> k)+5
@test k(1) == 6
@test k(2) == 7

@test @reset(2*(shift(k -> k(5))+1)) == 12

@test @reset(2*shift(k -> k(k(4)))) == 16

# TODO fix #1
@reset begin
  for i = 1:2
    _ = shift(k -> (i,k()))
  end
  ()
end

f(x) = length(x) > 10 ? :big : :small
k = @reset f(FakeArray())

# see #2
@test k(5) == :small
@test k(15) == :big

end
