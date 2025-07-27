# Makefile for Linux Post-Install Scripts

# Include project-specific targets if available
-include Makefile.project

.PHONY: changelog help install-zsh test clean requirements licenses monitor-deps ip-docs all-docs setup-dirs setup

# Default target
help:
	@echo "=== BMad Method Targets ==="
	@echo "  setup        - Initial setup (run this first)"
	@echo "  changelog    - Generate CHANGELOG.md with proper dates"
	@echo "  requirements - Generate requirements files"
	@echo "  licenses     - Analyze dependency licenses"
	@echo "  monitor-deps - Monitor dependency changes"
	@echo "  ip-docs      - Generate IP documentation package"
	@echo "  all-docs     - Generate all documentation"
	@echo ""
	@echo "=== Project-Specific Targets ==="
	@echo "  install-linux - Run full Linux post-installation"
	@echo "  install-zsh  - Install zsh configuration"
	@echo "  install-rust - Install Rust CLI tools"
	@echo "  verify       - Verify installed tools"
	@echo "  check-scripts - Check shell scripts for issues"
	@echo "  fix-permissions - Fix script permissions"
	@echo ""
	@echo "=== Common Targets ==="
	@echo "  test         - Run tests"
	@echo "  clean        - Clean generated files"

# Generate CHANGELOG.md from template
changelog:
	@echo "📝 Generating CHANGELOG.md..."
	@chmod +x .ai/scripts/update-changelog-dates.sh 2>/dev/null || true
	@if [ -f ".git/HEAD" ]; then \
		INITIAL_DATE=$$(git log --reverse --format="%Y-%m-%d" | head -1 || date +%Y-%m-%d); \
		RELEASE_DATE=$$(date +%Y-%m-%d); \
		sed "s/\$${RELEASE_DATE}/$$RELEASE_DATE/g; s/\$${INITIAL_DATE}/$$INITIAL_DATE/g" CHANGELOG.template.md > CHANGELOG.md; \
		echo "✅ CHANGELOG.md generated:"; \
		echo "   - Repository first commit: $$INITIAL_DATE"; \
		echo "   - Current date: $$RELEASE_DATE"; \
	else \
		echo "⚠️  Not a git repository. Using current date for both entries."; \
		CURRENT_DATE=$$(date +%Y-%m-%d); \
		sed "s/\$${RELEASE_DATE}/$$CURRENT_DATE/g; s/\$${INITIAL_DATE}/$$CURRENT_DATE/g" CHANGELOG.template.md > CHANGELOG.md; \
	fi

# Install zsh configuration
install-zsh:
	@echo "🚀 Installing zsh configuration..."
	@if [ -f ~/.zshrc ]; then \
		cp ~/.zshrc ~/.zshrc.backup.$$(date +%Y%m%d_%H%M%S); \
		echo "✅ Backed up existing .zshrc"; \
	fi
	@cp zshrc ~/.zshrc
	@echo "✅ Installed new .zshrc"
	@echo "🔄 Run 'source ~/.zshrc' to reload"

# Run tests - v3.2.0 MANUAL TESTING ONLY
test: test-manual

# Manual test targets - NO AUTOMATION
test-manual:
	@echo "🧪 Manual Testing - OS Post-Install Scripts v3.2.0"
	@echo "================================================="
	@echo "⚠️  ALL tests are manual and on-demand"
	@echo ""
	@echo "Available test suites:"
	@echo "  make test-manual-smoke       # Quick confidence check (5 min)"
	@echo "  make test-manual-integration # Component tests (15 min)"
	@echo "  make test-manual-acceptance  # User scenarios (30 min)"
	@echo "  make test-manual-security    # Security checks (10 min)"
	@echo "  make test-manual-full        # Complete validation (90 min)"
	@echo ""
	@echo "Story-specific tests:"
	@echo "  make test-story-1.1         # Quick start installation"
	@echo "  make test-story-1.6         # Technology detection"
	@echo ""
	@echo "Run with education mode:"
	@echo "  TEST_EDUCATION=1 make test-manual-smoke"
	@echo ""
	@echo "See tests/guides/WHEN_TO_TEST.md for guidance"

test-manual-smoke:
	@echo "🚀 Running smoke tests (5 minutes)..."
	@./tests/manual/smoke/minimal-base.sh

test-manual-integration:
	@echo "🔧 Running integration tests (15 minutes)..."
	@./tests/manual/integration/run-all.sh

test-manual-acceptance:
	@echo "👤 Running acceptance tests (30 minutes)..."
	@./tests/manual/acceptance/run-all.sh

test-manual-security:
	@echo "🔒 Running security tests (10 minutes)..."
	@./tests/manual/security/run-all.sh

test-manual-full:
	@echo "📊 Running full validation suite (90 minutes)..."
	@./tests/manual/full-validation.sh

test-story-%:
	@echo "📖 Running tests for Story $*..."
	@./tests/manual/run-story-tests.sh $*

# Linting only - no test execution
lint:
	@echo "🔍 Running ShellCheck on all scripts..."
	@find . -name "*.sh" -type f -exec shellcheck {} \;

# Setup directories
setup-dirs:
	@mkdir -p .ai/scripts .ai/templates .github/workflows .github/hooks
	@echo "✅ Directories created"

# Initial setup
setup: setup-dirs
	@chmod +x .ai/scripts/setup-scripts.sh 2>/dev/null || true
	@bash .ai/scripts/setup-scripts.sh
	@echo "✅ Initial setup complete"

# Generate requirements
requirements: setup-dirs
	@echo "📦 Generating requirements..."
	@chmod +x .ai/scripts/generate-requirements.sh
	@bash .ai/scripts/generate-requirements.sh
	@echo "✅ Requirements generated"

# Analyze licenses
licenses: requirements
	@echo "⚖️ Analyzing licenses..."
	@chmod +x .ai/scripts/analyze-licenses.sh
	@bash .ai/scripts/analyze-licenses.sh
	@echo "✅ License analysis complete"

# Monitor dependencies
monitor-deps:
	@echo "🔍 Monitoring dependencies..."
	@chmod +x .ai/scripts/monitor-dependencies.sh
	@bash .ai/scripts/monitor-dependencies.sh
	@echo "✅ Monitoring complete"

# Generate IP documentation
ip-docs: requirements licenses
	@echo "📋 Generating IP documentation..."
	@mkdir -p .ai/ip-package
	@cp -r requirements .ai/ip-package/
	@cp -r licenses .ai/ip-package/
	@sed "s/\$$(date +%Y-%m-%d)/$$(date +%Y-%m-%d)/g" .ai/templates/IP-DOCUMENTATION.md > .ai/ip-package/IP-DOCUMENTATION.md
	@cd .ai/ip-package && tar -czf ../ip-documentation-$(shell date +%Y%m%d).tar.gz .
	@echo "✅ IP documentation package created: .ai/ip-documentation-*.tar.gz"

# Generate all documentation
all-docs: changelog requirements licenses monitor-deps ip-docs
	@echo "✅ All documentation generated"

# Clean generated files
clean:
	@echo "🧹 Cleaning generated files..."
	@rm -f CHANGELOG.md
	@rm -rf requirements licenses .dependency-monitor .ai/ip-package
	@rm -f .ai/ip-documentation-*.tar.gz
	@echo "✅ Cleaned"