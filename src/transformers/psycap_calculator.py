"""
Psychological Capital (PsyCap) Calculator.

Calculates composite PsyCap score from Hope, Self-Efficacy, Resilience, and Optimism.
"""

import logging
from typing import Dict, List
import pandas as pd

logger = logging.getLogger(__name__)


class PsyCapCalculator:
    """
    Calculates Psychological Capital (PsyCap) composite scores.
    
    PsyCap is typically measured on a 1-6 Likert scale across 4 dimensions:
    - Hope (H): Goal-directed energy and pathways
    - Self-Efficacy (E): Confidence in ability to succeed
    - Resilience (R): Bouncing back from adversity
    - Optimism (O): Positive attribution about succeeding
    
    Composite Score = Mean(H, E, R, O)
    """
    
    DIMENSIONS = ['hope', 'self_efficacy', 'resilience', 'optimism']
    
    # Categorization thresholds (for PCQ-24/PCQ-12 on 1-6 scale)
    THRESHOLDS = {
        'low': 3.5,      # Below 3.5 = Low PsyCap
        'medium': 4.5    # 3.5-4.5 = Medium, Above 4.5 = High
    }
    
    def __init__(self, scale_min: float = 1.0, scale_max: float = 6.0):
        """
        Initialize calculator.
        
        Args:
            scale_min: Minimum value of Likert scale
            scale_max: Maximum value of Likert scale
        """
        self.scale_min = scale_min
        self.scale_max = scale_max
    
    def validate_scores(self, scores: Dict[str, float]) -> bool:
        """
        Validate that scores are within expected range.
        
        Args:
            scores: Dict with PsyCap dimension scores
            
        Returns:
            True if all scores valid, False otherwise
        """
        for dim in self.DIMENSIONS:
            if dim not in scores:
                logger.warning(f"Missing dimension: {dim}")
                return False
            
            score = scores[dim]
            if not (self.scale_min <= score <= self.scale_max):
                logger.warning(
                    f"{dim} score {score} outside range "
                    f"[{self.scale_min}, {self.scale_max}]"
                )
                return False
        
        return True
    
    def calculate_composite(
        self, 
        hope: float, 
        self_efficacy: float, 
        resilience: float, 
        optimism: float
    ) -> float:
        """
        Calculate composite PsyCap score.
        
        Args:
            hope: Hope score (1-6)
            self_efficacy: Self-Efficacy score (1-6)
            resilience: Resilience score (1-6)
            optimism: Optimism score (1-6)
            
        Returns:
            Composite PsyCap score (mean of 4 dimensions)
        """
        composite = (hope + self_efficacy + resilience + optimism) / 4
        return round(composite, 2)
    
    def categorize(self, composite_score: float) -> str:
        """
        Categorize PsyCap level.
        
        Args:
            composite_score: PsyCap composite score
            
        Returns:
            Category: "Low", "Medium", or "High"
        """
        if composite_score < self.THRESHOLDS['low']:
            return "Low"
        elif composite_score < self.THRESHOLDS['medium']:
            return "Medium"
        else:
            return "High"
    
    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Calculate PsyCap composite and category for DataFrame.
        
        Args:
            df: DataFrame with columns: hope, self_efficacy, resilience, optimism
            
        Returns:
            DataFrame with additional columns: psycap_composite, psycap_category
        """
        df_copy = df.copy()
        
        # Validate required columns
        missing_cols = [col for col in self.DIMENSIONS if col not in df_copy.columns]
        if missing_cols:
            raise ValueError(f"Missing required columns: {missing_cols}")
        
        # Calculate composite
        df_copy['psycap_composite'] = df_copy.apply(
            lambda row: self.calculate_composite(
                row['hope'],
                row['self_efficacy'],
                row['resilience'],
                row['optimism']
            ),
            axis=1
        )
        
        # Categorize
        df_copy['psycap_category'] = df_copy['psycap_composite'].apply(
            self.categorize
        )
        
        logger.info(f"Calculated PsyCap for {len(df_copy)} records")
        
        # Log distribution
        category_counts = df_copy['psycap_category'].value_counts()
        logger.info(f"PsyCap distribution: {category_counts.to_dict()}")
        
        return df_copy
    
    def transform_single(self, scores: Dict[str, float]) -> Dict[str, any]:
        """
        Calculate PsyCap for a single record.
        
        Args:
            scores: Dict with keys: hope, self_efficacy, resilience, optimism
            
        Returns:
            Dict with psycap_composite and psycap_category
            
        Example:
            >>> calculator = PsyCapCalculator()
            >>> scores = {
            ...     'hope': 4.5,
            ...     'self_efficacy': 5.0,
            ...     'resilience': 4.2,
            ...     'optimism': 4.8
            ... }
            >>> result = calculator.transform_single(scores)
            >>> print(result)
            {'psycap_composite': 4.62, 'psycap_category': 'High'}
        """
        if not self.validate_scores(scores):
            raise ValueError("Invalid PsyCap scores")
        
        composite = self.calculate_composite(
            scores['hope'],
            scores['self_efficacy'],
            scores['resilience'],
            scores['optimism']
        )
        
        category = self.categorize(composite)
        
        return {
            'psycap_composite': composite,
            'psycap_category': category
        }
    
    def get_dimension_strengths(self, scores: Dict[str, float]) -> Dict[str, str]:
        """
        Identify which PsyCap dimensions are strengths vs weaknesses.
        
        Args:
            scores: Dict with hope, self_efficacy, resilience, optimism
            
        Returns:
            Dict mapping each dimension to "Strength", "Average", or "Weakness"
        """
        results = {}
        
        for dim in self.DIMENSIONS:
            score = scores[dim]
            
            if score >= 5.0:  # Top 33%
                results[dim] = "Strength"
            elif score >= 4.0:  # Middle 33%
                results[dim] = "Average"
            else:  # Bottom 33%
                results[dim] = "Weakness"
        
        return results


if __name__ == "__main__":
    # Example usage
    logging.basicConfig(level=logging.INFO)
    
    # Sample data
    data = {
        'employee_id': [1, 2, 3, 4, 5],
        'hope': [4.5, 3.2, 4.8, 5.2, 2.8],
        'self_efficacy': [5.0, 3.8, 4.5, 5.5, 3.0],
        'resilience': [4.2, 3.0, 4.0, 4.8, 2.5],
        'optimism': [4.8, 3.5, 4.6, 5.0, 3.2]
    }
    
    df = pd.DataFrame(data)
    
    # Calculate PsyCap
    calculator = PsyCapCalculator()
    df_psycap = calculator.transform(df)
    
    print("\nPsyCap Scores:")
    print(df_psycap[['employee_id', 'psycap_composite', 'psycap_category']])
    
    # Single record analysis
    single_scores = {
        'hope': 4.5,
        'self_efficacy': 5.0,
        'resilience': 4.2,
        'optimism': 4.8
    }
    
    result = calculator.transform_single(single_scores)
    print(f"\nSingle record PsyCap: {result}")
    
    strengths = calculator.get_dimension_strengths(single_scores)
    print(f"Dimension analysis: {strengths}")
