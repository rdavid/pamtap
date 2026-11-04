# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2026 David Rabkin
# SPDX-License-Identifier: 0BSD

# Loads the freshly built module into a throwaway PAM service and drives it
# with pamtester, then asserts the authentication landed in the log. The
# service marks the module sufficient and falls back to pam_permit, so the
# stack always terminates. A trap removes the service file whether the run
# passes or fails. Both the pamtester exit status and the log line are
# checked, so the run fails if the module stops succeeding or stops logging.
# The single argument is the module to load, relative to the current
# directory.
set -e
module=${1:-pamtap.so}
service=pamtap-test
log=/tmp/pamtap.log
pass=s3cr3t
svc=/etc/pam.d/$service
printf 'auth sufficient %s/%s\nauth required pam_permit.so\n' \
	"$(pwd)" "$module" | sudo tee "$svc" >/dev/null
trap 'sudo rm --force "$svc"' EXIT
rm --force "$log"
printf '%s\n' "$pass" | pamtester "$service" "$(id --user --name)" authenticate
grep --quiet "user:$(id --user --name), pass:$pass," "$log"
