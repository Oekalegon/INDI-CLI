import INDIMCPKit

/// Renders a `ScriptRunStarted` the way every device-command subcommand reports its result: the
/// command only starts a script run server-side, so this is what the CLI has to show immediately
/// (use `script status <run-id>` to follow it to completion).
func describe(_ started: ScriptRunStarted) -> String {
    "Started '\(started.script)' on rig '\(started.rigId)' as run \(started.runId)."
}

func describe(_ outcome: PauseOutcome) -> String {
    switch outcome {
    case .paused(let p):
        return "\(p.runId): paused at step \(p.pausedAtStep)"
    case .rejected(let r):
        return "\(r.runId): pause rejected — \(r.reason)"
    }
}

func describe(_ outcome: ResumeOutcome) -> String {
    switch outcome {
    case .resumed(let r):
        return "\(r.runId): resumed at step \(r.resumedAtStep)"
    case .rejected(let r):
        return "\(r.runId): resume rejected — \(r.reason)"
    }
}

func describe(_ status: ScriptRunStatus) -> String {
    switch status {
    case .started(let s):
        return "\(s.runId): started"
    case .progress(let p):
        return "\(p.runId): in progress — \(p.message ?? "no message")"
    case .completed(let c):
        return "\(c.runId): completed"
    case .failed(let f):
        return "\(f.runId): failed — \(f.error.message)"
    case .cancelled(let c):
        return "\(c.runId): cancelled"
    case .paused(let p):
        return "\(p.runId): paused"
    case .resumed(let r):
        return "\(r.runId): resumed"
    case .pauseRejected(let r):
        return "\(r.runId): pause rejected — \(r.reason)"
    }
}
