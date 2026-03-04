"""
Unit tests for psychometric transformers.

Tests BigFiveNormalizer and PsyCapCalculator with known inputs/outputs,
edge cases (zero std dev, boundary thresholds), and batch transforms.
"""

import pytest
import pandas as pd
import sys
import os

# Add src to path so we can import transformers directly
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), "src"))

from transformers.big_five_normalizer import BigFiveNormalizer
from transformers.psycap_calculator import PsyCapCalculator


# ===========================================================================
# BigFiveNormalizer Tests
# ===========================================================================
class TestBigFiveNormalizer:
    """Unit tests for T-score normalization logic."""

    @pytest.fixture
    def normalizer(self):
        return BigFiveNormalizer(use_sample_norms=False)

    # --- T-Score calculation ---
    def test_t_score_at_mean_equals_50(self, normalizer):
        """When raw_score == population mean, T-score should be exactly 50."""
        result = normalizer.calculate_t_score(raw_score=3.5, mean=3.5, std=0.6)
        assert result == 50.0

    def test_t_score_one_sd_above(self, normalizer):
        """One SD above the mean → T = 60."""
        result = normalizer.calculate_t_score(raw_score=4.1, mean=3.5, std=0.6)
        assert result == 60.0

    def test_t_score_one_sd_below(self, normalizer):
        """One SD below the mean → T = 40."""
        result = normalizer.calculate_t_score(raw_score=2.9, mean=3.5, std=0.6)
        assert result == 40.0

    def test_t_score_zero_std_returns_50(self, normalizer):
        """Edge case: std=0 should return 50 (not crash with ZeroDivisionError)."""
        result = normalizer.calculate_t_score(raw_score=4.0, mean=3.5, std=0)
        assert result == 50.0

    # --- DataFrame transformation ---
    def test_transform_adds_tscore_columns(self, normalizer):
        """transform() should add _t_score and _percentile columns."""
        df = pd.DataFrame({
            "openness": [3.5],
            "conscientiousness": [3.8],
            "extraversion": [3.4],
            "agreeableness": [3.6],
            "neuroticism": [2.8],
        })
        result = normalizer.transform(df)

        for trait in BigFiveNormalizer.TRAITS:
            assert f"{trait}_t_score" in result.columns
            assert f"{trait}_percentile" in result.columns

    def test_transform_preserves_original_columns(self, normalizer):
        """Original trait columns should remain after transformation."""
        df = pd.DataFrame({
            "employee_id": [1],
            "openness": [4.0],
            "conscientiousness": [4.0],
            "extraversion": [3.5],
            "agreeableness": [3.5],
            "neuroticism": [3.0],
        })
        result = normalizer.transform(df)
        assert "employee_id" in result.columns
        assert "openness" in result.columns

    # --- Single record ---
    def test_transform_single(self, normalizer):
        scores = {
            "openness": 3.5,
            "conscientiousness": 3.8,
            "extraversion": 3.4,
            "agreeableness": 3.6,
            "neuroticism": 2.8,
        }
        result = normalizer.transform_single(scores)
        # All traits at population mean → T = 50
        assert result["openness_t_score"] == 50.0
        assert result["conscientiousness_t_score"] == 50.0
        assert result["extraversion_t_score"] == 50.0
        assert result["agreeableness_t_score"] == 50.0
        assert result["neuroticism_t_score"] == 50.0


# ===========================================================================
# PsyCapCalculator Tests
# ===========================================================================
class TestPsyCapCalculator:
    """Unit tests for PsyCap composite score and categorization."""

    @pytest.fixture
    def calculator(self):
        return PsyCapCalculator()

    # --- Composite calculation ---
    def test_composite_average(self, calculator):
        """Composite = mean of 4 dimensions."""
        result = calculator.calculate_composite(4.0, 4.0, 4.0, 4.0)
        assert result == 4.0

    def test_composite_mixed(self, calculator):
        result = calculator.calculate_composite(5.0, 3.0, 4.0, 4.0)
        assert result == 4.0

    def test_composite_rounding(self, calculator):
        """Should round to 2 decimal places."""
        result = calculator.calculate_composite(4.1, 4.2, 4.3, 4.7)
        # Due to IEEE 754 floating-point, (4.1+4.2+4.3+4.7)/4 is slightly
        # above 4.325, so round(..., 2) produces 4.33
        assert result == 4.33

    # --- Categorization ---
    def test_categorize_low(self, calculator):
        assert calculator.categorize(2.0) == "Low"
        assert calculator.categorize(3.4) == "Low"

    def test_categorize_medium(self, calculator):
        assert calculator.categorize(3.5) == "Medium"
        assert calculator.categorize(4.4) == "Medium"

    def test_categorize_high(self, calculator):
        assert calculator.categorize(4.5) == "High"
        assert calculator.categorize(6.0) == "High"

    def test_categorize_exact_thresholds(self, calculator):
        """Boundary values: 3.5 = Medium, 4.5 = High."""
        assert calculator.categorize(3.5) == "Medium"
        assert calculator.categorize(4.5) == "High"

    # --- Validation ---
    def test_validate_scores_valid(self, calculator):
        scores = {"hope": 4.5, "self_efficacy": 5.0, "resilience": 4.2, "optimism": 4.8}
        assert calculator.validate_scores(scores) is True

    def test_validate_scores_missing_dimension(self, calculator):
        scores = {"hope": 4.5, "self_efficacy": 5.0}  # missing resilience, optimism
        assert calculator.validate_scores(scores) is False

    def test_validate_scores_out_of_range(self, calculator):
        scores = {"hope": 7.0, "self_efficacy": 5.0, "resilience": 4.2, "optimism": 4.8}
        assert calculator.validate_scores(scores) is False

    # --- DataFrame transformation ---
    def test_transform_adds_composite_columns(self, calculator):
        df = pd.DataFrame({
            "hope": [4.5],
            "self_efficacy": [5.0],
            "resilience": [4.2],
            "optimism": [4.8],
        })
        result = calculator.transform(df)
        assert "psycap_composite" in result.columns
        assert "psycap_category" in result.columns

    def test_transform_missing_columns_raises(self, calculator):
        df = pd.DataFrame({"hope": [4.5]})  # missing 3 dimensions
        with pytest.raises(ValueError, match="Missing required columns"):
            calculator.transform(df)

    # --- Dimension strengths ---
    def test_dimension_strengths(self, calculator):
        scores = {"hope": 5.5, "self_efficacy": 4.5, "resilience": 3.0, "optimism": 4.0}
        result = calculator.get_dimension_strengths(scores)
        assert result["hope"] == "Strength"
        assert result["self_efficacy"] == "Average"
        assert result["resilience"] == "Weakness"
        assert result["optimism"] == "Average"
