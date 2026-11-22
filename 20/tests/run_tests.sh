#!/usr/bin/env bash
# =============================================================================
# CS F301 Assignment 2 — group 20 — full test runner
#
# Runs every check for P1, P2, S1 and S2: toolchain versions, banned-construct
# scans, load checks, and the worked examples from the assignment PDF compared
# byte for byte against expected output.
#
# Usage, from anywhere:
#     bash 20/tests/run_tests.sh
#     bash 20/tests/run_tests.sh q1          # one problem only: q1 q2 q3 q4
#
# Exit status 0 if everything that exists passed, 1 otherwise.
# Solution files that do not exist yet are reported as SKIP, not FAIL, so this
# script is useful from the first commit onwards.
# =============================================================================

set -u

# --- locate the 20/ directory regardless of where we were invoked from -------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT" || exit 1

CODE="code"
TESTS="tests"
BUILD="$ROOT/.testbuild"
mkdir -p "$BUILD"

ONLY="${1:-all}"

PASS=0
FAIL=0
SKIP=0

# timeout(1) exists in WSL but not in Git Bash; degrade quietly.
if command -v timeout >/dev/null 2>&1; then
  TMO="timeout 25"
else
  TMO=""
fi

# --- reporting ---------------------------------------------------------------
pass() { PASS=$((PASS + 1)); printf '  [PASS] %s\n' "$1"; }
skip() { SKIP=$((SKIP + 1)); printf '  [SKIP] %s\n' "$1"; }
fail() {
  FAIL=$((FAIL + 1))
  printf '  [FAIL] %s\n' "$1"
  shift
  for line in "$@"; do printf '         %s\n' "$line"; done
}
section() { printf '\n== %s ==\n' "$1"; }

# compare_exact LABEL EXPECTED ACTUAL
compare_exact() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$label"
  else
    fail "$label" "expected:" "$(printf '%s' "$expected" | sed 's/^/           /')" \
                  "actual:" "$(printf '%s' "$actual" | sed 's/^/           /')"
  fi
}

# =============================================================================
# 0. Toolchain
# =============================================================================
section "toolchain"

if command -v swipl >/dev/null 2>&1; then
  SWIPL_V="$(swipl --version 2>&1 | head -1)"
  case "$SWIPL_V" in
    *" 9."*) pass "swipl present: $SWIPL_V" ;;
    *)       skip "swipl is not 9.x: $SWIPL_V" \
                  "the brief pins SWI-Prolog 9.x; code may rely on 9.x behaviour" ;;
  esac
  HAVE_SWIPL=1
else
  fail "swipl not on PATH" "install SWI-Prolog 9.2.9 and reopen the terminal"
  HAVE_SWIPL=0
fi

if command -v racket >/dev/null 2>&1; then
  RACKET_V="$(racket --version 2>&1 | head -1)"
  case "$RACKET_V" in
    *"v8."*) pass "racket present: $RACKET_V" ;;
    *)       skip "racket is not 8.x: $RACKET_V" \
                  "the brief pins Racket 8.x" ;;
  esac
  HAVE_RACKET=1
else
  fail "racket not on PATH" "install Racket 8.17 and reopen the terminal"
  HAVE_RACKET=0
fi

# =============================================================================
# 1. Banned-construct scans (static, cheap, catches mark-losers early)
# =============================================================================

# Prolog: strip % comments, then look for forbidden goals.
scan_prolog() {
  local f="$1" name hits
  name="$(basename "$f")"
  for name in assert asserta assertz retract \
              nb_setval b_setval nb_getval b_getval \
              initialization halt \
              term_to_atom term_string read_term_from_atom \
              clpfd; do
    hits="$(sed 's/%.*//' "$f" | grep -n "\b${name}\b" || true)"
    if [ -n "$hits" ]; then
      fail "$(basename "$f"): banned construct '${name}'" "$hits"
    fi
  done
  pass "$(basename "$f"): banned-construct scan complete"
}

# Racket: tokenise (so my-length does not trip 'length'), compare exactly.
scan_racket() {
  local f="$1" tokens banned t
  tokens="$(sed 's/;.*//' "$f" \
            | grep -oE "[A-Za-z_][A-Za-z0-9_!?*/<>=+-]*" \
            | sort -u)"
  banned="length append reverse map filter member memq list-ref list-tail
          equal? set! for for/list for/fold do printf format write print
          vector vector-ref make-vector hash hash-ref string string-append
          number->string string->number apply error void foldl foldr
          list->vector sort assv remove"
  for t in $banned; do
    if printf '%s\n' "$tokens" | grep -qx -- "$t"; then
      fail "$(basename "$f"): forbidden identifier '${t}'" \
           "$(grep -n -- "$t" "$f" | head -3)"
    fi
  done
  if [ "$(head -1 "$f")" = "#lang racket/base" ]; then
    pass "$(basename "$f"): #lang racket/base on line 1"
  else
    fail "$(basename "$f"): line 1 is not '#lang racket/base'" "got: $(head -1 "$f")"
  fi
}

# =============================================================================
# 2. P1 — department puzzle
# =============================================================================
run_q1() {
  section "P1 — 20_q1.pl"
  local f="$CODE/20_q1.pl"
  if [ ! -f "$f" ]; then skip "P1: $f does not exist yet"; return; fi
  if [ "$HAVE_SWIPL" -eq 0 ]; then skip "P1: swipl unavailable"; return; fi

  scan_prolog "$f"

  # Load check: a correct file loads silently.
  local load
  load="$($TMO swipl -q -g "consult('$f')" -t halt 2>&1)"
  if [ -z "$load" ]; then
    pass "P1: loads with no warnings"
  else
    fail "P1: output or warnings at load time" "$load"
  fi

  # P1.a — main/0 prints four lines in the specified layout, in name order.
  local out n
  out="$($TMO swipl -q -f "$f" -g main -t halt 2>&1)"
  n="$(printf '%s\n' "$out" | grep -c '' )"
  if [ "$n" -ne 4 ]; then
    fail "P1.a: main/0 printed $n lines, expected 4" "$out"
  else
    local ok=1 i=1
    for who in Alex Ben Carla Dana; do
      local line
      line="$(printf '%s\n' "$out" | sed -n "${i}p")"
      if ! printf '%s' "$line" \
           | grep -qE "^${who} = \[[a-z]+, [a-z+]+, [A-Za-z+]+\]$"; then
        fail "P1.a: line $i does not match '${who} = [dept, lang, project]'" "$line"
        ok=0
      fi
      i=$((i + 1))
    done
    [ "$ok" -eq 1 ] && pass "P1.a: four lines, correct layout and name order"
  fi

  # P1.b — count over clues 1..8. The value goes in P1_REPORT.md; we report it.
  local n8
  n8="$($TMO swipl -q -f "$f" \
        -g "count_solutions([1,2,3,4,5,6,7,8],N), format('~w~n',[N])" \
        -t halt 2>&1)"
  if printf '%s' "$n8" | grep -qE '^[0-9]+$'; then
    pass "P1.b: count_solutions([1..8],N) gives N = $n8  <- put this in P1_REPORT.md"
  else
    fail "P1.b: count_solutions([1..8],N) did not yield a number" "$n8"
  fi

  # Each clue must be callable on its own and must not throw.
  local c bad=0
  for c in 1 2 3 4 5 6 7 8; do
    local r
    r="$($TMO swipl -q -f "$f" \
         -g "( catch(count_solutions([$c],_),E,(print_message(error,E),fail)) -> true ; true )" \
         -t halt 2>&1)"
    if [ -n "$r" ]; then fail "P1: clue $c raised an error" "$r"; bad=1; fi
  done
  [ "$bad" -eq 0 ] && pass "P1: clues 1-8 individually callable without error"

  # P1.c — adding clue 9 must pin the puzzle to exactly one solution.
  local n9
  n9="$($TMO swipl -q -f "$f" \
        -g "count_solutions([1,2,3,4,5,6,7,8,9],N), format('~w~n',[N])" \
        -t halt 2>&1)"
  if [ "$n9" = "1" ]; then
    pass "P1.c: count_solutions([1..9],N) gives N = 1"
  else
    fail "P1.c: count_solutions([1..9],N) gave '$n9', required 1" \
         "clue 9 must be true in exactly one solution of clues 1-8"
  fi

  # P1.c — the English sentence of clue 9, and the no-names rule.
  if grep -q '^% CLUE 9:' "$f"; then
    pass "P1.c: '% CLUE 9:' comment present"
    local sentence
    sentence="$(grep '^% CLUE 9:' "$f")"
    if printf '%s' "$sentence" | grep -qE 'Alex|Ben|Carla|Dana'; then
      fail "P1.c: clue 9 names a friend, which the brief forbids" "$sentence"
    else
      pass "P1.c: clue 9 sentence names no friend"
    fi
  else
    fail "P1.c: no line starting '% CLUE 9:'" \
         "the English sentence goes directly above clue(9, Solution)"
  fi
}

# =============================================================================
# 3. P2 — arithmetic equation
# =============================================================================
run_q2() {
  section "P2 — 20_q2.pl"
  local f="$CODE/20_q2.pl"
  if [ ! -f "$f" ]; then skip "P2: $f does not exist yet"; return; fi
  if [ "$HAVE_SWIPL" -eq 0 ]; then skip "P2: swipl unavailable"; return; fi

  scan_prolog "$f"

  local load
  load="$($TMO swipl -q -g "consult('$f')" -t halt 2>&1)"
  if [ -z "$load" ]; then
    pass "P2: loads with no warnings"
  else
    fail "P2: output or warnings at load time" "$load"
  fi

  # P2.b — all_equations on the PDF's worked example, exact and in sort/2 order.
  local expected_4253='["4*2-5=3","4*2=5+3","4-2=5-3","4/2=5-3","4=2*(5-3)","4=2+(5-3)","4=2+5-3"]'
  local got
  got="$($TMO swipl -q -f "$f" \
         -g "all_equations([4,2,5,3],Es), format('~q~n',[Es])" -t halt 2>&1)"
  compare_exact "P2.b: all_equations([4,2,5,3],Es)" "$expected_4253" "$got"

  got="$($TMO swipl -q -f "$f" \
         -g "all_equations([2,3,4],Es), format('~q~n',[Es])" -t halt 2>&1)"
  compare_exact "P2.b: all_equations([2,3,4],Es)" "[]" "$got"

  got="$($TMO swipl -q -f "$f" \
         -g "all_equations([2,4,8],Es), format('~q~n',[Es])" -t halt 2>&1)"
  compare_exact 'P2.b: all_equations([2,4,8],Es)' '["2*4=8"]' "$got"

  got="$($TMO swipl -q -f "$f" \
         -g "count_equations([4,2,5,3],N), format('~w~n',[N])" -t halt 2>&1)"
  compare_exact "P2.b: count_equations([4,2,5,3],N)" "7" "$got"

  # P2.a — one valid equation, and it must be one of the seven.
  got="$($TMO swipl -q -f "$f" \
         -g "generate_equation([4,2,5,3],E), format('~w~n',[E])" -t halt 2>&1)"
  case "$got" in
    "4*2-5=3"|"4*2=5+3"|"4-2=5-3"|"4/2=5-3"|"4=2*(5-3)"|"4=2+(5-3)"|"4=2+5-3")
      pass "P2.a: generate_equation([4,2,5,3],E) gave a valid equation: $got" ;;
    *)
      fail "P2.a: generate_equation([4,2,5,3],E) gave '$got'" \
           "must be one of the seven equations listed in the PDF" ;;
  esac

  # P2.a — the result must be a string, not an atom or a code list.
  got="$($TMO swipl -q -f "$f" \
         -g "generate_equation([4,2,5,3],E), (string(E)->write(yes);write(no)), nl" \
         -t halt 2>&1)"
  compare_exact "P2.a: Equation is an SWI string, not an atom" "yes" "$got"

  # P2.a — must FAIL, not error and not loop, on degenerate input.
  local lst
  for lst in "[]" "[7]" "[2,3,4]"; do
    got="$($TMO swipl -q -f "$f" \
           -g "( catch(generate_equation($lst,_),E,(write(error(E)),nl,fail)) -> write(succeeded) ; write(failed) ), nl" \
           -t halt 2>&1)"
    compare_exact "P2.a: generate_equation($lst,E) fails cleanly" "failed" "$got"
  done
}

# =============================================================================
# 4. Racket drivers — created if absent, so they become committed deliverables
# =============================================================================
ensure_q3_driver() {
  local d="$TESTS/test_q3.rkt"
  [ -f "$d" ] && return
  printf 'note: creating %s (commit it — tests/ is a deliverable)\n' "$d"
  cat > "$d" <<'DRIVER'
;; S1 test driver. No #lang line: this file is appended to code/20_q3.rkt,
;; exactly the way the grader appends its own calls.
;; Run via: bash tests/run_tests.sh q3
(define t1 '(4 (2 (1 () ()) (3 () ())) (6 (5 () ()) (7 () ()))))
(define t2 '(1 () (2 () (3 () ()))))
(define t3 '(a (b () ()) (c () ())))

(print-inorder t1)             ;; (1 2 3 4 5 6 7)
(print-all-traversals t1)      ;; (1 2 3 4 5 6 7) (4 2 1 3 6 5 7) (1 3 2 5 7 6 4)
(print-height-and-leaves t1)   ;; (3 4)
(print-all-traversals t2)      ;; (1 2 3) (1 2 3) (3 2 1)
(print-height-and-leaves t2)   ;; (3 1)
(print-all-traversals t3)      ;; (b a c) (a b c) (b c a)
(print-height-and-leaves t3)   ;; (2 2)
(print-inorder '())            ;; ()
(print-all-traversals '())     ;; () () ()
(print-height-and-leaves '())  ;; (0 0)
DRIVER
}

ensure_q4_driver() {
  local d="$TESTS/test_q4.rkt"
  [ -f "$d" ] && return
  printf 'note: creating %s (commit it — tests/ is a deliverable)\n' "$d"
  cat > "$d" <<'DRIVER'
;; S2 test driver. No #lang line: appended to code/20_q4.rkt like the grader.
;; print-insert-result reads x, lst and n from stdin, so each case is piped in
;; by tests/run_tests.sh:
;;   42 ((1 2) (3 4 5) (6) ()) 3  ->  ((42 1 2) (3 4 5) (42 6) (42))
;;   0 (((1) 2) (3) ((4 5 6) ())) 3 -> ((0 (0 1) 2) (0 3) (0 (4 5 6) (0)))
;;   7 () 3                       ->  (7)
;;   7 () 0                       ->  ()
(print-insert-result)
DRIVER
}

# =============================================================================
# 5. S1 — tree traversals
# =============================================================================
run_q3() {
  section "S1 — 20_q3.rkt"
  local f="$CODE/20_q3.rkt"
  if [ ! -f "$f" ]; then skip "S1: $f does not exist yet"; return; fi
  if [ "$HAVE_RACKET" -eq 0 ]; then skip "S1: racket unavailable"; return; fi

  scan_racket "$f"

  # Load check: definitions only, so running the file prints nothing.
  local load
  load="$($TMO racket "$f" 2>&1)"
  if [ -z "$load" ]; then
    pass "S1: file prints nothing when run (definitions only)"
  else
    fail "S1: file produced output or an error on load" "$load"
  fi

  ensure_q3_driver
  local run="$BUILD/run_q3.rkt"
  cat "$f" "$TESTS/test_q3.rkt" > "$run"

  local expected got
  expected='(1 2 3 4 5 6 7)
(1 2 3 4 5 6 7)
(4 2 1 3 6 5 7)
(1 3 2 5 7 6 4)
(3 4)
(1 2 3)
(1 2 3)
(3 2 1)
(3 1)
(b a c)
(a b c)
(b c a)
(2 2)
()
()
()
()
(0 0)'
  got="$($TMO racket "$run" 2>&1)"
  compare_exact "S1: all PDF examples (18 lines)" "$expected" "$got"
}

# =============================================================================
# 6. S2 — conditional insert
# =============================================================================
run_q4() {
  section "S2 — 20_q4.rkt"
  local f="$CODE/20_q4.rkt"
  if [ ! -f "$f" ]; then skip "S2: $f does not exist yet"; return; fi
  if [ "$HAVE_RACKET" -eq 0 ]; then skip "S2: racket unavailable"; return; fi

  scan_racket "$f"

  # S2 may use read; nothing else is added to the whitelist.
  local load
  load="$($TMO racket "$f" 2>&1)"
  if [ -z "$load" ]; then
    pass "S2: file prints nothing when run (definitions only)"
  else
    fail "S2: file produced output or an error on load" "$load"
  fi

  # The final file must define insert-if-short exactly once (the make-inserter
  # one), and must define make-inserter, my-length and my-map.
  local defs
  defs="$(grep -c '(define (insert-if-short' "$f" || true)"
  if [ "$defs" = "1" ]; then
    pass "S2.c: exactly one definition of insert-if-short"
  else
    fail "S2.c: found $defs definitions of insert-if-short, required exactly 1" \
         "delete the S2.b version; keep only the one built on make-inserter"
  fi
  local nm
  for nm in make-inserter my-length my-map print-insert-result; do
    if grep -q -- "(define ($nm\|(define $nm " "$f"; then
      pass "S2: $nm defined"
    else
      fail "S2: $nm is not defined" "required by S2.a/S2.b/S2.c"
    fi
  done

  ensure_q4_driver
  local run="$BUILD/run_q4.rkt"
  cat "$f" "$TESTS/test_q4.rkt" > "$run"

  # The four worked examples from the PDF.
  local got
  got="$(printf '42 ((1 2) (3 4 5) (6) ()) 3\n' | $TMO racket "$run" 2>&1)"
  compare_exact "S2: 42 ((1 2) (3 4 5) (6) ()) 3" \
                "((42 1 2) (3 4 5) (42 6) (42))" "$got"

  got="$(printf '0 (((1) 2) (3) ((4 5 6) ())) 3\n' | $TMO racket "$run" 2>&1)"
  compare_exact "S2: 0 (((1) 2) (3) ((4 5 6) ())) 3" \
                "((0 (0 1) 2) (0 3) (0 (4 5 6) (0)))" "$got"

  got="$(printf '7 () 3\n' | $TMO racket "$run" 2>&1)"
  compare_exact "S2: 7 () 3" "(7)" "$got"

  got="$(printf '7 () 0\n' | $TMO racket "$run" 2>&1)"
  compare_exact "S2: 7 () 0  (n=0 inserts nothing)" "()" "$got"

  # Our own edge cases.
  got="$(printf 'z (1 2 3) 3\n' | $TMO racket "$run" 2>&1)"
  compare_exact "S2: z (1 2 3) 3  (length 3 is not < 3)" "(1 2 3)" "$got"

  got="$(printf 'z (1 2 3) 4\n' | $TMO racket "$run" 2>&1)"
  compare_exact "S2: z (1 2 3) 4  (top level qualifies)" "(z 1 2 3)" "$got"

  got="$(printf 'q ((())) 2\n' | $TMO racket "$run" 2>&1)"
  compare_exact "S2: q ((())) 2  (every level, innermost () too)" \
                "(q (q (q)))" "$got"

  # Scale: the hidden tests use depth 100 and 10,000 elements.
  local nums t0 t1s
  nums="$(seq 0 9999 | tr '\n' ' ')"
  t0=$(date +%s)
  if printf '9 (%s) 3\n' "$nums" | $TMO racket "$run" >/dev/null 2>&1; then
    t1s=$(date +%s)
    pass "S2: 10,000-element list completes in $((t1s - t0))s"
  else
    fail "S2: 10,000-element list failed or timed out" \
         "usually my-length called per element instead of once per list"
  fi

  local open close
  open="$(printf '(%.0s' $(seq 1 100))"
  close="$(printf ')%.0s' $(seq 1 100))"
  if printf '9 %s%s 2\n' "$open" "$close" | $TMO racket "$run" >/dev/null 2>&1; then
    pass "S2: nesting depth 100 completes"
  else
    fail "S2: nesting depth 100 failed or timed out" "check the recursive descent"
  fi
}

# =============================================================================
# 7. Repository deliverables
# =============================================================================
run_repo() {
  section "repository deliverables"
  local p
  for p in code/20_q1.pl code/20_q2.pl code/20_q3.rkt code/20_q4.rkt \
           skills/prolog-dev/SKILL.md skills/scheme-dev/SKILL.md \
           prompts/P1.md prompts/P2.md prompts/S1.md prompts/S2.md \
           P1_REPORT.md; do
    if [ -s "$p" ]; then pass "present: $p"; else skip "missing or empty: $p"; fi
  done
}

# =============================================================================
# main
# =============================================================================
case "$ONLY" in
  q1)  run_q1 ;;
  q2)  run_q2 ;;
  q3)  run_q3 ;;
  q4)  run_q4 ;;
  all) run_q1; run_q2; run_q3; run_q4; run_repo ;;
  *)   printf 'usage: bash tests/run_tests.sh [q1|q2|q3|q4]\n'; exit 2 ;;
esac

printf '\n-----------------------------------------\n'
printf 'passed %d   failed %d   skipped %d\n' "$PASS" "$FAIL" "$SKIP"
printf -- '-----------------------------------------\n'

[ "$FAIL" -eq 0 ] || exit 1
exit 0
