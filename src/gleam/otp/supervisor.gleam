import gleam/list

// Test helpers
pub external type Pid(a)
pub external type Fail
pub external type OpaquePid

pub type Option(a) =
  Result(a, Nil)

pub type Start(a) =
  Result(Pid(a), Fail)

pub external fn erase(Pid(a)) -> OpaquePid = "" ""

pub external fn kill(Pid(a)) -> Nil = "" ""

// API

pub type Children(state) {
  Children(
    pids: List(OpaquePid),
    state: state,
    private_initialiser: Initialiser(Nil, state),
  )
}

pub type StartChildren(state) =
  Result(Children(state), Fail)

fn problem_flag(problem_pid: Option(OpaquePid), current_pid: OpaquePid) -> Option(OpaquePid) {
  case problem_pid {
    Ok(pid) if current_pid != pid -> problem_pid
    _ -> Error(Nil)
  }
}

pub type Initialiser(state_in, state_out) =
  fn(
    state_in,
    Option(OpaquePid),
  ) -> Result(tuple(state_out, List(OpaquePid)), Fail)

fn add_child(
  init: Initialiser(state_0, state_1),
  start: fn(state_1) -> Start(msg),
  merge: fn(state_1, Pid(msg)) -> state_2,
  existing_pid: Pid(msg),
  existing_state: state_2,
) -> Initialiser(state_0, state_2) {
  fn(state, problem_pid) {
    case init(state, problem_pid) {
      // Older siblings failed, exit early
      Error(fail) -> Error(fail)

      // Older siblings ok, initialise the new process
      Ok(tuple(state, pids)) -> {
        let opaque_pid = erase(existing_pid)

        case problem_pid {
          // This Pid is still alive, keep going.
          Ok(problem_pid) if problem_pid != opaque_pid -> {
            Ok(tuple(existing_state, [opaque_pid, ..pids]))
          }

          // This pid either is the cause of the problem, or we don't have problem
          // pid to compare with. In either case it must be restarted.
          _ -> {
            kill(existing_pid)
            case start(state) {
              Error(fail) -> Error(fail)
              Ok(new_pid) -> {
                let problem_pid = problem_flag(problem_pid, opaque_pid)
                let new_state = merge(state, new_pid)
                Ok(tuple(new_state, [erase(new_pid), ..pids]))
              }
            }
          }
        }
      }
    }
  }
}

pub fn empty() -> StartChildren(Nil) {
  Ok(Children(
    state: Nil,
    pids: [],
    private_initialiser: fn(state, _) { Ok(tuple(state, [])) },
  ))
}

pub fn worker(
  children: StartChildren(state),
  start start_child: fn(state) -> Start(msg),
  returning merge: fn(state, Pid(msg)) -> new_state
) -> StartChildren(new_state) {
  case children {
    Ok(Children(pids: pids, state: state, private_initialiser: init)) -> case start_child(state) {
      Ok(pid) -> {
        let state = merge(state, pid)
        let pids = [erase(pid), ..pids]
        let init = add_child(init, start_child, merge, pid, state)
        Ok(Children(pids, state, init))
      }

      Error(fail) -> Error(fail)
    }
  }
}

pub fn unreferenced_worker(
  children: StartChildren(state),
  start start_child: fn(state) -> Start(msg),
) -> StartChildren(state) {
  worker(children, start_child, fn(x, _) { x })
}

// Testing

pub fn start_child1(x: Nil) -> Start(Int) {
  todo
}

pub fn start_child2(older: Pid(Int)) -> Start(String) {
  todo
}

pub fn start_child3(older: Pid(Int)) -> Start(Float) {
  todo
}

pub fn supervisor_init() {
  empty()
  |> worker(start: start_child1, returning: fn(_state, pid) { pid })
  |> unreferenced_worker(start: start_child2)
  |> unreferenced_worker(start: start_child3)
}
