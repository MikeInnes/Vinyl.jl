using ASTInterpreter2
using ASTInterpreter2: JuliaStackFrame, JuliaProgramCounter, enter_call_expr,
  do_assignment!, lookup_var_if_var, pc_expr
using DebuggerFramework: execute_command, dummy_state, print_locdesc

struct InterpreterError <: Exception
  err
  trace

  InterpreterError(ierr::InterpreterError, stack) = new(ierr.err, vcat(ierr.trace, stack))
  InterpreterError(err::Exception, stack) = new(err, stack)
end

isdone(state) = isempty(state.stack)

frame(state) = state.stack[state.level]

function expr(state)
  fr = frame(state)
  expr = pc_expr(fr, fr.pc)
end

step!(state) =
  execute_command(state, state.stack[state.level], Val{:se}(), "se")

stepin!(state) =
  execute_command(state, state.stack[state.level], Val{:s}(), "s")

lookup(frame, var) = lookup_var_if_var(frame, var)
lookup(frame, x::QuoteNode) = x.value

function callargs(state)
  ex = expr(state)
  isexpr(ex, :(=)) && (ex = ex.args[2])
  isexpr(ex, :call) || return
  args = lookup.(frame(state), ex.args)
  args[1] == Core._apply && (args = [args[2], Iterators.flatten(args[3:end])...])
  return args
end

primitive_(ctx, state, a...) = primitive(ctx, a...)

function provide_result!(state, x)
  do_assignment!(frame(state), expr(state).args[1], x)
end

function inc_pc!(state)
  state.stack[1] = JuliaStackFrame(state.stack[1], JuliaProgramCounter(frame(state).pc.next_stmt+1))
end

unwrap(x) = x
unwrap(x::QuoteNode) = x.value
unwrap(x::Expr) = isexpr(x,:copyast) ? unwrap(x.args[1]) : x

meth(x) = x.meth

function runall(ctx, state)
  while !isdone(state)
    try
      if (ex = callargs(state)) ≠ nothing
        hook(ctx, ex...)
        if isprimitive(ctx, ex...)
          result = primitive_(ctx, state, ex...)
          isexpr(expr(state), :(=)) && provide_result!(state, result)
          inc_pc!(state)
        else
          stepin!(state)
        end
      else
        step!(state)
      end
    catch err
      throw(InterpreterError(err, state.stack))
    end
  end
  return unwrap(state.overall_result)
end

function overdub(ctx, f, args...)
  frame = enter_call_expr(:($f($(args...))))
  frame == nothing && return f(args...)
  runall(ctx, dummy_state([frame]))
end

macro overdub(ctx, ex)
  :(overdub($(esc(ctx)), () -> $(esc(ex))))
end

function Base.showerror(io::IOContext, ierr::InterpreterError)
  showerror(io, ierr.err)
  println(io, "\nStacktrace of evaluated expression:")
  for (num, frame) in enumerate(ierr.trace)
      print(io, "[$num] ")
      print_locdesc(io, frame)
  end
end
