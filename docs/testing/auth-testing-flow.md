# Auth Testing Flow

This document defines how to run and evaluate authentication tests in `Orbit-flutter`.

## Quick commands

- Run only auth unit tests:
  - `flutter test test/ui/auth/view_model/auth_view_model_test.dart`
- Run auth tests with detailed output:
  - `flutter test test/ui/auth/view_model/auth_view_model_test.dart --reporter expanded`
- Run auth tests with coverage:
  - `flutter test --coverage test/ui/auth/view_model/auth_view_model_test.dart`
- Run all project tests:
  - `flutter test`

## Coverage output

When running with `--coverage`, Flutter writes LCOV output to:

- `coverage/lcov.info`

To inspect `AuthViewModel` file coverage quickly:

```bash
python3 - <<'PY'
from pathlib import Path
p=Path('coverage/lcov.info')
text=p.read_text()
for b in text.split('end_of_record'):
    if 'SF:lib/ui/auth/view_model/auth_view_model.dart' in b:
        lf=lh=0
        for line in b.splitlines():
            if line.startswith('LF:'): lf=int(line[3:])
            if line.startswith('LH:'): lh=int(line[3:])
        pct=(lh/lf*100) if lf else 0
        print(f'LF={lf} LH={lh} COVERAGE={pct:.2f}%')
        break
PY
```

## Current unit test scope (Auth)

The file `test/ui/auth/view_model/auth_view_model_test.dart` covers:

- `login()`: validation, success state, exception path
- `register()`: invalid email/password/mismatch, success, exception path
- `sendRegistrationOTP()`: validation, success, exception path
- `requestPasswordReset()`: validation, success
- `confirmPasswordReset()`: invalid token, weak password, mismatch, success, exception
- `logout()`: local state cleared even if API fails
- `loadProfile()`: unauthenticated guard + success
- `updateProfile()`: unauthenticated guard + success
- `completeRegistration()`: username edge cases, password checks, success, exception
- `checkAuthStatus()`: unauthenticated, invalid storage, valid token, failed verification

## PR checklist for auth changes

For any change touching auth flow:

- [ ] `flutter test test/ui/auth/view_model/auth_view_model_test.dart` passes
- [ ] New auth behavior has a unit test (success + at least one failure path)
- [ ] Validation changes include matching error-message tests
- [ ] `flutter test --coverage test/ui/auth/view_model/auth_view_model_test.dart` is run
- [ ] Coverage for `auth_view_model.dart` does not regress significantly

## Suggested CI gate (auth path)

Add a lightweight PR job that runs:

- `flutter test test/ui/auth/view_model/auth_view_model_test.dart`

And a nightly/full job that runs:

- `flutter test --coverage`

