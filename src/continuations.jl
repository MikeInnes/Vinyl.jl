using Debugger: DebuggerState

copy_stack(::Nothing) = nothing

copy_stack(fd::FrameData) =
  FrameData(copy(fd.locals), copy(fd.ssavalues), copy(fd.sparams),
  fd.exception_frames, fd.last_exception, fd.caller_will_catch_err,
  fd.last_reference, fd.callargs)

copy_stack(st::Frame) =
  Frame(st.framecode, copy_stack(st.framedata),
  st.pc, st.assignment_counter, copy_stack(st.caller), st.callee)

copy_stack(st::DebuggerState) =
  DebuggerState(copy_stack(st.frame), st.level, st.broke_on_error,
  st.watch_list, st.lowered_status, st.mode,
  st.repl, st.terminal, st.main_mode,
  st.julia_prompt, st.standard_keymap, st.overall_result)

function reset_(f)
  try f()
  catch e
    e isa InterpreterError || rethrow()
    p = e.err
    p isa Tuple{Any,Continuation} || rethrow()
    return p[1](p[2])
  end
end

struct Continuation
  st::DebuggerState
end

Base.show(io::IO, ::Continuation) = print(io, "Continuation()")

function (c::Continuation)(x = nothing)
  st = copy_stack(c.st)
  provide_result!(st, x)
  inc_pc!(st)
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
