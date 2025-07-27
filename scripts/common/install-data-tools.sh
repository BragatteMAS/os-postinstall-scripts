#!/usr/bin/env bash
# install-data-tools.sh - Install high-performance data processing tools
# IMPORTANT: Uses Polars, NOT pandas for performance

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

install_rust_toolchain() {
    log_info "Installing Rust toolchain for high-performance backend..."
    
    if command -v rustc &> /dev/null; then
        log_success "Rust already installed: $(rustc --version)"
        return 0
    fi
    
    # Install Rust via rustup
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    log_success "Rust installed successfully"
}

install_polars_stack() {
    log_info "Installing Polars data processing stack..."
    
    # Ensure Python is available
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 not found. Please install Python first."
        return 1
    fi
    
    # Install Polars (NOT pandas!)
    log_info "Installing Polars (5-10x faster than pandas)..."
    pip install --user polars
    
    # Install DuckDB for SQL analytics
    log_info "Installing DuckDB for SQL analytics..."
    pip install --user duckdb
    
    # Install PyArrow for Arrow format support
    log_info "Installing PyArrow for columnar data..."
    pip install --user pyarrow
    
    # EXPLICITLY NOT INSTALLING: pandas
    # If you need pandas functionality, use Polars equivalents:
    # - pl.read_csv() instead of pd.read_csv()
    # - pl.DataFrame() instead of pd.DataFrame()
    # - pl.concat() instead of pd.concat()
    
    log_success "Polars stack installed successfully"
}

verify_no_pandas() {
    log_info "Verifying pandas is NOT installed..."
    
    if python3 -c "import pandas" 2>/dev/null; then
        log_warning "pandas detected! This project uses Polars for better performance."
        log_warning "Consider uninstalling pandas: pip uninstall pandas"
        log_warning "See ADR-012 for migration guide from pandas to Polars"
    else
        log_success "Good! No pandas installation detected."
    fi
}

create_polars_example() {
    log_info "Creating Polars example script..."
    
    cat > "$HOME/.local/share/polars-example.py" << 'EOF'
#!/usr/bin/env python3
"""Example showing Polars usage (NOT pandas)"""

import polars as pl
# NEVER: import pandas as pd

# Read CSV with Polars (5-10x faster than pandas)
df = pl.read_csv("data.csv")

# Lazy evaluation for large files
lazy_df = pl.scan_csv("large_data.csv")

# Fast operations
result = (lazy_df
    .filter(pl.col("value") > 100)
    .group_by("category")
    .agg(pl.col("value").sum())
    .collect()  # Execute only when needed
)

# DuckDB integration for SQL
import duckdb
conn = duckdb.connect()
conn.register("my_table", df)
sql_result = conn.execute("SELECT * FROM my_table WHERE value > 100").pl()

print("Polars is configured and ready!")
print("Remember: Always use Polars, never pandas!")
EOF
    
    chmod +x "$HOME/.local/share/polars-example.py"
    log_success "Example created at: $HOME/.local/share/polars-example.py"
}

main() {
    log_header "Installing High-Performance Data Tools"
    
    install_rust_toolchain
    install_polars_stack
    verify_no_pandas
    create_polars_example
    
    log_header "Data Tools Installation Complete!"
    log_info "Key tools installed:"
    log_info "  - Rust: High-performance backend"
    log_info "  - Polars: Fast DataFrame library (NOT pandas)"
    log_info "  - DuckDB: SQL analytics engine"
    log_info "  - PyArrow: Columnar data format"
    
    log_warning "Remember: This project uses Polars exclusively."
    log_warning "Do NOT install or use pandas!"
}

# Run main function
main "$@"