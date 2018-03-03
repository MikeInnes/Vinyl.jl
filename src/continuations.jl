using DebuggerFramework: DebuggerState

copy_stack(st::JuliaStackFrame) =
  JuliaStackFrame(st.meth, st.code, copy(st.locals), copy(st.ssavalues),
                  st.sparams, st.exception_frames, st.last_exception, st.pc,
                  st.last_reference, st.wrapper, st.generator, st.fullpath)

copy_stack(st::DebuggerState) =
  DebuggerState(copy_stack.(st.stack), st.level, st.repl, st.main_mode,
                st.language_modes, st.standard_keymap, st.terminal,
                st.overall_result)

function reset_(f)
  try f()
  catch e
    e isa Tuple{Any,Continuation} || rethrow()
    return e[1](e[2])
  end
end

struct Continuation
  st::DebuggerState
end

Base.show(io::IO, ::Continuation) = print(io, "Continuation()")

function (c::Continuation)(x)
  st = copy_stack(c.st)
  provide_result!(st, x)
  reset_(() -> runall(Continuations(), st))
end

struct Continuations end

function reset(f)
  reset_(() -> overdub(Continuations(), f))
end

@primitive Continuations reset(f) = overdub(Continuations(), f)

shift(f) = error("`shift` only works inside `reset`")

isprimitive(::Continuations, ::typeof(shift), f) = true

primitive_(::Continuations, state, ::typeof(shift), f) =
  throw((f, Continuation(state)))

macro reset(ex)
  :(reset(() -> $(esc(ex))))
end
