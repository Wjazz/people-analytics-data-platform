"""
Tests for data extractors and raw data validation.

Validates that sample CSV files exist, have correct structure,
and that column schemas match what the dbt models expect.
"""

import pytest
import pandas as pd
import os

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(PROJECT_ROOT, "data")


# ===========================================================================
# Test: sample_hr.csv
# ===========================================================================
class TestSampleHRData:
    """Validates structure and integrity of the HR employee dataset."""

    CSV_PATH = os.path.join(DATA_DIR, "sample_hr.csv")

    def test_file_exists(self):
        assert os.path.exists(self.CSV_PATH), "sample_hr.csv not found in data/"

    def test_required_columns(self):
        df = pd.read_csv(self.CSV_PATH)
        expected = [
            "employee_id", "first_name", "last_name", "email",
            "department_id", "position_id", "hire_date",
            "termination_date", "is_active", "salary",
        ]
        for col in expected:
            assert col in df.columns, f"Missing required column: {col}"

    def test_no_null_employee_ids(self):
        df = pd.read_csv(self.CSV_PATH)
        assert df["employee_id"].notna().all(), "employee_id contains NULLs"

    def test_no_null_hire_dates(self):
        df = pd.read_csv(self.CSV_PATH)
        assert df["hire_date"].notna().all(), "hire_date contains NULLs"

    def test_unique_employee_ids(self):
        df = pd.read_csv(self.CSV_PATH)
        assert df["employee_id"].is_unique, "employee_id has duplicates"

    def test_has_records(self):
        df = pd.read_csv(self.CSV_PATH)
        assert len(df) > 0, "sample_hr.csv is empty"


# ===========================================================================
# Test: sample_performance.csv
# ===========================================================================
class TestSamplePerformanceData:
    """Validates structure of the performance reviews dataset."""

    CSV_PATH = os.path.join(DATA_DIR, "sample_performance.csv")

    def test_file_exists(self):
        assert os.path.exists(self.CSV_PATH), "sample_performance.csv not found"

    def test_required_columns(self):
        df = pd.read_csv(self.CSV_PATH)
        expected = [
            "review_id", "employee_id", "review_date",
            "overall_rating", "department_id",
        ]
        for col in expected:
            assert col in df.columns, f"Missing required column: {col}"

    def test_rating_range(self):
        """Ratings should be between 1.0 and 5.0."""
        df = pd.read_csv(self.CSV_PATH)
        assert (df["overall_rating"] >= 1.0).all(), "Rating below 1.0 found"
        assert (df["overall_rating"] <= 5.0).all(), "Rating above 5.0 found"

    def test_unique_review_ids(self):
        df = pd.read_csv(self.CSV_PATH)
        assert df["review_id"].is_unique, "review_id has duplicates"


# ===========================================================================
# Test: sample_big_five.csv
# ===========================================================================
class TestSampleBigFiveData:
    """Validates structure of the Big Five psychometric dataset."""

    CSV_PATH = os.path.join(DATA_DIR, "sample_big_five.csv")

    def test_file_exists(self):
        assert os.path.exists(self.CSV_PATH), "sample_big_five.csv not found"

    def test_required_columns(self):
        df = pd.read_csv(self.CSV_PATH)
        expected = [
            "employee_code", "assessment_date",
            "openness", "conscientiousness", "extraversion",
            "agreeableness", "neuroticism",
        ]
        for col in expected:
            assert col in df.columns, f"Missing required column: {col}"
