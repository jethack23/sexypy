# Getting Started
## Simple Web REPL
You can try Sxpy without installing at
[https://jethack23.github.io/sxpy-web/](https://jethack23.github.io/sxpy-web/).
## Installation
### Using pip
```bash
pip install sexypy
```
### Manual Installation (for development)
```bash
poetry install --no-root # for dependency
pip install -e . # for development
```
#### Poetry
I recommend using [Poetry](https://python-poetry.org/) for development.
And turn off virtual environment creation in Poetry settings.
```bash
poetry config virtualenvs.create false
```