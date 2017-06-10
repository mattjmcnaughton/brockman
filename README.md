# Brockman

![Image of Kent Brockman](logo/brockman.png)

*brockman* is a lightweight bash utility for reporting on background unix
processes.

## Install

Installing *brockman* is easy - just run `wget
https://raw.githubusercontent.com/mattjmcnaughton/brockman/master/brockman.sh`.
Place the downloaded file in a directory included in your `$PATH`. Finally, run
`chmod u+x` on `brockman.sh` to allow execution.

## Usage

*brockman* defines four main options: `report`, `failure`,
`view`, and `resolve`. These operations handle running a background task
with *brockman* reporting on errors, whether an error occurred on a task on
which *brockman* reported, viewing the errors *brockman* reported,
and resolving errors reported by *brockman*.

### Report

`report` runs a given command, and monitors whether the operation fails. If
failure, *brockman* will log both an `alert` that the task failed, and an
`error` log of the failure. It logs these errors to
`~/.brockman/{alert,error}.log` respectively.

Ex: `brockman.sh --report "clamscan -r ~/"`

### Failure

`failure` succeeds if *brockman* has unresolved errors, and fails if not.

Ex: `brockman.sh --failure`

### View

`view` displays the results of any failures. It outputs either the `alert` log,
which is a brief description of the command which failed, or the `error` log,
which is the entire output of `stderr` for the failed command.

Ex: `brockman.sh --view [alert|error]`

### Resolve

`resolve` clears out all errors tracked by *brockman* thus far. You should only
call it after you've copied whatever info you need from *brockman* logs to a
more permanent location.

Ex: `brockman.sh --resolve`

## Use cases

*brockman* supports many use cases, following the unix philosophy of performing
a single task well.

I use it for monitoring nightly updates, anti-virus scans, and local ansible
playbook runs. I run these cron jobs with `brockman.sh --report "$CMD"` and then
add `brockman.sh --failure` to alert if one of these tasks failed when I open a
new shell. If there has been a failure, I use `brockman.sh --view alert` and
`brockman.sh --view error` to investigate further. Finally, after resolving the
issue, I run `brockman.sh --resolve` so *brockman* won't alert me to this error
again.

## Contributing

Contributions are welcome :dog: Please open an
[issue](https://github.com/mattjmcnaughton/brockman/issues) or [pull
request](https://github.com/mattjmcnaughton/brockman/pulls).

## License

[Apache](https://github.com/mattjmcnaughton/brockman/blob/master/LICENSE).
