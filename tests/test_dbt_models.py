"""
Tests for dbt project structure and configuration integrity.

Validates that dbt models, sources, and project configuration
are correctly defined — without requiring a running database.
"""

import pytest
import os
import yaml

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DBT_DIR = os.path.join(PROJECT_ROOT, "dbt_project")


class TestDbtProjectConfig:
    """Validates dbt_project.yml configuration."""

    def test_dbt_project_yml_exists(self):
        path = os.path.join(DBT_DIR, "dbt_project.yml")
        assert os.path.exists(path), "dbt_project.yml not found"

    def test_project_name(self):
        with open(os.path.join(DBT_DIR, "dbt_project.yml")) as f:
            config = yaml.safe_load(f)
        assert config["name"] == "people_analytics"

    def test_staging_materialized_as_view(self):
        with open(os.path.join(DBT_DIR, "dbt_project.yml")) as f:
            config = yaml.safe_load(f)
        staging = config["models"]["people_analytics"]["staging"]
        assert staging["+materialized"] == "view"

    def test_marts_materialized_as_table(self):
        with open(os.path.join(DBT_DIR, "dbt_project.yml")) as f:
            config = yaml.safe_load(f)
        marts = config["models"]["people_analytics"]["marts"]
        assert marts["+materialized"] == "table"


class TestDbtModelsExist:
    """Validates that all expected dbt model files are present."""

    @pytest.mark.parametrize("model_path", [
        "models/staging/stg_employees.sql",
        "models/staging/stg_employees.yml",
        "models/staging/sources.yml",
        "models/marts/mart_performance_percentiles.sql",
        "models/marts/mart_performance_percentiles.yml",
    ])
    def test_model_file_exists(self, model_path):
        full_path = os.path.join(DBT_DIR, model_path)
        assert os.path.exists(full_path), f"Missing dbt model: {model_path}"


class TestDbtSources:
    """Validates sources.yml defines the expected raw tables."""

    @pytest.fixture
    def sources_config(self):
        with open(os.path.join(DBT_DIR, "models/staging/sources.yml")) as f:
            return yaml.safe_load(f)

    def test_raw_source_defined(self, sources_config):
        source_names = [s["name"] for s in sources_config["sources"]]
        assert "raw" in source_names

    def test_employees_table_defined(self, sources_config):
        raw_source = next(s for s in sources_config["sources"] if s["name"] == "raw")
        table_names = [t["name"] for t in raw_source["tables"]]
        assert "employees" in table_names

    def test_performance_reviews_table_defined(self, sources_config):
        raw_source = next(s for s in sources_config["sources"] if s["name"] == "raw")
        table_names = [t["name"] for t in raw_source["tables"]]
        assert "performance_reviews" in table_names

    def test_employees_has_tests(self, sources_config):
        """The employee_id column should have unique + not_null tests."""
        raw_source = next(s for s in sources_config["sources"] if s["name"] == "raw")
        employees = next(t for t in raw_source["tables"] if t["name"] == "employees")
        emp_id_col = next(c for c in employees["columns"] if c["name"] == "employee_id")
        assert "unique" in emp_id_col["tests"]
        assert "not_null" in emp_id_col["tests"]
