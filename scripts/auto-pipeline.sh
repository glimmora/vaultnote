#!/bin/bash

# VaultNote Automated CI/CD Pipeline
# Complete build, test, and deployment automation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPTS_DIR")"

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_step() {
    echo -e "${CYAN}▶${NC} $1"
}
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

show_help() {
    cat << EOF
VaultNote Auto Pipeline Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -t, --type TYPE         Project type: auto, flutter, web, android (default: auto)
    -m, --mode MODE         Run mode: development, production (default: development)
    -v, --verbose           Verbose output
    -r, --retries NUM       Max fix-test retries (default: 3)
    -s, --skip-run          Skip run step
    -S, --skip-test         Skip test step
    -F, --skip-fix          Skip fix step
    -R, --no-report         Don't generate pipeline report
    -h, --help              Show this help message

Examples:
    $(basename "$0")                    # Full pipeline
    $(basename "$0") -t flutter         # Flutter only
    $(basename "$0") -s                 # Skip run, do test+fix
    $(basename "$0") -v -r 5            # Verbose with 5 retries

EOF
}

# Generate pipeline report
generate_report() {
    local report_file="$SCRIPTS_DIR/logs/pipeline-report-$(date +%Y%m%d-%H%M%S).md"
    local end_time=$(date +%s)
    local duration=$((end_time - PIPELINE_START_TIME))
    local duration_formatted=$(printf "%02d:%02d:%02d" $((duration/3600)) $((duration%3600/60)) $((duration%60)))
    
    cat > "$report_file" << EOF
# VaultNote Auto Pipeline Report

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Duration:** $duration_formatted
**Status:** $PIPELINE_STATUS

## Configuration

- Project Type: $PROJECT_TYPE
- Mode: $MODE
- Max Retries: $MAX_RETRIES
- Verbose: $VERBOSE

## Pipeline Steps

| Step | Status | Details |
|------|--------|---------|
| Setup | ✅ Completed | Dependencies verified |
| Run | $([ "$SKIP_RUN" == true ] && echo "⏭️ Skipped" || echo "✅ Completed") | Application execution |
| Test | $([ "$SKIP_TEST" == true ] && echo "⏭️ Skipped" || echo "✅ Completed") | Test execution |
| Fix | $([ "$SKIP_FIX" == true ] && echo "⏭️ Skipped" || echo "✅ Completed") | Issue resolution |
| Re-Test | $([ "$SKIP_TEST" == true ] && echo "⏭️ Skipped" || echo "✅ Completed") | Verification |

## Results

EOF

    if [[ ${#PIPELINE_ERRORS[@]} -eq 0 ]]; then
        echo "No errors encountered during pipeline execution." >> "$report_file"
    else
        echo "### Errors Encountered" >> "$report_file"
        echo "" >> "$report_file"
        for error in "${PIPELINE_ERRORS[@]}"; do
            echo "- $error" >> "$report_file"
        done
    fi
    
    cat >> "$report_file" << EOF

## Logs

- Pipeline Log: \`$LOG_FILE\`
- Setup Log: \`$SCRIPTS_DIR/logs/setup-*.log\`
- Run Log: \`$SCRIPTS_DIR/logs/run-*.log\`
- Test Log: \`$SCRIPTS_DIR/logs/test-*.log\`
- Fix Log: \`$SCRIPTS_DIR/logs/fix-*.log\`

## Next Steps

1. Review any errors in the logs
2. Run individual scripts if needed:
   - \\\`./scripts/setup.sh\\\` - Setup dependencies
   - \\\`./scripts/run.sh\\\` - Run application
   - \\\`./scripts/test.sh\\\` - Run tests
   - \\\`./scripts/fix.sh\\\` - Fix issues

EOF
    
    print_info "Pipeline report generated: $report_file"
}

# Run pipeline step
run_step() {
    local step_name="$1"
    local script="$2"
    local args="$3"
    
    print_step "Running $step_name..."
    
    if [[ ! -f "$SCRIPTS_DIR/$script" ]]; then
        print_error "$script not found"
        PIPELINE_ERRORS+=("$step_name: Script not found")
        return 1
    fi
    
    # Make script executable
    chmod +x "$SCRIPTS_DIR/$script"
    
    # Run script
    if [[ "$VERBOSE" == true ]]; then
        if "$SCRIPTS_DIR/$script" $args; then
            print_success "$step_name completed"
            return 0
        else
            print_error "$step_name failed"
            PIPELINE_ERRORS+=("$step_name: Script execution failed")
            return 1
        fi
    else
        if "$SCRIPTS_DIR/$script" $args > "$LOG_FILE.$step_name" 2>&1; then
            print_success "$step_name completed"
            return 0
        else
            print_error "$step_name failed"
            PIPELINE_ERRORS+=("$step_name: Script execution failed")
            cat "$LOG_FILE.$step_name"
            return 1
        fi
    fi
}

# Main pipeline function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            -m|--mode)
                MODE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -r|--retries)
                MAX_RETRIES="$2"
                shift 2
                ;;
            -s|--skip-run)
                SKIP_RUN=true
                shift
                ;;
            -S|--skip-test)
                SKIP_TEST=true
                shift
                ;;
            -F|--skip-fix)
                SKIP_FIX=true
                shift
                ;;
            -R|--no-report)
                GENERATE_REPORT=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header "VaultNote Auto Pipeline"
    echo ""
    
    log "Starting auto pipeline..."
    
    # Print pipeline configuration
    print_info "Pipeline Configuration:"
    echo -e "  Project Type: ${GREEN}$PROJECT_TYPE${NC}"
    echo -e "  Mode: ${GREEN}$MODE${NC}"
    echo -e "  Max Retries: ${GREEN}$MAX_RETRIES${NC}"
    echo -e "  Verbose: ${GREEN}$VERBOSE${NC}"
    echo ""
    
    print_info "Pipeline Steps:"
    echo -e "  Setup: ${GREEN}✓ Always run${NC}"
    echo -e "  Run: ${GREEN}$([ "$SKIP_RUN" == true ] && echo "⏭️ Skip" || echo "✓ Run")${NC}"
    echo -e "  Test: ${GREEN}$([ "$SKIP_TEST" == true ] && echo "⏭️ Skip" || echo "✓ Run")${NC}"
    echo -e "  Fix: ${GREEN}$([ "$SKIP_FIX" == true ] && echo "⏭️ Skip" || echo "✓ Run")${NC}"
    echo -e "  Re-Test: ${GREEN}$([ "$SKIP_TEST" == true ] && echo "⏭️ Skip" || echo "✓ Run")${NC}"
    echo ""
    
    # Step 1: Setup
    print_header "Step 1: Setup"
    if ! run_step "Setup" "setup.sh" ""; then
        print_error "Setup failed, cannot continue"
        PIPELINE_STATUS="FAILED"
        if [[ "$GENERATE_REPORT" == true ]]; then
            generate_report
        fi
        exit 1
    fi
    echo ""
    
    # Step 2: Run
    if [[ "$SKIP_RUN" == false ]]; then
        print_header "Step 2: Run"
        if ! run_step "Run" "run.sh" "-m $MODE -b"; then
            print_error "Run failed"
            PIPELINE_ERRORS+=("Run: Application execution failed")
            # Continue to test anyway
        fi
        echo ""
    fi
    
    # Step 3: Test
    if [[ "$SKIP_TEST" == false ]]; then
        print_header "Step 3: Test"
        if ! run_step "Test" "test.sh" ""; then
            print_error "Tests failed, proceeding to fix"
            PIPELINE_ERRORS+=("Test: Initial test run failed")
        else
            print_success "All tests passed"
            # Skip fix and re-test if tests pass
            SKIP_FIX=true
        fi
        echo ""
    fi
    
    # Step 4: Fix (if tests failed and fix not skipped)
    if [[ "$SKIP_FIX" == false && "$SKIP_TEST" == false ]]; then
        print_header "Step 4: Fix"
        
        local retry_count=0
        local fix_success=false
        
        while [[ $retry_count -lt $MAX_RETRIES ]]; do
            print_info "Fix attempt $((retry_count + 1))/$MAX_RETRIES"
            
            if run_step "Fix" "fix.sh" ""; then
                print_success "Fix completed"
                
                # Re-run tests after fix
                print_info "Re-running tests after fix..."
                if run_step "Re-Test" "test.sh" ""; then
                    print_success "Tests passed after fix"
                    fix_success=true
                    break
                else
                    print_error "Tests still failing after fix"
                    PIPELINE_ERRORS+=("Fix: Tests failed after attempt $((retry_count + 1))")
                fi
            else
                print_error "Fix attempt failed"
                PIPELINE_ERRORS+=("Fix: Attempt $((retry_count + 1)) failed")
            fi
            
            ((retry_count++))
            
            if [[ $retry_count -lt $MAX_RETRIES ]]; then
                print_info "Waiting 2 seconds before next retry..."
                sleep 2
            fi
        done
        
        if [[ "$fix_success" == false ]]; then
            print_error "Max fix retries reached"
            PIPELINE_STATUS="FAILED"
        fi
        echo ""
    fi
    
    # Final status
    print_header "Pipeline Complete"
    echo ""
    
    if [[ ${#PIPELINE_ERRORS[@]} -eq 0 ]]; then
        print_success "Pipeline completed successfully"
        PIPELINE_STATUS="SUCCESS"
    else
        print_error "Pipeline completed with errors"
        PIPELINE_STATUS="FAILED"
        
        print_info "Errors encountered:"
        for error in "${PIPELINE_ERRORS[@]}"; do
            echo -e "  ${RED}•${NC} $error"
        done
    fi
    
    echo ""
    
    # Generate report
    if [[ "$GENERATE_REPORT" == true ]]; then
        generate_report
    fi
    
    # Print summary
    local end_time=$(date +%s)
    local duration=$((end_time - PIPELINE_START_TIME))
    local duration_formatted=$(printf "%02d:%02d:%02d" $((duration/3600)) $((duration%3600/60)) $((duration%60)))
    
    print_info "Pipeline Summary:"
    echo -e "  Status: ${GREEN}$PIPELINE_STATUS${NC}"
    echo -e "  Duration: ${CYAN}$duration_formatted${NC}"
    echo -e "  Errors: ${RED}${#PIPELINE_ERRORS[@]}${NC}"
    echo ""
    
    # Exit with appropriate code
    if [[ "$PIPELINE_STATUS" == "SUCCESS" ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"