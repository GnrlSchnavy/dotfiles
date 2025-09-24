#!/bin/bash

# Comprehensive verification script for GitLab CI environment
# Validates that the dotfiles setup completed successfully

set -e  # Exit on any error

# Enhanced logging for CI
LOG_FILE="/tmp/ci-verify.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "🔍 GitLab CI Verification Script"
echo "Validating dotfiles installation..."
echo "Log file: $LOG_FILE"
echo "Timestamp: $(date)"
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters for final report
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

# Function to print colored output
print_section() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_test() {
    echo -e "  🧪 Testing: $1"
}

print_pass() {
    echo -e "  ${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "  ${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

print_warn() {
    echo -e "  ${YELLOW}⚠️  $1${NC}"
    ((TESTS_WARNED++))
}

print_info() {
    echo -e "  ℹ️  $1"
}

# Helper function to test command availability
test_command() {
    local cmd="$1"
    local description="$2"
    local required="${3:-true}"

    print_test "$description"
    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        case "$cmd" in
            "git") version=$(git --version) ;;
            "brew") version=$(brew --version | head -1) ;;
            "nix") version=$(nix --version) ;;
            "docker") version=$(docker --version 2>/dev/null || echo "Docker CLI") ;;
            "kubectl") version=$(kubectl version --client --short 2>/dev/null || echo "kubectl") ;;
            *) version="Available" ;;
        esac
        print_pass "$description - $version"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            print_fail "$description not found"
            return 1
        else
            print_warn "$description not found (optional)"
            return 0
        fi
    fi
}

# Helper function to test file/directory existence
test_path() {
    local path="$1"
    local description="$2"
    local required="${3:-true}"

    print_test "$description"
    if [[ -e "$path" ]]; then
        if [[ -L "$path" ]]; then
            local target=$(readlink "$path")
            print_pass "$description exists (symlink to: $target)"
        else
            print_pass "$description exists"
        fi
        return 0
    else
        if [[ "$required" == "true" ]]; then
            print_fail "$description not found"
            return 1
        else
            print_warn "$description not found (optional)"
            return 0
        fi
    fi
}

echo "🎯 Starting comprehensive verification tests..."
echo

# Section 1: System Environment
print_section "System Environment"
print_info "macOS Version: $(sw_vers -productVersion)"
print_info "Build Version: $(sw_vers -buildVersion)"
print_info "Architecture: $(uname -m)"
print_info "User: $USER"
print_info "Home: $HOME"
print_info "Shell: $SHELL"

if [[ "$CI" == "true" ]]; then
    print_info "CI Environment: GitLab CI"
    print_info "Pipeline ID: ${CI_PIPELINE_ID:-unknown}"
    print_info "Job ID: ${CI_JOB_ID:-unknown}"
    print_info "Branch: ${CI_COMMIT_REF_NAME:-unknown}"
    print_info "Project Dir: ${CI_PROJECT_DIR:-unknown}"
fi

echo

# Section 2: Core Package Managers
print_section "Package Managers"
test_command "brew" "Homebrew package manager" true
test_command "nix" "Nix package manager" true

# Test specific package manager functionality
if command -v brew >/dev/null 2>&1; then
    print_test "Homebrew doctor check"
    if brew doctor >/dev/null 2>&1; then
        print_pass "Homebrew health check passed"
    else
        print_warn "Homebrew doctor reported issues"
    fi

    print_test "Homebrew package count"
    local formula_count=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    local cask_count=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
    print_pass "Homebrew packages: $formula_count formulas, $cask_count casks"
fi

if command -v nix >/dev/null 2>&1; then
    print_test "Nix configuration check"
    if nix flake check ~/.dotfiles/nix >/dev/null 2>&1; then
        print_pass "Nix flake configuration is valid"
    else
        print_fail "Nix flake configuration has errors"
    fi
fi

echo

# Section 3: Darwin Configuration
print_section "Nix Darwin Configuration"
test_command "darwin-rebuild" "darwin-rebuild command" true

if command -v darwin-rebuild >/dev/null 2>&1; then
    print_test "Darwin system configuration"
    if darwin-version >/dev/null 2>&1; then
        local darwin_gen=$(darwin-version 2>/dev/null | head -1)
        print_pass "Darwin configuration active: $darwin_gen"
    else
        print_fail "Darwin configuration not active"
    fi
fi

echo

# Section 4: Dotfiles Structure
print_section "Dotfiles Structure"
test_path "$HOME/.dotfiles" "Dotfiles directory" true
test_path "$HOME/.dotfiles/nix" "Nix configuration directory" true
test_path "$HOME/.dotfiles/scripts" "Scripts directory" true

# Test individual category directories
categories=("shell" "git" "editors" "development" "system")
for category in "${categories[@]}"; do
    test_path "$HOME/.dotfiles/$category" "$category configuration directory" true
done

echo

# Section 5: Symlinked Dotfiles
print_section "Dotfile Symlinks"

# Critical symlinks that should exist
critical_dotfiles=(
    "$HOME/.zprofile:Shell profile"
    "$HOME/.zshrc:Shell rc file"
    "$HOME/.gitconfig:Git configuration"
    "$HOME/.gitignore_global:Global gitignore"
    "$HOME/.ideavimrc:IdeaVim configuration"
    "$HOME/.claude:Claude Code settings directory"
)

for entry in "${critical_dotfiles[@]}"; do
    IFS=':' read -ra ADDR <<< "$entry"
    path="${ADDR[0]}"
    desc="${ADDR[1]}"
    test_path "$path" "$desc" false
done

echo

# Section 6: Essential Development Tools
print_section "Development Tools"

# Core tools that should be available
essential_tools=(
    "git:Git version control"
    "stow:GNU Stow for symlink management"
    "curl:HTTP client"
    "wget:File downloader"
    "jq:JSON processor"
    "tree:Directory tree visualization"
)

for tool_desc in "${essential_tools[@]}"; do
    IFS=':' read -ra ADDR <<< "$tool_desc"
    tool="${ADDR[0]}"
    desc="${ADDR[1]}"
    test_command "$tool" "$desc" false
done

echo

# Section 7: Language Runtimes & Version Managers
print_section "Language Runtimes & Version Managers"

# Language runtimes
test_command "python3" "Python 3 runtime" false
test_command "node" "Node.js runtime" false
test_command "rustc" "Rust compiler" false

# Version managers
test_command "nvm" "Node Version Manager" false
test_command "pyenv" "Python Environment Manager" false
test_command "jenv" "Java Environment Manager" false

# Java runtime (handled by jenv)
if command -v java >/dev/null 2>&1; then
    java_version=$(java -version 2>&1 | head -1)
    print_pass "Java runtime - $java_version"
else
    print_warn "Java runtime not found (may be managed by jenv)"
fi

echo

# Section 8: Container & Cloud Tools
print_section "Container & Cloud Tools"
test_command "docker" "Docker CLI" false
test_command "kubectl" "Kubernetes CLI" false
test_command "helm" "Helm package manager" false
test_command "minikube" "Minikube local Kubernetes" false

echo

# Section 9: Shell Environment
print_section "Shell Environment"

print_test "Shell environment loading"
if [[ -f "$HOME/.zprofile" ]]; then
    # Source shell configuration to test it loads without errors
    if source "$HOME/.zprofile" >/dev/null 2>&1; then
        print_pass "Shell profile loads without errors"
    else
        print_fail "Shell profile has loading errors"
    fi
else
    print_fail "Shell profile not found"
fi

# Test critical environment variables
print_test "Environment variables"
if [[ -n "$PATH" ]]; then
    print_pass "PATH is configured"
    print_info "PATH contains $(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ') entries"
else
    print_fail "PATH is not configured"
fi

# Test aliases (if shell is sourced)
print_test "Kubernetes aliases"
if alias k >/dev/null 2>&1; then
    print_pass "kubectl alias 'k' is configured"
else
    print_warn "kubectl alias 'k' not found (shell may not be sourced)"
fi

echo

# Section 10: Homebrew Integration
print_section "Homebrew Integration"

if command -v brew >/dev/null 2>&1; then
    # Test key homebrew packages
    key_packages=(
        "stow:GNU Stow"
        "kubectl:Kubernetes CLI"
        "helm:Helm package manager"
        "gh:GitHub CLI"
    )

    for package_desc in "${key_packages[@]}"; do
        IFS=':' read -ra ADDR <<< "$package_desc"
        package="${ADDR[0]}"
        desc="${ADDR[1]}"

        print_test "$desc (via Homebrew)"
        if brew list "$package" >/dev/null 2>&1; then
            print_pass "$desc is installed via Homebrew"
        else
            print_warn "$desc not found in Homebrew packages"
        fi
    done
fi

echo

# Section 11: Final Integration Test
print_section "Integration Tests"

print_test "Git configuration validation"
if git config --get user.name >/dev/null 2>&1 && git config --get user.email >/dev/null 2>&1; then
    local git_name=$(git config --get user.name)
    local git_email=$(git config --get user.email)
    print_pass "Git user configured: $git_name <$git_email>"
else
    print_fail "Git user not properly configured"
fi

print_test "Development workflow simulation"
# Test a simple git operation
if cd "$HOME/.dotfiles" && git status >/dev/null 2>&1; then
    print_pass "Git operations work in dotfiles directory"
else
    print_fail "Git operations failed in dotfiles directory"
fi

echo

# GitLab CI specific tests
if [[ "$CI" == "true" ]]; then
    print_section "GitLab CI Integration"

    print_test "GitLab CI environment variables"
    if [[ -n "$CI_PIPELINE_ID" ]]; then
        print_pass "GitLab CI pipeline ID available: $CI_PIPELINE_ID"
    else
        print_warn "GitLab CI pipeline ID not found"
    fi

    print_test "Project directory access"
    if [[ -n "$CI_PROJECT_DIR" && -d "$CI_PROJECT_DIR" ]]; then
        print_pass "GitLab CI project directory accessible: $CI_PROJECT_DIR"
    else
        print_warn "GitLab CI project directory not available"
    fi

    echo
fi

# Final Report
print_section "Verification Summary"

local total_tests=$((TESTS_PASSED + TESTS_FAILED + TESTS_WARNED))

echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"
echo -e "${YELLOW}⚠️  Warnings: $TESTS_WARNED${NC}"
echo -e "📊 Total Tests: $total_tests"
echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 All critical tests passed! Dotfiles installation verified successfully.${NC}"
    echo "Log file saved to: $LOG_FILE"

    if [[ "$CI" == "true" ]]; then
        echo "GitLab CI Pipeline: ${CI_PIPELINE_ID:-unknown}"
        echo "GitLab CI Job: ${CI_JOB_ID:-unknown}"
    fi

    exit 0
else
    echo -e "${RED}💥 $TESTS_FAILED critical test(s) failed. Installation needs attention.${NC}"
    echo "Log file saved to: $LOG_FILE"
    echo
    echo "🔧 Common fixes:"
    echo "  - Re-run the setup script: ./scripts/ci-setup.sh"
    echo "  - Check system requirements and dependencies"
    echo "  - Review installation logs for specific errors"

    if [[ "$CI" == "true" ]]; then
        echo "  - Check GitLab CI job logs for detailed error information"
        echo "  - Verify macOS runner configuration and dependencies"
    fi

    exit 1
fi