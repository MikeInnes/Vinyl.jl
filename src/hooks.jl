hook(ctx, f, args...) = return

isprimitive(ctx, f, args...) = false
function primitive end

macro hook(ctx, f)
  def = splitdef(f)
  f, args, body, ps = def[:name], def[:args], def[:body], def[:whereparams]
  ctx isa Symbol && (ctx = :(::$ctx))
  isexpr(f, :(::)) || (f = :(::typeof($f)))
  :(function hook($(esc(ctx)), $(esc(f)), $(esc.(args)...)) where {$(esc.(ps)...)}
     $(esc(body))
    end)
end

macro primitive(ctx, f)
  def = splitdef(f)
  f, args, body, ps = def[:name], def[:args], def[:body], def[:whereparams]
  ctx isa Symbol && (ctx = :(::$ctx))
  isexpr(f, :(::)) || (f = :(::typeof($f)))
  quote
    Vinyl.isprimitive($(esc(ctx)), $(esc(f)), $(esc.(args)...)) where {$(esc.(ps)...)} = true
    function Vinyl.primitive($(esc(ctx)), $(esc(f)), $(esc.(args)...)) where {$(esc.(ps)...)}
      $(esc(body))
    end
  end
end
