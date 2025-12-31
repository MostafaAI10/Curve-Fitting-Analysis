# Advanced Curve Fitting with Cubic Splines (MATLAB)

## Overview

This project implements a robust, high-resolution curve fitting pipeline for noisy and highly oscillatory data using cubic spline approximation in MATLAB. The workflow emphasizes data integrity, numerical stability, model diagnostics, and statistical validation, making it suitable for engineering analysis, scientific research, and academic reporting.

The core fitting method is based on MATLAB's `spap2` function (least-squares cubic splines with user-defined breakpoints), supported by automatic fallback strategies to ensure reliability.

## Key Features

- ✅ Comprehensive data cleaning and validation
- ✅ Uniform multi-breakpoint spline strategy for oscillatory signals
- ✅ Cubic spline fitting using `spap2` (order-4 splines)
- ✅ Automatic fallback to smoothing splines if needed
- ✅ Detailed performance metrics (KPIs)
- ✅ Extensive visual diagnostics
- ✅ Export of figures and numerical results
- ✅ Publication-ready plots and summaries

## Project Structure

```
.
├── data_to_curve_fit.txt        # Input data file (x, y)
├── curve_fitting_analysis.m     # Main MATLAB script
├── curve_fitting_overview.png   # Summary visualization
├── curve_fitting_detailed.png   # Detailed diagnostics
├── fitting_results.xlsx         # Numerical output (x, y, fit, residuals)
└── README.md                    # Project documentation
```

## Requirements

- **MATLAB R2020a or later** (recommended)
- **MATLAB toolboxes:**
  - Curve Fitting Toolbox
  - Spline Toolbox

## Input Data Format

The input file (`data_to_curve_fit.txt`) must contain two numeric columns:

```
x₁   y₁
x₂   y₂
x₃   y₃
⋮    ⋮
```

### Constraints

- x values must be numeric
- Duplicate x values are automatically removed
- NaN and Inf values are filtered out

## Methodology

### 1. Data Cleaning

- Removes NaN / Inf values
- Removes duplicate x entries
- Sorts data in ascending x

### 2. Breakpoint Strategy

- Uses uniformly spaced breakpoints
- Optimized for highly oscillatory data
- Default: 30 breakpoints across data range

### 3. Spline Fitting

**Primary method:**

```matlab
sp = spap2(breakpoints, 4, x, y);
```

- Order 4 → cubic spline
- Least-squares approximation
- Enforces smoothness up to second derivative

**Fallback methods (automatic):**

- `csaps` (smoothing spline)
- `fit(..., 'smoothingspline')`

## Performance Metrics (KPIs)

The script computes:

- **2-Norm of Residuals**
- **Squared Error (SE)**
- **Root Mean Squared Error (RMSE)**
- **Coefficient of Determination (R²)**
- **Relative RMSE** (% of data range)
- **Bias Ratio**

Each metric is automatically interpreted as:

- ✅ Excellent
- 🟢 Good
- 🟡 Acceptable
- 🔴 Poor

## Visual Outputs

### 1. Overview Figure

- Raw data
- Curvature estimation
- Fitted spline
- Residuals

### 2. Detailed Diagnostics

- High-resolution fit vs data
- Breakpoint visualization
- Residual distribution
- Histogram with normal distribution overlay

## Output Files

| File                           | Description                  |
|--------------------------------|------------------------------|
| `curve_fitting_overview.png`   | Summary visualization        |
| `curve_fitting_detailed.png`   | Detailed diagnostics         |
| `fitting_results.xlsx`         | Numerical results table      |

### Example Results Table

| X   | Y_Original | Y_Fitted | Residuals      |
|-----|------------|----------|----------------|
| x₁  | y₁         | ŷ₁       | y₁ − ŷ₁        |
| x₂  | y₂         | ŷ₂       | y₂ − ŷ₂        |
| ⋮   | ⋮          | ⋮        | ⋮              |

## Why Cubic Splines (`spap2`)?

- **Local adaptability** (piecewise modeling)
- **Smoothness guaranteed** up to second derivative
- **Avoids Runge's phenomenon**
- **More stable** than global polynomial fitting
- **Ideal** for experimental and oscillatory data

## Use Cases

- Signal processing
- Experimental data smoothing
- Sensor data analysis
- Engineering curve fitting
- Scientific data modeling
- Academic coursework and research

## Limitations

- Breakpoints are currently user-defined (uniform)
- Extremely sparse datasets may require fewer breakpoints
- Overfitting is possible if breakpoints are excessively dense

## Future Improvements

- 🔹 Adaptive breakpoint placement (curvature-based)
- 🔹 Automatic breakpoint optimization
- 🔹 Cross-validation for spline complexity
- 🔹 Support for multivariate fitting
- 🔹 Noise modeling and uncertainty quantification

## License

This project is provided for educational and research purposes.

## Author

**Mostafa Abdelhamed**