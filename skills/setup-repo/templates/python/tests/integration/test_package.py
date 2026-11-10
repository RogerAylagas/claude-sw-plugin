"""Integration smoke tests. Placeholder: replace with tests that cross real boundaries."""

import subprocess  # sw:if kind=app
import sys  # sw:if kind=app
from importlib.metadata import version

import {{PACKAGE_NAME}}


def test_distribution_is_installed() -> None:
    assert version("{{PROJECT_NAME}}")
    assert {{PACKAGE_NAME}}.greet("ci") == "Hello, ci!"
# sw:if kind=app
# sw:if kind=app
def test_command_line_prints_greeting() -> None:  # sw:if kind=app
    result = subprocess.run(  # sw:if kind=app
        [sys.executable, "-m", "{{PACKAGE_NAME}}"],  # sw:if kind=app
        capture_output=True,  # sw:if kind=app
        text=True,  # sw:if kind=app
        check=True,  # sw:if kind=app
    )  # sw:if kind=app
    assert result.stdout.strip() == "Hello, world!"  # sw:if kind=app
