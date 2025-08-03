# Python Style Guide

## Package Management

### 🚨 ALWAYS use UV
- **Don't use pip, conda, poetry, or pipenv**
- UV is the standard for ALL Python projects

```bash
# Install UV (once)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create virtual environment
uv venv

# Activate environment
source .venv/bin/activate  # Linux/Mac
# ou
.venv\Scripts\activate     # Windows

# Install dependencies
uv pip install -r requirements.txt

# Add new dependency
uv pip install package-name

# Freeze dependencies
uv pip freeze > requirements.txt
```

## Code Style

### Formatting
- **Black** for automatic formatting
- **Ruff** for linting (faster than flake8/pylint)
- Maximum line: 88 characters (Black default)

```bash
# Setup
uv pip install black ruff

# Format
black .

# Lint
ruff check .
```

### Type Hints
- **Always use type hints** for public functions
- Use `from typing import` for complex types
- Mypy for static checking (optional)

```python
from typing import List, Optional, Dict

def process_data(
    items: List[str],
    config: Optional[Dict[str, any]] = None
) -> Dict[str, int]:
    """Process items and return counts."""
    # implementation
```

### Docstrings
- Use docstrings for all public functions
- Google or NumPy format (consistent in project)
- Include types, description, and examples when relevant

```python
def calculate_metrics(data: pd.DataFrame) -> Dict[str, float]:
    """Calculate performance metrics from data.
    
    Args:
        data: DataFrame with columns 'actual' and 'predicted'
        
    Returns:
        Dictionary with metrics: accuracy, precision, recall
        
    Example:
        >>> metrics = calculate_metrics(df)
        >>> print(metrics['accuracy'])
        0.95
    """
```

## Data Processing

### Always Polars > Pandas
- **Use Polars** for new projects
- Faster, less memory, more consistent API
- Pandas only for legacy compatibility

```python
import polars as pl

# Instead of pandas
df = pl.read_csv("data.csv")
result = df.filter(pl.col("value") > 100).select(["id", "value"])
```

## Performance

### Consider Rust Bindings
For performance-critical code:
- Heavy loops
- String processing
- Intensive numerical calculations

```python
# Use maturin to create bindings
# my_rust_module.pyi
def fast_process(data: List[float]) -> float: ...

# main.py
from my_rust_module import fast_process
result = fast_process(large_dataset)
```

### Async/Await
For I/O intensive:
```python
import asyncio
import httpx

async def fetch_data(urls: List[str]) -> List[dict]:
    async with httpx.AsyncClient() as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks)
        return [r.json() for r in responses]
```

## Project Structure

```
project/
├── src/
│   └── package_name/
│       ├── __init__.py
│       ├── core.py
│       └── utils.py
├── tests/
│   ├── test_core.py
│   └── test_utils.py
├── .venv/             # Created by uv venv
├── requirements.txt   # Dependencies
├── pyproject.toml     # Project metadata
└── README.md
```

## Import Organization

```python
# Standard library
import os
import sys
from pathlib import Path

# Third-party
import polars as pl
import httpx
from pydantic import BaseModel

# Local
from .core import process
from .utils import helpers
```

## Common Patterns

### Configuration with Pydantic
```python
from pydantic import BaseModel
from pydantic_settings import BaseSettings

class Config(BaseSettings):
    api_key: str
    debug: bool = False
    max_retries: int = 3
    
    class Config:
        env_file = ".env"
```

### Error Handling
```python
from typing import Result  # Using result type pattern

def process_file(path: Path) -> Result[str, Exception]:
    try:
        data = path.read_text()
        return Ok(process(data))
    except FileNotFoundError as e:
        return Err(e)
```

## Testing

### Use Pytest
```bash
uv pip install pytest pytest-asyncio pytest-cov

# Run tests
pytest

# With coverage
pytest --cov=src --cov-report=html
```

### Test Structure
```python
import pytest
from src.package_name import process

def test_process_valid_input():
    result = process("valid")
    assert result == expected

@pytest.mark.asyncio
async def test_async_function():
    result = await async_process()
    assert result is not None
```

## Never Do

- ❌ Use pip or conda (always UV)
- ❌ Import * (always explicit)
- ❌ Mutable default arguments
- ❌ Global variables for state
- ❌ Print for debugging (use logging)
- ❌ Pandas in new projects (use Polars)