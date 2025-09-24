# GitLab CI/CD Pipeline Documentation

This document describes the automated testing pipeline that validates your dotfiles setup against clean macOS installations using GitLab CI.

## Overview

The GitLab CI pipeline simulates a fresh macOS 26 (Apple Silicon) installation to ensure your dotfiles work reliably for new users and catch breaking changes before they reach the main branch.

**Important Note**: This pipeline requires a self-hosted GitLab Runner on macOS, as GitLab.com's shared runners don't support macOS.

## Pipeline Architecture

### Target Environment
- **Operating System**: macOS (any version, optimized for macOS 26)
- **Architecture**: Apple Silicon (arm64) preferred
- **Runner Type**: Self-hosted GitLab Runner with `macos` tag
- **Runtime**: ~15-20 minutes per run
- **Frequency**: On merge requests, pushes to `ci/*` branches, and manual triggers

### Pipeline Stages

#### 1. **Validate Stage**
- Quick repository structure validation
- Can run on any GitLab runner (uses Alpine Linux)
- Verifies essential files exist before attempting macOS installation

#### 2. **Test Stage**
- **Main Test**: Full macOS setup test (requires macOS runner)
- **Fallback**: Simulation test on Linux (syntax validation only)
- Runs `scripts/ci-setup.sh` and `scripts/ci-verify.sh`
- Comprehensive validation of installation and configuration

#### 3. **Report Stage**
- Generates pipeline summary
- Collects artifacts and logs
- Provides failure diagnostics

## GitLab CI Configuration

### Main Pipeline File
**`.gitlab-ci.yml`**: Complete pipeline configuration with:
- **Variables**: CI environment setup
- **Rules**: Smart triggering for MRs and CI branches
- **Jobs**: Validation, testing, and reporting
- **Artifacts**: Log collection and failure diagnostics

### Runner Requirements

To run this pipeline, you need a self-hosted GitLab Runner configured with:

#### **macOS Runner Setup**
1. **Install GitLab Runner on macOS**:
   ```bash
   # Download and install GitLab Runner
   curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
   brew install gitlab-runner

   # Register runner with your GitLab instance
   gitlab-runner register
   ```

2. **Runner Configuration**:
   - **URL**: Your GitLab instance URL
   - **Token**: Project or group runner token
   - **Tags**: `macos`, `apple-silicon` (or `intel` for Intel Macs)
   - **Executor**: `shell`

3. **Prerequisites on Runner Machine**:
   - macOS 12+ (Monterey or later)
   - Xcode Command Line Tools
   - Admin privileges for package installation
   - Stable internet connection

### Pipeline Triggers

#### **Automatic Triggers**
- **Merge Requests**: Any MR targeting main/master branch
- **CI Branches**: Pushes to branches starting with `ci/`
- **Excludes**: Documentation-only changes (`.md` files, `docs/`)

#### **Manual Triggers**
- Go to **CI/CD → Pipelines** in GitLab
- Click **Run Pipeline**
- Select branch and trigger pipeline
- Optional: Set variables like `ENABLE_SIMULATION=true`

## Key Files

### CI Scripts
- **`scripts/ci-setup.sh`**: GitLab CI-adapted setup script
- **`scripts/ci-verify.sh`**: Comprehensive installation validation
- **Enhanced for GitLab**: Uses `CI_PROJECT_DIR`, `CI_PIPELINE_ID`, etc.

### Existing Integration
- **`scripts/check.sh`**: Your existing health check (reused in pipeline)
- **`setup.sh`**: Referenced for local testing comparison

## Pipeline Features

### **Smart Job Execution**
- **macOS Test**: Runs on self-hosted macOS runner
- **Simulation Test**: Fallback syntax validation on Linux
- **Conditional Logic**: Adapts based on runner availability

### **Comprehensive Testing**
- ✅ **System Environment**: macOS version, architecture validation
- ✅ **Package Managers**: Homebrew and Nix installation/health
- ✅ **Darwin Configuration**: nix-darwin setup and flake validation
- ✅ **Dotfiles Structure**: All categories and symlinks
- ✅ **Development Tools**: git, kubectl, docker, version managers
- ✅ **Shell Environment**: Aliases, PATH, environment variables
- ✅ **Integration**: Full development workflow simulation

### **Artifact Collection**
- **Installation Logs**: Complete setup and verification logs
- **System Reports**: Package inventories and system state
- **Failure Diagnostics**: Debug information for failed runs
- **30-day Retention**: Artifacts available for troubleshooting

## How to Use

### **Setting Up the Runner**
1. **Provision macOS Machine**: Mac with admin access
2. **Install GitLab Runner**: Follow GitLab's installation guide
3. **Register Runner**: Configure with `macos` tag
4. **Test Runner**: Verify it can execute jobs

### **Running the Pipeline**

#### **For Development**
```bash
# Create CI branch to trigger pipeline
git checkout -b ci/test-my-changes

# Push changes
git push origin ci/test-my-changes

# Pipeline will automatically run
```

#### **For Testing**
- Create merge request to main/master
- Pipeline runs automatically on MR creation
- Review results before merging

### **Without macOS Runner**
If you don't have a macOS runner available:

1. **Enable Simulation Mode**:
   ```bash
   # Set GitLab CI variable
   ENABLE_SIMULATION=true
   ```

2. **Limitations**:
   - Only syntax validation
   - No actual package installation
   - Limited testing scope

## Interpreting Results

### **Pipeline Status**

#### **✅ Green Pipeline**
- All stages passed successfully
- Dotfiles install cleanly on fresh macOS
- Ready for production use

#### **⚠️ Yellow Pipeline**
- Some non-critical tests failed
- Usually indicates optional packages missing
- Review warnings, often safe to proceed

#### **❌ Red Pipeline**
- Critical installation failures
- Setup script encountered errors
- Requires investigation before merging

### **Job Logs**
- **Validate**: Repository structure issues
- **Test macOS Setup**: Installation and verification errors
- **Report**: Summary of pipeline execution

## Troubleshooting

### **Common Issues**

#### **No macOS Runner Available**
- **Symptom**: Jobs stuck in "pending" state
- **Cause**: No runner with `macos` tag available
- **Solution**: Set up self-hosted macOS runner or enable simulation mode

#### **Runner Permission Issues**
- **Symptom**: Installation fails with permission errors
- **Cause**: Runner user lacks admin privileges
- **Solution**: Ensure runner runs with admin user account

#### **Nix Installation Failures**
- **Symptom**: Nix installation or flake errors
- **Cause**: Network issues, permission problems, or invalid flake
- **Solution**: Check network connectivity, verify flake syntax locally

#### **Homebrew Conflicts**
- **Symptom**: Package installation conflicts
- **Cause**: Pre-existing packages on runner
- **Solution**: Use dedicated runner machine or improve cleanup

### **Debugging Steps**

1. **Review Job Logs**:
   - Check specific stage that failed
   - Look for error messages and stack traces
   - Note system environment details

2. **Download Artifacts**:
   - Installation logs contain detailed output
   - System reports show package states
   - Available for 30 days after pipeline run

3. **Test Locally**:
   - Run CI scripts on local macOS machine
   - Compare results with CI environment
   - Identify environment-specific issues

4. **Check Runner Health**:
   - Verify runner is online and responsive
   - Check runner logs for system issues
   - Ensure adequate disk space and memory

## Cost and Performance

### **Resource Usage**
- **Runtime**: ~15-20 minutes for full test
- **Frequency**: Typically 5-10 runs per week
- **Resource**: Self-hosted runner (your hardware costs)

### **Optimization Strategies**
- **Smart Triggers**: Skip documentation-only changes
- **Parallel Jobs**: Validation runs on any runner
- **Artifact Cleanup**: 30-day retention for logs
- **Conditional Execution**: Skip expensive steps when possible

## Runner Setup Guide

### **Detailed macOS Runner Configuration**

1. **Prepare macOS Machine**:
   ```bash
   # Install Homebrew (if not already installed)
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # Install GitLab Runner
   brew install gitlab-runner
   ```

2. **Register Runner**:
   ```bash
   gitlab-runner register \
     --url https://gitlab.com/ \
     --registration-token YOUR_TOKEN \
     --description "macOS Dotfiles Runner" \
     --tag-list "macos,apple-silicon" \
     --executor shell
   ```

3. **Start Runner**:
   ```bash
   # Start as service
   brew services start gitlab-runner

   # Or run manually
   gitlab-runner run
   ```

4. **Verify Setup**:
   - Check runner appears in GitLab project settings
   - Run a test pipeline to verify functionality

## Future Enhancements

### **Potential Improvements**
- **Multi-version Testing**: Test against multiple macOS versions
- **Intel Support**: Add Intel Mac runner for broader compatibility
- **Performance Monitoring**: Track installation times and success rates
- **Notification Integration**: Slack/email alerts for failures
- **Scheduled Health Checks**: Regular validation of main branch

### **Advanced Features**
- **Custom Runner Images**: Pre-configured runner environments
- **Pipeline Templates**: Reusable configurations for different projects
- **Integration Testing**: Test with external services and dependencies

---

For questions about the GitLab CI pipeline, check job logs first, then review this documentation for troubleshooting steps. Consider setting up the simulation mode if a macOS runner isn't immediately available.