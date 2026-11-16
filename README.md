# Rising US Yields: The Fault Lines Have Moved

Writing sample for the Goldman Sachs Global Investment Research internships, November 2026. Public data only; the views are my own and do not necessarily reflect those of the ECB.

| Path | Contents |
|---|---|
| `report/writing_sample.pdf` | the note |
| `report/writing_sample.tex` | its source (`SimpleStef.tex` is my LaTeX preamble) |
| `figures/` | the three exhibits |
| `code/` | MATLAB code: download, analysis, exhibits, word count |
| `data/raw/` | the downloaded data, as of 14 November 2026 |
| `data/processed/` | every estimate used in the note and the exhibits |

## Rebuild

```
matlab -batch "run('code/main.m')"
cd report && latexmk -pdf writing_sample.tex
```

`main.m` runs `step2_analysis`, `step3_figures` and `step4_wordcount`. The download (`step1_download`, which uses curl) is off by default, so the 11th November 2026 vintage stays fixed; set `refresh = true` in `main.m` to download again. Tested with MATLAB R2025b and the Statistics and Machine Learning Toolbox.

## Method

1. **Sell-off and rally betas (Exhibit 1).** For each market, monthly changes in the 10-year yield are regressed on monthly changes in the US 10-year, with a kink at zero:

   $$\Delta y_t = \alpha + \beta^{+} \max(\Delta y^{\mathrm{US}}_t, 0) + \beta^{-} \min(\Delta y^{\mathrm{US}}_t, 0) + \varepsilon_t$$

   Newey-West standard errors (3 lags) and a Wald test of $\beta^{+} = \beta^{-}$, for 2000-12 and 2013-26.
2. **What explains the gap (Exhibit 2).** Cross-section of $\beta^{+} - \beta^{-}$ on IMF current-account and budget balances (period averages), with HC1 standard errors. On its own, the current account has $t = -1.8$ in 2000-12 and the budget $t = -2.8$ in 2013-26 ($-0.06$ per point of GDP); with both balances in the regression, the other one has $t = -0.2$ and $0.1$. Without Norway the 2013-26 slope is $-0.08$ with $t = -1.5$, and the Spearman correlation is $-0.51$ ($p = 0.02$). Adding the monthly change in the VIX to the 2013-26 regressions roughly halves the gap in South Africa, Hungary and Italy.
3. **Out-of-sample test (Exhibit 3).** Betas estimated on 2000-25 are applied month by month to the US moves of February-September 2026, with no drift. The 90% range is $\pm 1.645$ standard errors, combining the long-run variance of the residuals over the window with the sampling error of the betas. Only Japan is outside its range ($+70$bp against $\pm 39$bp); France comes closest ($+52$bp against $\pm 54$bp).
4. **Scenario.** GS's forecast of 4.6% for the US 10-year at end-2027 (Global Markets Outlook 2027, 12 November 2026), from 5.10% on 12 November, run through the 2013-26 betas along two paths: a steady 50bp rally, and a 50bp sell-off followed by 100bp of rallies. The ranges use the same formula over 14 months. Spreads over Bunds, $s_t$, come from $\Delta s_t = a + b \, \lvert \Delta y^{\mathrm{US}}_t \rvert + c \, \Delta y^{\mathrm{US}}_t + \varepsilon_t$.

## Data

- 10-year yields for 21 markets: OECD, via FRED. Monthly averages, except Japan and Switzerland (end of month); each market is paired with the US 10-year on the same basis, and the Japan series is checked against daily MOF data.
- US Treasury, TIPS and breakeven yields, the Kim-Wright term premium, the VIX and Brent: FRED.
- Current-account and budget balances: IMF World Economic Outlook (DataMapper).
- Events named in the note, checked on 15 November 2026: the BoJ's move to 1.25% on 18 September 2026; Hungary's election on 12 April 2026; France's 10-year OAT above 5% on 21-22 October 2026; the week of 7-11 April 2025, when the US 10-year rose 47bp and Bund yields were broadly unchanged; IMF projections of 2026 deficits of 7.2% of GDP for Poland and 7.3% for Hungary.

## Limitations

- The betas measure co-movement, so common shocks, such as this year's energy shock (would have liked to investigate in greater detail, but it is more directly part of my current job), move all yields together.
- The asymmetry is concentrated in stress episodes (the euro crisis, March 2020). For the UK and France the 2013-26 gap is not significant once 2020-21 is dropped ($p = 0.17$ and $0.11$).
- The cross-section has only 20-21 markets; Japan and India, with large deficits but domestic investor bases, sit below the line.
- Coverage is limited to markets with an OECD 10-year series on FRED, which leaves out Turkey, Brazil and Indonesia, among others.
- Monthly averages smooth out daily moves.
- Over a year, local news dominates: the scenario's 90% ranges run from $\pm 58$bp (Canada) to $\pm 220$bp (Hungary).
