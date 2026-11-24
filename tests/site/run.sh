#!/usr/bin/env bash
# Prove an image: create a site with every app of apps.json and serve it through gunicorn and nginx.
#
#   tests/site/run.sh IMAGE        for example tests/site/run.sh erpnext_germanized:local
#
# MariaDB, Redis and the containers of IMAGE come from compose.yaml next to this script. Every container and
# volume of the test is removed when it ends, and it fails after 20 minutes.
set -euo pipefail

readonly TIME_LIMIT=20m
readonly SITE=test.localhost

if [[ $# -ne 1 || -z "$1" ]]; then
	echo "usage: tests/site/run.sh IMAGE" >&2
	exit 1
fi
for tool in docker jq timeout; do
	if ! command -v "$tool" >/dev/null; then
		echo "tests/site/run.sh needs $tool" >&2
		exit 1
	fi
done

if [[ -z "${SITE_TEST_UNDER_TIME_LIMIT:-}" ]]; then
	export SITE_TEST_UNDER_TIME_LIMIT=1
	exec timeout --kill-after=1m "$TIME_LIMIT" "$BASH" "$0" "$@"
fi

image=$1
here=$(cd "$(dirname "$0")" && pwd)
apps_json="$here/../../apps.json"
export SITE_TEST_IMAGE="$image"
compose=(docker compose --file "$here/compose.yaml" --ansi never --progress plain)

step() {
	printf '\n==> %s\n' "$*"
}

fail() {
	printf '\nsite test failed: %s\n' "$*" >&2
	exit 1
}

# A command in a one-off container of the image, after its entrypoint has linked the assets.
in_bench() {
	"${compose[@]}" run --rm --no-deps --quiet-pull -T bench "$@"
}

# The entrypoint prints a line of its own, so commands whose output is parsed skip it.
bench_output() {
	"${compose[@]}" run --rm --no-deps --quiet-pull -T --entrypoint bench bench "$@"
}

# Run a Python function on the site with bench execute; it must return a PDF. bench prints the bytes it
# returns as a JSON list of numbers on its last line, and a failure exits nonzero with the traceback.
expect_pdf() {
	local function=$1 output pdf
	output=$(bench_output --site "$SITE" execute "$@") || fail "$function raised an error"
	pdf=$(tail -n 1 <<<"$output")
	if [[ $(jq -r '.[0:5] | implode' <<<"$pdf" 2>/dev/null) != "%PDF-" ]]; then
		fail "$function returned no PDF"
	fi
	echo "$function returned a PDF of $(jq length <<<"$pdf") bytes"
}

# Ask a url from inside a running service until it answers, for up to two minutes.
wait_for() {
	local service=$1 url=$2 answer
	shift 2
	for _ in {1..60}; do
		if answer=$("${compose[@]}" exec -T "$service" curl -fsS "$@" "$url" 2>/dev/null); then
			printf '%s\n' "$answer"
			return 0
		fi
		sleep 2
	done
	fail "$service did not answer $url within two minutes"
}

cleanup() {
	local status=$?
	trap - EXIT
	if [[ $status -ne 0 ]]; then
		step "last logs of the services"
		"${compose[@]}" logs --no-color --tail 100 || true
	fi
	step "removing the containers and volumes"
	"${compose[@]}" down --volumes --remove-orphans || true
	if [[ $status -eq 0 ]]; then
		printf '\nsite test passed: %s\n' "$image"
	fi
	exit "$status"
}

trap cleanup EXIT
trap 'echo "site test interrupted" >&2; exit 130' INT
trap 'echo "site test stopped, the time limit is $TIME_LIMIT" >&2; exit 143' TERM

step "apps of $image against apps.json"
mapfile -t pinned < <(jq -r '.[] | "\(.url) \(.branch)"' "$apps_json")
# The module names bench installs are not always the repository names, and apps.txt does not always keep
# the order of apps.json, so the names and the tags come from the manifest bench writes, in the order in
# which it fetched the apps.
manifest=$(docker run --rm --quiet --entrypoint cat "$image" sites/apps.json)
mapfile -t names < <(jq -r 'to_entries | sort_by(.value.idx) | .[].key' <<<"$manifest")
if [[ ${#names[@]} -ne $((${#pinned[@]} + 1)) || "${names[0]}" != frappe ]]; then
	fail "the image has the apps ${names[*]}, apps.json lists ${#pinned[@]} apps besides frappe"
fi
# Every pinned tag must have been built once; two apps may share a tag, so each match is used up.
mapfile -t built < <(jq -r 'to_entries | sort_by(.value.idx) | .[1:] | .[] | "\(.key) \(.value.resolution.branch // "unknown")"' <<<"$manifest")
for pin in "${pinned[@]}"; do
	read -r url tag <<<"$pin"
	found=""
	for index in "${!built[@]}"; do
		read -r name branch <<<"${built[index]}"
		if [[ "$branch" == "$tag" ]]; then
			found=$name
			unset 'built[index]'
			break
		fi
	done
	if [[ -z "$found" ]]; then
		fail "no app of the image was built from $tag of $url; the image has ${built[*]}"
	fi
	printf '  %-16s %-10s %s\n' "$found" "$tag" "$url"
done

step "Ghostscript for the PDF/A-3 invoices of eu_einvoice"
docker run --rm --quiet --entrypoint gs "$image" --version
profiles=$(docker run --rm --quiet --entrypoint find "$image" -L /usr/share/ghostscript -name srgb.icc)
if [[ -z "$profiles" ]]; then
	fail "Ghostscript has no srgb.icc profile, which eu_einvoice needs for PDF/A-3"
fi

step "starting MariaDB and Redis"
"${compose[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true
"${compose[@]}" up --detach --quiet-pull --wait --wait-timeout 180 db redis

step "configuring common_site_config.json"
in_bench bench set-config -g db_host db
in_bench bench set-config -g redis_cache redis://redis:6379
in_bench bench set-config -g redis_queue redis://redis:6379
in_bench bench set-config -g redis_socketio redis://redis:6379
# As in examples/compose.yaml: without chromium_path, Frappe downloads a Chromium of its own for the first PDF
# and the test would prove that download instead of the Chromium of the image.
in_bench bench set-config -g chromium_path /usr/lib/chromium/chromium-headless-shell

step "creating $SITE with ${names[*]:1}"
install=()
for name in "${names[@]:1}"; do
	install+=(--install-app "$name")
done
# The passwords are set in compose.yaml and expanded inside the container.
# shellcheck disable=SC2016
new_site='exec bench new-site "$@" --db-root-password "$DB_ROOT_PASSWORD" --admin-password "$ADMIN_PASSWORD"'
in_bench bash -c "$new_site" new-site "$SITE" \
	--mariadb-user-host-login-scope=% --db-root-username root "${install[@]}"

step "apps installed on $SITE"
installed=$(bench_output --site "$SITE" list-apps --format json | sed -n '/^{/,$p')
jq -r --arg site "$SITE" '.[$site] | join(" ")' <<<"$installed"
for name in "${names[@]}"; do
	if ! jq -e --arg site "$SITE" --arg app "$name" '.[$site] | index($app)' <<<"$installed" >/dev/null; then
		fail "$name is not installed on $SITE"
	fi
done

step "making $SITE the default site"
in_bench bench use "$SITE"

# Frappe 16 prints with the generator of the print format, else with the one of the print settings: chrome
# on a new site, wkhtmltopdf where an operator chose it. Each has a binary of its own per platform.
step "PDF with wkhtmltopdf, page numbers in the footer"
expect_pdf frappe.utils.pdf.get_pdf \
	--args '["<h1>PDF test</h1>", {"footer-center": "Page [page] of [topage]"}]'

step "PDF with Chromium, the default generator of the print settings"
expect_pdf frappe.get_print \
	--kwargs '{"doctype": "User", "name": "Administrator", "as_pdf": True, "pdf_generator": "chrome"}'

# The default site serves bench and Socket.IO; gunicorn takes the site of a request from its Host header.
step "backend: gunicorn, the default command of the image"
"${compose[@]}" up --detach --no-deps backend
pong=$(wait_for backend http://localhost:8000/api/method/ping -H "Host: $SITE")
echo "$pong"
[[ "$pong" == *'"pong"'* ]] || fail "the backend answered the ping with $pong"
login=$("${compose[@]}" exec -T backend curl -fsS -H "Host: $SITE" http://localhost:8000/login)
grep -qi '<html' <<<"$login" || fail "the login page of the backend is no HTML"
echo "the login page is HTML"

# Engine.IO answers the opening request of a client with its session before any authentication.
step "socketio: node socketio.js on the Node.js packages left after the build"
"${compose[@]}" up --detach --no-deps socketio
handshake=$(wait_for socketio "http://localhost:9000/socket.io/?EIO=4&transport=polling" -H "Host: $SITE")
echo "$handshake"
[[ "$handshake" == '0{"sid":'* ]] || fail "Socket.IO answered the handshake with $handshake"

# Socket.IO loads <app>/realtime/handlers.js only for an authenticated connection, inside a try/catch that merely
# warns, so a handler that lost a package would fail silently; loading each one directly fails loudly instead.
step "socketio: the realtime handlers of every app load"
# shellcheck disable=SC2016 # expanded by the shell inside the container
docker run --rm --quiet --entrypoint sh --workdir /home/frappe/frappe-bench/apps "$image" -c '
	found=0
	for handlers in */realtime/handlers.js; do
		[ -f "$handlers" ] || continue
		found=1
		node -e "require(process.argv[1])" "$PWD/$handlers" || exit 1
		echo "$handlers loads"
	done
	[ "$found" = 1 ] || echo "no app has realtime handlers"
' || fail "the realtime handlers of an app do not load"

step "frontend: nginx in front of the backend"
"${compose[@]}" up --detach --no-deps frontend
pong=$(wait_for frontend http://localhost:8080/api/method/ping -H "Host: $SITE")
echo "$pong"
[[ "$pong" == *'"pong"'* ]] || fail "the frontend answered the ping with $pong"
bundle=$("${compose[@]}" exec -T frontend jq -r '[.[]][0]' /home/frappe/frappe-bench/assets/assets.json)
"${compose[@]}" exec -T frontend curl -fsS -o /dev/null -H "Host: $SITE" "http://localhost:8080$bundle" ||
	fail "nginx does not serve the asset $bundle"
echo "nginx serves $bundle"
handshake=$("${compose[@]}" exec -T frontend curl -fsS -H "Host: $SITE" \
	"http://localhost:8080/socket.io/?EIO=4&transport=polling")
[[ "$handshake" == '0{"sid":'* ]] || fail "nginx does not pass /socket.io/ to Socket.IO: $handshake"
echo "nginx passes /socket.io/ to Socket.IO"

# The desk loads some libraries at run time from node_modules, such as qz-tray for printing; the build stage
# keeps exactly those, so every such path in the built bundles has to answer.
step "frontend: the libraries the browser loads from node_modules"
# The character class leaves out the quotes, backticks, $, { and } of template literals, which name no file.
# shellcheck disable=SC2016 # $ is a literal character of the pattern
mapfile -t libraries < <("${compose[@]}" exec -T frontend sh -c \
	'grep -rhoE "/?assets/[a-z0-9_]+/node_modules/[^\"'"'"' )\`\${},]+\.(js|css)" /home/frappe/frappe-bench/assets/*/dist' |
	sed 's#^/*#/#' | sort -u)
[[ ${#libraries[@]} -gt 0 ]] || fail "the built bundles name no library under node_modules; the search has gone stale"
for library in "${libraries[@]}"; do
	"${compose[@]}" exec -T frontend curl -fsS -o /dev/null -H "Host: $SITE" "http://localhost:8080$library" ||
		fail "nginx does not serve $library"
	echo "nginx serves $library"
done

# Saving a Website Theme compiles its SCSS with node generate_bootstrap_theme.js, which needs sass and the
# packages the SCSS of the apps imports, such as Bootstrap; the build stage keeps them for this. The custom SCSS
# uses $primary, a variable of Bootstrap, so the stylesheet only compiles when the import of Bootstrap works.
step "Website Theme: a custom theme compiles and nginx serves it"
# shellcheck disable=SC2016 # $primary is SCSS, not a shell variable
theme=$(bench_output --site "$SITE" execute frappe.client.insert \
	--args '[{"doctype": "Website Theme", "theme": "Site Test", "custom": 1,
		"custom_scss": ".site-test { color: $primary; }"}]' 2>&1) ||
	fail "saving a Website Theme raised an error: $theme"
theme_url=$(tail -n 1 <<<"$theme" | jq -r '.theme_url // empty')
[[ "$theme_url" == /files/website_theme/*.css ]] || fail "the Website Theme has no compiled stylesheet: $theme"
stylesheet=$("${compose[@]}" exec -T frontend curl -fsS -H "Host: $SITE" "http://localhost:8080$theme_url") ||
	fail "nginx does not serve $theme_url"
[[ "$stylesheet" == *".site-test{color:"* ]] || fail "the stylesheet $theme_url lacks the rule of the custom SCSS"
echo "nginx serves $theme_url with the custom SCSS compiled against Bootstrap"
