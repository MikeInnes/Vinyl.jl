using Vinyl: @reset, shift

# ---------------------------------------------------------------------------- #

# Simulate Functions
k = @reset 1 + shift(k -> k)

# This is equivalent to (x -> 1 + x)
# The reset block stops running at `shift`, and continues when we provide a
# value to `k`.

k(2) # 3
k(4) # 5

# ---------------------------------------------------------------------------- #

# Turning callbacks into straight-line code.
# Imagine this callback retreives a web page asynchronously.
load(cb, page) = (sleep(1);cb(page))

# Here's a JavaScript-style function that loads two pages. Awful!
function f(cb)
  load("page1") do page1
    load("page2") do page2
      cb((page1,page2))
    end
  end
end

f(print) # ("page1", "page2")

# Here's a version with continuations.
function f()
  @reset begin
    page1 = shift(k -> load(k, "page1"))
    page2 = shift(k -> load(k, "page2"))
    return (page1, page2)
  end
end

f() # ("page1", "page2")

# ---------------------------------------------------------------------------- #

# Hijacking Julia's control flow; we can explore both branches of
# an `if` statement.

quantum_predicate() = shift(k -> (k(true), k(false)))

function foo(x)
  quantum_predicate() && (x = -x)
  2x
end

@reset foo(5) # (-10, 10)

# Cartesian product of two bits:
@reset (quantum_predicate(), quantum_predicate())
