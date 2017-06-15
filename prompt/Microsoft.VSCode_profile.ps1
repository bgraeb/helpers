$wsroot = $pwd.path
function prompt {
    if ($executionContext.SessionState.Path.CurrentLocation.path -like "$wsroot*") {
        $subPath = $executionContext.SessionState.Path.CurrentLocation.path -replace ([regex]::Escape($wsroot))
        "PS WS:$subPath> ";
    }
    else {
        "PS $($executionContext.SessionState.Path.CurrentLocation.path)$('>' * ($nestedPromptLevel + 1)) ";
    }
}
