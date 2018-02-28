using ASTInterpreter2
using DebuggerFramework: execute_command, dummy_state

isdone(state) = isempty(state.stack)

frame(state) = state.stack[state.level]

function expr(state)
  fr = frame(state)
  expr = ASTInterpreter2.pc_expr(fr, fr.pc)
end

step!(state) =
  execute_command(state, state.stack[state.level], Val{:nc}(), "nc")

stepin!(state) =
  execute_command(state, state.stack[state.level], Val{:s}(), "s")

lookup(frame, x) = x
lookup(frame, x::SSAValue) = frame.ssavalues[x.id+1]
lookup(frame, x::SlotNumber) = get(frame.locals[x.id])

function callargs(state)
  ex = expr(state)
  isexpr(ex, :(=)) || return
  ex = ex.args[2]
  Meta.isexpr(ex, :call) || return
  lookup.(frame(state), ex.args)
end

function runall(ctx, state)
  while true
    if (ex = callargs(state)) ≠ nothing
      hook(ctx, ex...)
      stepin!(state)
    else
      step!(state)
    end
    isdone(state) && return state.overall_result
  end
end

macro overdub(ctx, ex)
  quote
    f = () -> $(esc(ex))
    state = dummy_state(@make_stack f())
    runall($(esc(ctx)), state)
  end
end
