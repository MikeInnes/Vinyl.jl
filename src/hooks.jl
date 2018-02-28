hook(c, f, args...) = return

macro hook(ctx, f)
  def = splitdef(f)
  f, args, body, ps = def[:name], def[:args], def[:body], def[:whereparams]
  ctx isa Symbol && (ctx = :(::$ctx))
  isexpr(f, :(::)) || (f = :(::typeof($f)))
  :(function hook($(esc(ctx)), $(esc(f)), $(esc.(args)...)) where {$(esc.(ps)...)}
     $(esc(body))
    end)
end
