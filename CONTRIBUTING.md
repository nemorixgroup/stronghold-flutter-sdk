# Contributing to stronghold_flutter_sdk

Thank you for your interest in contributing to the first native Flutter/Dart SDK
for the SHx token ecosystem on Stellar. This document defines the standards and workflow for
all contributions.

---

## Table of Contents

1. [Development Setup](#1-development-setup)
2. [Branch Strategy](#2-branch-strategy)
3. [Commit Conventions](#3-commit-conventions)
4. [Code Standards](#4-code-standards)
5. [Testing Standards](#5-testing-standards)
6. [Pre-Commit Gate](#6-pre-commit-gate)
7. [Pull Request Process](#7-pull-request-process)
8. [Adding a New Feature](#8-adding-a-new-feature)
9. [Security Policy](#9-security-policy)

---

## 1. Development Setup

**Requirements:**

- Flutter SDK >= 3.32.0
- Dart SDK >= 3.8.0
- Windows + PowerShell (primary dev environment)

**Clone and setup:**

```yaml
git clone https://github.com/nemorixgroup/stronghold-flutter-sdk.git
cd stronghold-flutter-sdk
git checkout develop
flutter pub get
```

**Verify setup:**

```yaml
.\scripts\pre_commit.ps1
```

All checks must pass green before your first change.

---

## 2. Branch Strategy

main <- stable releases only (tagged)
develop <- integration branch for all features
feature/* <- one branch per feature or fix

**Branch naming:**

Examples:
feature/escrow-testnet-verification
feature/asset-path-payment
fix/governance-vote-encoding
docs/readme-quick-start

**Rules:**

- Never commit directly to `main` or `develop`
- Every feature branch is created from `develop`
- Merges to `develop` via Pull Request only
- Merges to `main` via Pull Request from `develop` at release time

---

## 3. Commit Conventions

This project uses **Conventional Commits**.
Format: `<type>(<scope>): <description>`

| Type       | When to use                         |
|------------|--------------------------------------|
| `feat`     | New feature or capability           |
| `fix`      | Bug fix                             |
| `test`     | Adding or updating tests            |
| `docs`     | Documentation changes only          |
| `refactor` | Code change with no behavior change |
| `chore`    | Build, deps, CI, tooling            |
| `perf`     | Performance improvement             |

**Scope examples:**

feat(asset): add SHx path payment builder
feat(escrow): implement getEscrow storage read
fix(governance): correct ManageData value encoding
test(escrow): add lock/unlock Testnet integration tests
docs(readme): add quick start example
chore(ci): add coverage threshold check

**Rules:**

- Description in lowercase, no period at end
- One logical change per commit
- If a commit closes an issue: add `Closes #42` in the body

---

## 4. Code Standards

**Linter:** `very_good_analysis`, zero warnings, zero infos (`dart analyze --fatal-infos`).

**Section comments:** Use `// ---- Section Name ----` for logical grouping:

```yaml
// ---- Constructor ----
// ---- Fields ----
// ---- Public Methods ----
// ---- Private Methods ----
```

**Documentation:** Every public API element must have a dartdoc comment:

```dart
/// Locks [amount] of SHx for [account] until [claimAfter].
///
/// Throws [EscrowException] if the contract rejects the request
/// (e.g. claimAfter in the past, or an escrow already exists).
///
/// Example:
/// ```dart
/// await escrowClient.lock(
///   accountId: myAccountId,
///   amount: BigInt.from(1000000000),
///   claimAfter: DateTime.now().add(Duration(days: 30)),
/// );
/// ```
Future<void> lock({...}) async { ... }
```

**No hardcoded secrets:** Private keys, seeds, and API keys must never
appear in source code, tests, or logs.

**No `print()` statements:** Use proper error propagation via exceptions.

---

## 5. Testing Standards

**Coverage target:** >= 80% line and branch coverage across all modules.

**Test file location:** Mirror the `lib/src/` structure under `test/src/`:

lib/src/escrow/escrow_client.dart
test/src/escrow/escrow_client_test.dart

**Test structure:**

```dart
void main() {
  group('ShxEscrowClient', () {
    setUp(() { ... });

    test('locks SHx and can be read back via getEscrow', () {
      // Arrange
      // Act
      // Assert
    });

    test('throws EscrowException when unlocking before claimAfter', () {
      expect(
        () => someCall(),
        throwsA(isA<EscrowException>()),
      );
    });
  });
}
```

**Every feature must include:**

- Happy path test
- Error path tests (invalid input, network failure, edge cases)
- Security test: private keys must not appear in exception messages

---

## 6. Pre-Commit Gate

Run before **every** commit:

```yaml
.\scripts\pre_commit.ps1
```

This runs in order:

1. `dart format .`
2. `dart analyze --fatal-infos`
3. `flutter test`

**The gate must pass green before any `git commit`.** No exceptions.

---

## 7. Pull Request Process

1. Create your feature branch from `develop`
2. Make your changes with passing pre-commit
3. Open a PR targeting `develop`
4. Fill in the PR template completely
5. Wait for CI to pass (GitHub Actions)
6. Request review if needed

**PR title** must follow Conventional Commits format:

feat(escrow): implement Testnet-verified lock/unlock flow

---

## 8. Adding a New Feature

Example: adding path payment support:

```
1. Create branch  
git checkout develop  
git pull origin develop  
git checkout -b feature/asset-path-payment  

2. Create files  
lib/src/asset/shx_path_payment.dart  
test/src/asset/shx_path_payment_test.dart  

3. Export from barrel file  
lib/stronghold_flutter_sdk.dart -> add export  

4. Run pre-commit  
.\scripts\pre_commit.ps1  

5. Commit  
git add .  
git commit -m "feat(asset): add SHx path payment builder"  

6. Push and open PR  
git push origin feature/asset-path-payment  
```

---

## 9. Security Policy

**Reporting a vulnerability:**

- Do NOT open a public GitHub issue for security vulnerabilities
- Email: <sdks@nemorixpay.com>
- We will respond within 48 hours
- A patched version will be released within 7 days of confirmation

**Key handling rules:**

- No key material may appear in exception messages, stack traces, or logs
- Security tests are non-negotiable blockers for every milestone

---

## Questions?

Open a [GitHub Discussion](https://github.com/nemorixgroup/stronghold-flutter-sdk/discussions) or email us at <sdks@nemorixpay.com>