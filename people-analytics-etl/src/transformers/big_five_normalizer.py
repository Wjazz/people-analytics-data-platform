"""
Big Five Personality Normalizer.

Transforms raw Big Five scores to T-scores (M=50, SD=10) for standardized interpretation.
"""

import logging
from typing import Dict, List, Optional
import pandas as pd
import numpy as np

logger = logging.getLogger(__name__)


class BigFiveNormalizer:
    """
    Normalizes Big Five personality trait scores to T-scores.
    
    T-Score formula: T = ((X - M) / SD) * 10 + 50
    where:
        X = raw score
        M = population mean
        SD = population standard deviation
    """
    
    # Big Five traits (OCEAN)
    TRAITS = [
        'openness',
        'conscientiousness', 
        'extraversion',
        'agreeableness',
        'neuroticism'
    ]
    
    # Population norms (from NEO-FFI standardization sample)
    # These are example values - replace with actual norms from your instrument
    POPULATION_NORMS = {
        'openness': {'mean': 3.5, 'std': 0.6},
        'conscientiousness': {'mean': 3.8, 'std': 0.6},
        'extraversion': {'mean': 3.4, 'std': 0.7},
        'agreeableness': {'mean': 3.6, 'std': 0.6},
        'neuroticism': {'mean': 2.8, 'std': 0.8}
    }
    
    def __init__(self, use_sample_norms: bool = False):
        """
        Initialize normalizer.
        
        Args:
            use_sample_norms: If True, calculate means/stds from sample data
                             If False, use population norms (POPULATION_NORMS)
        """
        self.use_sample_norms = use_sample_norms
        self.sample_norms: Optional[Dict] = None
        
    def calculate_t_score(
        self, 
        raw_score: float, 
        mean: float, 
        std: float
    ) -> float:
        """
        Calculate T-score from raw score.
        
        Args:
            raw_score: Original score
            mean: Population/sample mean
            std: Population/sample standard deviation
            
        Returns:
            T-score (M=50, SD=10)
        """
        if std == 0:
            logger.warning("Standard deviation is 0, returning 50 (mean)")
            return 50.0
        
        t_score = ((raw_score - mean) / std) * 10 + 50
        return round(t_score, 2)
    
    def calculate_percentile(self, t_score: float) -> int:
        """
        Convert T-score to percentile rank (approximate).
        
        Assumes normal distribution.
        
        Args:
            t_score: T-score value
            
        Returns:
            Percentile rank (0-100)
        """
        # Convert T-score to Z-score
        z_score = (t_score - 50) / 10
        
        # Use normal CDF to get percentile
        from scipy.stats import norm
        percentile = norm.cdf(z_score) * 100
        
        return int(round(percentile))
    
    def fit_sample_norms(self, df: pd.DataFrame) -> Dict:
        """
        Calculate means and standard deviations from sample data.
        
        Args:
            df: DataFrame with raw Big Five scores
            
        Returns:
            Dictionary with mean/std for each trait
        """
        norms = {}
        
        for trait in self.TRAITS:
            if trait in df.columns:
                norms[trait] = {
                    'mean': df[trait].mean(),
                    'std': df[trait].std()
                }
                logger.info(
                    f"{trait}: M={norms[trait]['mean']:.2f}, "
                    f"SD={norms[trait]['std']:.2f}"
                )
            else:
                logger.warning(f"Trait {trait} not found in DataFrame")
        
        self.sample_norms = norms
        return norms
    
    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Transform raw Big Five scores to T-scores.
        
        Args:
            df: DataFrame with columns: openness, conscientiousness, 
                extraversion, agreeableness, neuroticism (raw scores)
                
        Returns:
            DataFrame with additional T-score and percentile columns
        """
        df_copy = df.copy()
        
        # Determine which norms to use
        if self.use_sample_norms:
            if self.sample_norms is None:
                logger.info("Calculating sample norms from data...")
                self.fit_sample_norms(df_copy)
            norms = self.sample_norms
        else:
            norms = self.POPULATION_NORMS
        
        # Calculate T-scores for each trait
        for trait in self.TRAITS:
            if trait not in df_copy.columns:
                logger.warning(f"Skipping {trait} - not found in DataFrame")
                continue
            
            mean = norms[trait]['mean']
            std = norms[trait]['std']
            
            # T-score column
            t_col = f'{trait}_t_score'
            df_copy[t_col] = df_copy[trait].apply(
                lambda x: self.calculate_t_score(x, mean, std)
            )
            
            # Percentile column
            percentile_col = f'{trait}_percentile'
            df_copy[percentile_col] = df_copy[t_col].apply(
                self.calculate_percentile
            )
            
            logger.info(f"Normalized {trait}: {len(df_copy)} records")
        
        return df_copy
    
    def transform_single(self, raw_scores: Dict[str, float]) -> Dict[str, float]:
        """
        Transform a single record's raw scores to T-scores.
        
        Args:
            raw_scores: Dict with keys matching TRAITS, values are raw scores
            
        Returns:
            Dict with T-scores and percentiles
            
        Example:
            >>> normalizer = BigFiveNormalizer()
            >>> scores = {
            ...     'openness': 4.2,
            ...     'conscientiousness': 3.9,
            ...     'extraversion': 2.8,
            ...     'agreeableness': 3.1,
            ...     'neuroticism': 2.5
            ... }
            >>> result = normalizer.transform_single(scores)
            >>> print(result['extraversion_t_score'])  # ~44
        """
        norms = self.sample_norms if self.use_sample_norms else self.POPULATION_NORMS
        result = {}
        
        for trait in self.TRAITS:
            if trait not in raw_scores:
                continue
            
            raw_score = raw_scores[trait]
            mean = norms[trait]['mean']
            std = norms[trait]['std']
            
            t_score = self.calculate_t_score(raw_score, mean, std)
            percentile = self.calculate_percentile(t_score)
            
            result[f'{trait}_t_score'] = t_score
            result[f'{trait}_percentile'] = percentile
        
        return result


if __name__ == "__main__":
    # Example usage
    logging.basicConfig(level=logging.INFO)
    
    # Sample data
    data = {
        'employee_id': [1, 2, 3, 4, 5],
        'openness': [4.2, 3.1, 3.8, 4.5, 2.9],
        'conscientiousness': [3.9, 4.2, 3.5, 4.0, 3.3],
        'extraversion': [2.8, 3.9, 3.2, 2.5, 4.1],
        'agreeableness': [3.1, 4.0, 3.6, 2.9, 3.8],
        'neuroticism': [2.5, 3.2, 2.8, 3.5, 2.0]
    }
    
    df = pd.DataFrame(data)
    
    # Use population norms
    normalizer = BigFiveNormalizer(use_sample_norms=False)
    df_normalized = normalizer.transform(df)
    
    print("\nNormalized Big Five Scores:")
    print(df_normalized[['employee_id', 'extraversion', 'extraversion_t_score', 'extraversion_percentile']].head())
    
    # Single record transformation
    single_scores = {
        'openness': 4.2,
        'conscientiousness': 3.9,
        'extraversion': 2.8,
        'agreeableness': 3.1,
        'neuroticism': 2.5
    }
    
    result = normalizer.transform_single(single_scores)
    print(f"\nSingle record T-scores: {result}")
