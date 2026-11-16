%% STEP2_ANALYSIS  How much of a rise in US 10y yields do other bond markets import?
%
% Inputs : data/raw/fred (OECD 10y yields via FRED, US Treasury and TIPS yields, Kim-Wright
%          term premium, VIX, Brent), data/raw/imf (WEO balances) and data/raw/cb/jgbcme*.csv
%          (MOF daily JGB yields, used as a check).
% Outputs: data/processed/*.csv and xsec_stats.json for the exhibits, plus the numbers quoted
%          in the text, printed to the command window.
%
% Method : monthly changes in 10y yields (bp) regressed on monthly changes in the US 10y, with
%          separate slopes for months in which US yields rose (sell-off beta) and fell (rally
%          beta). OECD series are monthly averages except Japan and Switzerland, which are
%          end-of-month; each market is paired with the US series on the same basis.
%          Newey-West standard errors (3 lags, Bartlett weights, no small-sample correction),
%          normal p-values. Every output file is written to 8 significant digits.
% Run    : run code/step2_analysis.m   (from anywhere)

clear
root = fileparts(fileparts(mfilename("fullpath")));
out = fullfile(root, "data", "processed");
if ~isfolder(out), mkdir(out); end

% code, name, region, ISO3 (for the IMF data)
M = ["CA" "Canada"       "G10"       "CAN"
     "AU" "Australia"    "G10"       "AUS"
     "NZ" "New Zealand"  "G10"       "NZL"
     "GB" "UK"           "G10"       "GBR"
     "SE" "Sweden"       "G10"       "SWE"
     "NO" "Norway"       "G10"       "NOR"
     "CH" "Switzerland"  "G10"       "CHE"
     "JP" "Japan"        "G10"       "JPN"
     "DE" "Germany"      "Euro area" "DEU"
     "FR" "France"       "Euro area" "FRA"
     "IT" "Italy"        "Euro area" "ITA"
     "ES" "Spain"        "Euro area" "ESP"
     "KR" "Korea"        "EM"        "KOR"
     "IL" "Israel"       "EM"        "ISR"
     "MX" "Mexico"       "EM"        "MEX"
     "CL" "Chile"        "EM"        "CHL"
     "ZA" "South Africa" "EM"        "ZAF"
     "PL" "Poland"       "EM"        "POL"
     "HU" "Hungary"      "EM"        "HUN"
     "CZ" "Czechia"      "EM"        "CZE"
     "IN" "India"        "EM"        "IND"];
cc = M(:, 1); names = M(:, 2); region = M(:, 3); iso = M(:, 4);
nm = numel(cc);
eom = ismember(cc, ["JP" "CH"]);     % OECD convention for these two (checked against MOF data)
SAMPLE = ["2000-01" "2026-09"];
TEST_START = "2026-02";              % trough of US 10y before this year's sell-off

%% data: one monthly grid (months coded as 12*year + month) for every series
for j = 1:nm
    sid = "IRLTLT01" + cc(j) + "M156N";
    if cc(j) == "IN", sid = "INDIRLTLT01STM"; end
    [t, v] = fred(root, sid);
    oecd(j).k = 12*year(t) + month(t); oecd(j).v = v; %#ok<SAGROW>
end
[t10, v10] = fred(root, "DGS10");
[ku, us_avg] = monthly(t10, v10, "avg");
[~, us_eom] = monthly(t10, v10, "eom");

k = (min([arrayfun(@(s) s.k(1), oecd) ku(1)]) : max([arrayfun(@(s) s.k(end), oecd) ku(end)]))';
Y = nan(numel(k), nm);
for j = 1:nm
    Y(:, j) = ongrid(k, oecd(j).k, oecd(j).v);
end
D.k = k;
D.dy = [nan(1, nm); diff(Y)]*100;                       % bp changes
D.dx_avg = ongrid(k, ku, [NaN; diff(us_avg)]*100);
D.dx_eom = ongrid(k, ku, [NaN; diff(us_eom)]*100);
D.eom = eom;

%% 1. Sell-off and rally betas, 2000-2026
F = struct();
for j = 1:nm
    [y, x] = pair(D, j, SAMPLE(1), SAMPLE(2));
    [m, p] = updown(y, x);
    a = ols(y, x, 3);
    F.n(j, 1) = int32(numel(y));
    F.beta(j, 1) = a.b(2); F.beta_se(j, 1) = a.se(2);
    F.up(j, 1) = m.b(2); F.up_se(j, 1) = m.se(2); F.dn(j, 1) = m.b(3); F.dn_se(j, 1) = m.se(3);
    F.gap(j, 1) = m.b(2) - m.b(3); F.p_gap(j, 1) = p;
end
write_csv(fullfile(out, "betas_updown.csv"), ...
    ["cc" "name" "region" "n" "beta" "beta_se" "up" "up_se" "dn" "dn_se" "gap" "p_gap"], ...
    {cc, names, region, F.n, F.beta, F.beta_se, F.up, F.up_se, F.dn, F.dn_se, F.gap, F.p_gap});

%% 2. Sub-periods: 2000-12, 2013-26, 2022-26
PER = ["2000_12" "2000-01" "2012-12"; "2013_26" "2013-01" SAMPLE(2); "2022_26" "2022-01" SAMPLE(2)];
S = struct();
for i = 1:size(PER, 1)
    lab = PER(i, 1);
    [S.("up_" + lab), S.("dn_" + lab), S.("p_" + lab), S.("beta_" + lab)] = deal(nan(nm, 1));
    for j = 1:nm
        [y, x] = pair(D, j, PER(i, 2), PER(i, 3));
        if numel(y) < 36, continue, end
        [m, p] = updown(y, x);
        a = ols(y, x, 3);
        S.("up_" + lab)(j) = m.b(2); S.("dn_" + lab)(j) = m.b(3);
        S.("p_" + lab)(j) = p; S.("beta_" + lab)(j) = a.b(2);
    end
end
cols = ["up_" "dn_" "p_" "beta_"] + PER(:, 1);           % one row per period
cols = reshape(cols', 1, []);
write_csv(fullfile(out, "betas_subperiods.csv"), ["cc" "name" "region" cols], ...
    [{cc, names, region}, cellfun(@(c) S.(c), cellstr(cols), "UniformOutput", false)]);

%% 3. Out-of-sample test: February-September 2026, betas estimated to December 2025
T = struct();
for j = 1:nm
    [y, x] = pair(D, j, SAMPLE(1), "2025-12");
    m = updown(y, x);
    last = find(k >= ym(TEST_START) & ~isnan(Y(:, j)), 1, "last");   % Sep 2026, or Aug where Sep is missing
    dx = D.dx_avg; if eom(j), dx = D.dx_eom; end
    win = dx(k > ym(TEST_START) & k <= k(last));                     % every US monthly move after the February base
    up = sum(max(win, 0)); dn = sum(min(win, 0));
    pred = m.b(2)*up + m.b(3)*dn;                                    % betas only: no drift carried forward
    v = [up dn];
    se = sqrt(numel(win)*long_run_var(m.e, 3) + v*m.V(2:3, 2:3)*v');
    act = (Y(last, j) - Y(k == ym(TEST_START), j))*100;
    T.end(j, 1) = ymstr(k(last)); T.months(j, 1) = int32(numel(win));
    T.us_change(j, 1) = up + dn; T.actual(j, 1) = act; T.predicted(j, 1) = pred;
    T.surprise(j, 1) = act - pred; T.se(j, 1) = se; T.outside90(j, 1) = abs(act - pred) > 1.645*se;
end
write_csv(fullfile(out, "test_2026.csv"), ["cc" "name" "region" "end" "months" "us_change" "actual" ...
    "predicted" "surprise" "se" "outside90"], {cc, names, region, T.end, T.months, T.us_change, ...
    T.actual, T.predicted, T.surprise, T.se, T.outside90});

%% 4. US 10y, 2y, TIPS yield, breakeven and Kim-Wright decomposition, daily
ids = ["DGS10" "DGS2" "DFII10" "T10YIE" "THREEFYTP10" "THREEFY10" "DCOILBRENTEU"];
for i = 1:numel(ids)
    [td{i}, vd{i}] = fred(root, ids(i)); %#ok<SAGROW>
end
days = unique(vertcat(td{:}));
U = nan(numel(days), numel(ids) + 1);
for i = 1:numel(ids)
    [~, loc] = ismember(td{i}, days);
    U(loc, i) = vd{i};
end
U(:, end) = U(:, ids == "THREEFY10") - U(:, ids == "THREEFYTP10");   % Kim-Wright expected path
keep = days >= datetime(2024, 1, 1);
write_csv(fullfile(out, "us_daily.csv"), ["date" ids "KW_EXP"], ...
    [{string(days(keep), "yyyy-MM-dd")}, num2cell(U(keep, :), 1)]);

%% 5. Real yields vs breakevens, 2003-2026 (markets with monthly-average yields)
[tr, vr] = fred(root, "DFII10"); [tb, vb] = fred(root, "T10YIE");
[kr, real_m] = monthly(tr, vr, "avg"); [kb, be_m] = monthly(tb, vb, "avg");
dreal = ongrid(k, kr, [NaN; diff(real_m)]*100);
dbe = ongrid(k, kb, [NaN; diff(be_m)]*100);
R = struct("j", [], "b_real", [], "se_real", [], "b_be", [], "se_be", []);
for j = find(~eom)'
    in = k >= ym("2003-02") & k <= ym(SAMPLE(2)) & ~isnan(D.dy(:, j)) & ~isnan(dreal) & ~isnan(dbe);
    m = ols(D.dy(in, j), [dreal(in) dbe(in)], 3);
    R.j(end+1, 1) = j; R.b_real(end+1, 1) = m.b(2); R.se_real(end+1, 1) = m.se(2);
    R.b_be(end+1, 1) = m.b(3); R.se_be(end+1, 1) = m.se(3);
end
write_csv(fullfile(out, "betas_real_breakeven.csv"), ["cc" "name" "region" "b_real" "se_real" "b_be" "se_be"], ...
    {cc(R.j), names(R.j), region(R.j), R.b_real, R.se_real, R.b_be, R.se_be});

%% 6. Robustness: 2013-26 excluding 2020-21
B = nan(nm, 3);
for j = 1:nm
    [y, x, kj] = pair(D, j, "2013-01", SAMPLE(2));
    ex = kj >= ym("2020-01") & kj <= ym("2021-12");
    [m, p] = updown(y(~ex), x(~ex));
    B(j, :) = [m.b(2) m.b(3) p];
end
write_csv(fullfile(out, "robustness_2013_26_ex_2020_21.csv"), ["cc" "name" "up_ex2020_21" "dn_ex2020_21" ...
    "p_ex2020_21"], {cc, names, B(:, 1), B(:, 2), B(:, 3)});

%% 7. Cross-section: asymmetry on current-account and budget balances (IMF WEO)
yrs = (1980:2031)';
ca = weo(root, "BCA_NGDPD", iso, yrs); bb = weo(root, "GGXCNL_NGDP", iso, yrs);
avg = @(A, y0, y1) mean(A(yrs >= y0 & yrs <= y1, :), 1, "omitnan")';
X = table(names, S.up_2000_12 - S.dn_2000_12, S.up_2013_26 - S.dn_2013_26, avg(ca, 2000, 2012), ...
    avg(ca, 2013, 2025), avg(bb, 2000, 2012), avg(bb, 2013, 2025), ...
    'VariableNames', ["name" "gap0" "gap1" "ca0" "ca1" "bb0" "bb1"]);
write_csv(fullfile(out, "xsec_fundamentals.csv"), ["" string(X.Properties.VariableNames)], ...
    [{cc}, cellfun(@(v) X.(v), X.Properties.VariableNames, "UniformOutput", false)]);

per = ["0" "ca0" "bb0"; "1" "bb1" "ca1"];
fitgrid = {};
for i = 1:2
    own = per(i, 2); other = per(i, 3); g = "gap" + per(i, 1);
    ok1 = ~isnan(X.(g)) & ~isnan(X.(own));
    ok2 = ok1 & ~isnan(X.(other));
    m1 = ols(X.(g)(ok1), X.(own)(ok1), "hc1");
    m2 = ols(X.(g)(ok2), [X.(own)(ok2) X.(other)(ok2)], "hc1");
    ok3 = ok1 & cc ~= "NO";                                          % Norway: the largest surplus by far
    m3 = ols(X.(g)(ok3), X.(own)(ok3), "hc1");
    [rk, prk] = spearman(X.(own)(ok3), X.(g)(ok3));
    xst(i) = struct("x", own, "slope", m1.b(2), "t", m1.t(2), "r2", m1.r2, "n", int32(m1.n), ...
                    "t_own_joint", m2.t(2), "t_other_joint", m2.t(3), "slope_ex_NO", m3.b(2), ...
                    "t_ex_NO", m3.t(2), "rank_ex_NO", rk, "p_rank_ex_NO", prk); %#ok<SAGROW>
    lo = min(X.(own)) - 0.5; hi = max(X.(own)) + 0.5;
    gx = linspace(lo, hi, 60)';
    G = [ones(60, 1) gx];
    fit = G*m1.b;
    se = sqrt(sum(G .* (m1.V*G')', 2));
    q = norminv(0.95);                                               % 90% band
    fitgrid{i} = {repmat(per(i, 1), 60, 1), gx, fit, fit - q*se, fit + q*se}; %#ok<SAGROW>
end
write_json(fullfile(out, "xsec_stats.json"), xst, ["0" "1"]);
write_csv(fullfile(out, "xsec_fit.csv"), ["period" "x" "fit" "lo" "hi"], ...
    cellfun(@(a, b) [a; b], fitgrid{1}, fitgrid{2}, "UniformOutput", false));

%% 8. Spreads over Bunds: d(spread) = a + b*|dUS| + c*dUS
SP = ["IT" "DE"; "ES" "DE"; "FR" "DE"; "GB" "DE"];
Q = struct("spread", strings(0, 1), "from", strings(0, 1), "up", [], "down", [], "t", []);
for i = 1:size(SP, 1)
    a = cc == SP(i, 1); b = cc == SP(i, 2);
    s = [NaN; diff(Y(:, a) - Y(:, b))]*100;
    for lo = ["2000-01" "2013-01"]
        in = k >= ym(lo) & k <= ym(SAMPLE(2)) & ~isnan(s) & ~isnan(D.dx_avg);
        x = D.dx_avg(in);
        m = ols(s(in), [abs(x) x], 3);
        Q.spread(end+1, 1) = SP(i, 1) + "-" + SP(i, 2); Q.from(end+1, 1) = extractBefore(lo, 5);
        Q.up(end+1, 1) = m.b(2) + m.b(3); Q.down(end+1, 1) = m.b(2) - m.b(3); Q.t(end+1, 1) = m.t(2);
    end
end
write_csv(fullfile(out, "spreads_vs_us_moves.csv"), ["spread" "from" "per_bp_up" "per_bp_down" "t_abs"], ...
    {Q.spread, Q.from, Q.up, Q.down, Q.t});

%% 9. Rule of thumb: +/-50bp on the US 10y, 2013-26 betas
write_csv(fullfile(out, "scenario_50bp.csv"), ["cc" "name" "plus50" "minus50"], ...
    {cc, names, 50*S.up_2013_26, -50*S.dn_2013_26});

%% 10. Scenario: US 10y at 4.6% by end-2027 (GS forecast), 2013-26 betas
% Two paths to the same level: a steady rally, and a 50bp sell-off followed by the rally. Betas only,
% as in section 3; the s.e. adds H months of residual long-run variance to parameter uncertainty.
GS_US_END2027 = 4.60;                                   % GS Global Markets Outlook 2027 (12 Nov 2026)
US_NOW = v10(find(t10 <= datetime(2026, 11, 12) & ~isnan(v10), 1, "last"));   % 5.10% on 12 November 2026
H = 14;                                                 % monthly moves, mid-November 2026 to end-2027
move = (GS_US_END2027 - US_NOW)*100;
ROUTES = ["steady" "detour"];
RU = [0 move; 50 move - 50];                            % sum of US up-moves, sum of down-moves
G = struct();
for j = 1:nm
    [y, x] = pair(D, j, "2013-01", SAMPLE(2));
    m = updown(y, x);
    for i = 1:2
        v = RU(i, :);
        G.(ROUTES(i))(j, 1) = m.b(2)*v(1) + m.b(3)*v(2);
        G.(ROUTES(i) + "_se")(j, 1) = sqrt(H*long_run_var(m.e, 3) + v*m.V(2:3, 2:3)*v');
    end
end
write_csv(fullfile(out, "scenario_gs2027.csv"), ["cc" "name" "region" "steady" "steady_se" "detour" ...
    "detour_se"], {cc, names, region, G.steady, G.steady_se, G.detour, G.detour_se});
assert(max(abs(G.steady - move*S.dn_2013_26)) < 1e-9, "steady path should equal move times the 2013-26 rally beta")

%% 11. The 2013-26 gap holding the VIX fixed
[tv, vv] = fred(root, "VIXCLS");
[kv, vix_avg] = monthly(tv, vv, "avg");
[~, vix_eom] = monthly(tv, vv, "eom");
dv_avg = ongrid(k, kv, [NaN; diff(vix_avg)]);
dv_eom = ongrid(k, kv, [NaN; diff(vix_eom)]);
V = nan(nm, 4);
for j = 1:nm
    [y, x, kj] = pair(D, j, "2013-01", SAMPLE(2));
    dv = dv_avg; if eom(j), dv = dv_eom; end
    dv = dv(ismember(k, kj));
    ok = ~isnan(dv);
    m = ols(y(ok), [max(x(ok), 0) min(x(ok), 0) dv(ok)], 3);
    V(j, :) = [S.up_2013_26(j) - S.dn_2013_26(j), m.b(2) - m.b(3), m.b(4), m.t(4)];
end
write_csv(fullfile(out, "betas_vix_2013_26.csv"), ["cc" "name" "gap" "gap_vix" "b_vix" "t_vix"], ...
    {cc, names, V(:, 1), V(:, 2), V(:, 3), V(:, 4)});

%% Check: Japan with MOF daily yields, monthly averages
[tj, vj] = mof(root);
[kj, jp_avg] = monthly(tj, vj, "avg");
djp = ongrid(k, kj, [NaN; diff(jp_avg)]*100);
in = k >= ym(SAMPLE(1)) & k <= ym(SAMPLE(2)) & ~isnan(djp) & ~isnan(D.dx_avg);
[m_jp, p_jp] = updown(djp(in), D.dx_avg(in));

%% Numbers quoted in the note
fprintf("== Full sample sell-off / rally betas ==\n");
[~, o] = sort(F.gap, "descend");
fprintf("%-4s %-13s %6s %6s %6s %6s %6s %5s\n", "cc", "name", "beta", "up", "dn", "gap", "p_gap", "n");
for j = o'
    fprintf("%-4s %-13s %6.2f %6.2f %6.2f %6.2f %6.2f %5d\n", cc(j), names(j), F.beta(j), F.up(j), ...
        F.dn(j), F.gap(j), F.p_gap(j), F.n(j));
end
fprintf("\n== Sub-periods (sell-off / rally / average beta) ==\n");
bcols = cols(~startsWith(cols, "p_"));
fprintf("%-4s" + join(repmat(" %12s", 1, 9), "") + "\n", "cc", bcols);
for j = 1:nm
    fprintf("%-4s" + join(repmat(" %12.2f", 1, 9), "") + "\n", cc(j), cellfun(@(c) S.(c)(j), cellstr(bcols)));
end
fprintf("\n== 2026 test ==\n");
[~, o] = sort(T.surprise);
for j = o'
    fprintf("%-4s %-13s %s %d  US %6.1f  actual %7.1f  implied %6.1f  surprise %7.1f  se %6.1f  outside %d\n", ...
        cc(j), names(j), T.end(j), T.months(j), T.us_change(j), T.actual(j), T.predicted(j), T.surprise(j), ...
        T.se(j), T.outside90(j));
end
fprintf("\n== Cross-section: gap on fundamentals (HC1) ==\n");
for i = 1:2
    fprintf("%s on %s: slope %.4f, t %.2f, R2 %.2f, n %d; joint t own %.2f, other %.2f\n", "gap" + per(i, 1), ...
        xst(i).x, xst(i).slope, xst(i).t, xst(i).r2, xst(i).n, xst(i).t_own_joint, xst(i).t_other_joint);
end
fprintf("\n== Spreads over Bunds: bp per 1bp US move ==\n");
for i = 1:numel(Q.up)
    fprintf("%s from %s: sell-off %.2f, rally %.2f (t on |dUS| %.2f)\n", Q.spread(i), Q.from(i), Q.up(i), Q.down(i), Q.t(i));
end
fprintf("\n== +/-50bp on the US 10y, 2013-26 betas ==\n");
for j = 1:nm
    fprintf("%-13s %+4.0f %+4.0f\n", names(j), 50*S.up_2013_26(j), -50*S.dn_2013_26(j));
end
fprintf("\n== GS end-2027 call: US 10y %.2f%% -> %.2f%% (%+.0fbp), 2013-26 betas, 90%% ranges ==\n", US_NOW, ...
    GS_US_END2027, move);
[~, o] = sort(G.detour);
for j = o'
    fprintf("%-13s steady %+5.0f (+/-%3.0f)  detour %+5.0f (+/-%3.0f)\n", names(j), G.steady(j), ...
        1.645*G.steady_se(j), G.detour(j), 1.645*G.detour_se(j));
end
fprintf("BTP-Bund: steady %+.0fbp, detour %+.0fbp\n", G.steady(cc == "IT") - G.steady(cc == "DE"), ...
    G.detour(cc == "IT") - G.detour(cc == "DE"));
fprintf("\n== Real vs breakeven betas (2003-26) ==\n");
for i = 1:numel(R.j)
    fprintf("%-13s real %.2f (%.2f)  breakeven %.2f (%.2f)\n", names(R.j(i)), R.b_real(i), R.se_real(i), R.b_be(i), R.se_be(i));
end
fprintf("\n== 2013-26 excluding 2020-21 ==\n");
for j = 1:nm
    fprintf("%-13s up %.2f  dn %.2f  p %.2f\n", names(j), B(j, 1), B(j, 2), B(j, 3));
end
fprintf("\n== 2013-26 gap, and holding the VIX fixed ==\n");
for j = 1:nm
    fprintf("%-13s gap %5.2f  gap|VIX %5.2f  VIX %5.2f (t %5.2f)\n", names(j), V(j, :));
end
brent = U(days >= datetime(2026, 2, 27), ids == "DCOILBRENTEU"); brent = brent(~isnan(brent));
fprintf("\nBrent since 27 Feb 2026: average %.0f, above $100 on %.0f%% of days, max %.0f\n", mean(brent), ...
    100*mean(brent > 100), max(brent));
fprintf("\nJapan check, MOF monthly averages: up %.2f dn %.2f p %.2f\n", m_jp.b(2), m_jp.b(3), p_jp);
u = days >= datetime(2026, 1, 1);
d10 = U(u, 1); du = days(u);
[lo10, ilo] = min(d10(du <= datetime(2026, 3, 15))); [hi10, ihi] = max(d10); n10 = find(~isnan(d10), 1, "last");
fprintf("\nUS 10y low %.2f on %s, high %.2f on %s, last %.2f on %s\n", lo10, string(du(ilo), "yyyy-MM-dd"), ...
    hi10, string(du(ihi), "yyyy-MM-dd"), d10(n10), string(du(n10), "yyyy-MM-dd"));
labs = ["DGS10" "DGS2" "DFII10" "T10YIE" "THREEFYTP10" "KW_EXP"];
for c = labs
    s = U(u, [ids "KW_EXP"] == c); ok = ~isnan(s);
    upto = find(ok & du <= du(ihi), 1, "last"); lst = find(ok, 1, "last");
    fprintf("  %-12s %.2f -> peak-date %.2f -> last %.2f (%s)\n", c, s(ilo), s(upto), s(lst), string(du(lst), "yyyy-MM-dd"));
end


%% ---------------------------------------------------------------------------------------------
% Bunch of recycled stuff from macrometrics 
function [t, v] = fred(root, sid)
% One FRED series: dates and values, missing values as NaN
o = detectImportOptions(fullfile(root, "data", "raw", "fred", sid + ".csv"));
o = setvartype(o, o.VariableNames{1}, "datetime");
o = setvaropts(o, o.VariableNames{1}, "InputFormat", "yyyy-MM-dd");
o = setvartype(o, o.VariableNames{2}, "double");
T = readtable(fullfile(root, "data", "raw", "fred", sid + ".csv"), o);
t = T{:, 1}; v = T{:, 2};
end

function [km, m] = monthly(t, x, how)
% Monthly average ("avg") or last available value ("eom") of a daily series; km = 12*year + month
kd = 12*year(t) + month(t);
km = (kd(1):kd(end))';
ok = ~isnan(x);
if how == "avg"
    m = accumarray(kd(ok) - kd(1) + 1, x(ok), size(km), @mean, NaN);
else
    m = accumarray(kd(ok) - kd(1) + 1, x(ok), size(km), @(v) v(end), NaN);
end
end

function v = ongrid(k, ks, x)
% Put series x, observed on months ks, on the common monthly grid k
v = nan(size(k));
[in, loc] = ismember(ks, k);
v(loc(in)) = x(in);
end

function n = ym(s)
% "yyyy-mm" -> 12*year + month
n = 12*str2double(extractBefore(s, 5)) + str2double(extractAfter(s, 5));
end

function s = ymstr(n)
% 12*year + month -> "yyyy-mm"
s = string(sprintf("%d-%02d", floor((n - 1)/12), mod(n - 1, 12) + 1));
end

function [y, x, k] = pair(D, j, lo, hi)
% Monthly bp changes of market j and of the US 10y on the matching basis, from lo to hi
x = D.dx_avg; if D.eom(j), x = D.dx_eom; end
y = D.dy(:, j);
keep = D.k >= ym(lo) & D.k <= ym(hi) & ~isnan(y) & ~isnan(x);
y = y(keep); x = x(keep); k = D.k(keep);
end

function [m, p] = updown(y, x)
% Sell-off and rally betas (a kink at zero) and the p-value of their difference
m = ols(y, [max(x, 0) min(x, 0)], 3);
c = [0 1 -1];
p = erfc(abs(c*m.b/sqrt(c*m.V*c'))/sqrt(2));
end

function r = ols(y, X, cov)
% OLS of y on a constant and X, with Newey-West (cov = number of lags, Bartlett weights) or HC1
% (cov = "hc1") covariance. Coefficients through the pseudo-inverse.
X = [ones(size(y)) X];
[n, kx] = size(X);
P = pinv(X);
r.b = P*y;
r.e = y - X*r.b;
if isnumeric(cov)
    u = X .* r.e;
    S = u'*u;
    for j = 1:cov
        s = u(j+1:end, :)'*u(1:end-j, :);
        S = S + (1 - j/(cov + 1))*(s + s');
    end
    XXi = P*P';
    r.V = XXi*S*XXi';
else
    r.V = P*((n/(n - kx)*r.e.^2) .* P');
end
r.se = sqrt(diag(r.V));
r.t = r.b ./ r.se;
r.n = n;
yc = y - mean(y);
r.r2 = 1 - (r.e'*r.e)/(yc'*yc);
end

function [r, p] = spearman(x, y)
% Spearman rank correlation, with the p-value from the t approximation
n = numel(x);
r = corr(tiedrank(x), tiedrank(y));
t = r*sqrt((n - 2)/((r + 1)*(1 - r)));
p = 2*tcdf(-abs(t), n - 2);
end

function s = long_run_var(e, lags)
% Newey-West long-run variance of monthly residuals (Bartlett weights)
e = e - mean(e);
n = numel(e);
s = e'*e/n;
for j = 1:lags
    s = s + 2*(1 - j/(lags + 1))*(e(j+1:end)'*e(1:end-j))/n;
end
end

function A = weo(root, ind, iso, yrs)
% IMF WEO annual series (% of GDP), years in rows and markets in columns
v = jsondecode(fileread(fullfile(root, "data", "raw", "imf", ind + ".json"))).values.(ind);
A = nan(numel(yrs), numel(iso));
for j = 1:numel(iso)
    if ~isfield(v, iso(j)), continue, end
    s = v.(iso(j));
    y = str2double(erase(string(fieldnames(s)), "x"));
    x = struct2cell(s);
    e = cellfun(@isempty, x);                                % no value reported
    x = cell2mat(x(~e)); y = y(~e);
    [in, loc] = ismember(y, yrs);
    A(loc(in), j) = x(in);
end
end

function [t, v] = mof(root)
% MOF daily 10y JGB yields: the historical file, then the current month
t = datetime.empty(0, 1); v = [];
for f = ["jgbcme_all.csv" "jgbcme.csv"]
    L = readlines(fullfile(root, "data", "raw", "cb", f), "Encoding", "ISO-8859-1");
    tok = regexp(L, "^(\d{4}/\d{1,2}/\d{1,2}),(?:[^,]*,){9}([^,]*),", "tokens", "once");
    tok = vertcat(tok{:});
    d = datetime(tok(:, 1), "InputFormat", "yyyy/M/d");
    new = ~ismember(d, t);                                   % keep the first file's value for a date
    t = [t; d(new)]; v = [v; str2double(tok(new, 2))]; %#ok<AGROW>
end
[t, o] = sort(t); v = v(o);
end

function write_csv(file, header, cols)
% Write columns to CSV: numbers to 8 significant digits, empty for NaN, True/False for logicals
n = numel(cols{1});
txt = strings(n, numel(cols));
for c = 1:numel(cols)
    x = cols{c};
    if isstring(x) || ischar(x) || iscellstr(x)
        txt(:, c) = string(x);
    elseif islogical(x)
        tf = ["False" "True"];
        txt(:, c) = tf(x + 1)';
    elseif isinteger(x)
        txt(:, c) = compose("%d", x);
    else
        s = compose("%.8g", x);
        s(isnan(x)) = "";
        txt(:, c) = s;
    end
end
lines = [strjoin(header, ","); join(txt, ",", 2)];
fid = fopen(file, "w");
fprintf(fid, "%s\n", lines);
fclose(fid);
end

function write_json(file, st, keys)
% Write the cross-section statistics as JSON, one object per period
f = string(fieldnames(st))';
out = "{";
for i = 1:numel(st)
    out = out + newline + " """ + keys(i) + """: {";
    for j = 1:numel(f)
        x = st(i).(f(j));
        if isstring(x)
            val = """" + x + """";
        elseif isinteger(x)
            val = string(x);
        else
            val = string(sprintf("%.8g", x));
            if ~contains(val, [".", "e", "n"]), val = val + ".0"; end     % a float always has a point
        end
        out = out + newline + "  """ + f(j) + """: " + val + extractBefore(",", 1 + (j < numel(f)));
    end
    out = out + newline + " }" + extractBefore(",", 1 + (i < numel(st)));
end
out = out + newline + "}";
fid = fopen(file, "w");
fprintf(fid, "%s", out);
fclose(fid);
end
