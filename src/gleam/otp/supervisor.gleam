pub external type Pid

pub enum Strategy {
  OneForOne
  OneForAll
  RestForOne
}

pub enum Restart {
  Permanent
  Transient
  Temporary
}

pub enum ShutdownGracePeriod {
  Infinity
  BrutalKill
  Timeout(Int)
}

pub enum ChildType {
  Supervisor

  // Supervisors have a shutdown grace period of infinity so only require a
  // shutdown for workers
  Worker(ShutdownGracePeriod)
}

pub enum StartLinkResult {
  Started(Pid)
  AlreadyStarted(Pid)
  Shutdown(String)
  Ignored
}

pub struct ChildSpec {
  id: String
  start: fn() -> StartLinkResult
  restart: Restart
  child_type: ChildType
}


pub enum StartResult {
  IgnoreSupervisor

  StartSupervisor(
    Strategy,
    Int, // intensity
    Int, // period
    List(ChildSpec),
  )
}

pub enum Name {
  Named(String)
  Unnamed
}

pub external fn start_link(Name, fn() -> StartResult) -> StartLinkResult
  = "todo" "todo"

// Module:init(Args) -> Result
// Types
// Args = term()
// Result = {ok,{SupFlags,[ChildSpec]}} | ignore
//  SupFlags = sup_flags()
//  ChildSpec = child_spec()
//
//  sup_flags() =
// #{strategy => strategy(),
//   intensity => integer() >= 0,
//   period => integer() >= 1} |
// {RestartStrategy :: strategy(),
//  Intensity :: integer() >= 0,
//  Period :: integer() >= 1}
//
//  child_spec() =
// #{id := child_id(),
//   start := mfargs(),
//   restart => restart(),
//   shutdown => shutdown(),
//   type => worker(),
//   modules => modules()} |
// {Id :: child_id(),
//  StartFunc :: mfargs(),
//  Restart :: restart(),
//  Shutdown :: shutdown(),
//  Type :: worker(),
//  Modules :: modules()}
