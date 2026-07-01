Mobile Phone Price Classification — Hardware Analysis

Tools: MySQL, HTML/CSS/JavaScript

Dataset: 
- Source: Mobile Price Classification dataset (Kaggle)
- Split: 2,000 training rows + 1,000 test rows
- Price tiers: 0 = Budget, 1 = Mid-Range, 2 = High-End, 3 = Flagship
- Distribution: Perfectly balanced — 500 phones per tier
- Features: 20 specs including RAM, battery, screen resolution, camera, cores, clock speed, and connectivity flags (4G, 3G, WiFi, Bluetooth, Dual SIM, Touch Screen)

This dataset contains 2,000 mobile phones with 20 hardware and connectivity specifications, each labeled with a price range from Budget to Flagship. My goal was to figure out which specs genuinely separate cheap phones from expensive ones — and which ones don't matter at all.
The answer turned out to be surprisingly simple: RAM explains nearly everything.

Key Findings

RAM is the dominant predictor
- Pearson correlation with price: **r = 0.917**
- Budget phones average 785 MB RAM; flagship phones average 3,449 MB — a **4.4× difference**
- No other single feature comes close to this predictive power

Battery is meaningful but secondary
- Correlation: r = 0.201
- Flagship phones average 1,380 mAh vs. 1,117 mAh for budget phones
- Real gap, but much smaller than RAM

Screen resolution ranks 3rd and 4th
- Pixel width (r = 0.166) and pixel height (r = 0.149) together form the second-strongest signal
- Higher price generally means a sharper display

Connectivity features are noise
- 4G, WiFi, Bluetooth, Dual SIM, and Touch Screen adoption rates are nearly flat across all four tiers (~49–55%)
- These features do not distinguish expensive phones from cheap ones in this dataset

Camera barely moves
- Primary camera goes from 9.6 MP (budget) to 10.2 MP (flagship) — effectively flat
- Front camera is similarly unchanged across tiers

Clock speed is the most surprising finding
- Correlation with price: **r = −0.007**
- Budget phones average slightly faster clock speeds than flagship phones
- Clock speed is essentially a noise variable in this dataset
