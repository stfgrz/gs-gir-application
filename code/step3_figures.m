%% STEP3_FIGURES  The three exhibits of the writing sample, from data/processed to figures/.
%
% Colours mean the same in every exhibit: red = sell-offs imported more than rallies, or a 2026 rise
% above what Treasuries explain; blue = the opposite; grey = no significant difference, the part
% imported from Treasuries, bands and references; black = actual values.
% Figures are drawn at \textwidth with MATLAB's LaTeX interpreter, so the report includes them at
% 100%. Axes positions are in inches.
% Run: run code/step3_figures.m   (after code/step2_analysis.m)

clear
root = fileparts(fileparts(mfilename("fullpath")));
proc = fullfile(root, "data", "processed");
figdir = fullfile(root, "figures");
if ~isfolder(figdir), mkdir(figdir); end

% colours and sizes
% ColorBrewer RdBu: dark for points and lines, mid for bars, pale for shaded areas
C.red = "#b2182b"; C.red_mid = "#d6604d"; C.red_wash = "#fbeae6";
C.blue = "#2166ac"; C.blue_mid = "#4393c3";
C.ink = "#1a1a1a"; C.frame = "#333333"; C.ref = "#4d4d4d"; C.mute = "#6b6b6b";
C.grey_bar = "#cdcdcd"; C.grey_pt = "#9b9b9b"; C.grid = "#e6e6e6"; C.band = "#e0e0e0";
W = 6.2677;                                 % \textwidth: A4 with 1in margins
MS = 4.6;                                   % marker size, points
BAR = dictionary(["oneway" "haven" "none"], [C.red_mid C.blue_mid C.grey_bar]);
PT = dictionary(["oneway" "haven" "none"], [C.red C.blue C.grey_pt]);
NAMES = dictionary(["CA" "AU" "NZ" "GB" "SE" "NO" "CH" "JP" "DE" "FR" "IT" "ES" "PL" "HU" "CZ" "ZA" "MX" ...
    "KR" "IL" "CL" "IN"], ["Canada" "Australia" "New Zealand" "UK" "Sweden" "Norway" "Switzerland" ...
    "Japan" "Germany" "France" "Italy" "Spain" "Poland" "Hungary" "Czechia" "South Africa" "Mexico" ...
    "Korea" "Israel" "Chile" "India"]);
MARKETS = ["CA" "AU" "NZ" "GB" "SE" "NO" "CH" "JP" "DE" "FR" "IT" "ES" "PL" "HU" "CZ" "ZA" "MX" "KR"];  % Exhibits 1 and 3

sub = readtable(fullfile(proc, "betas_subperiods.csv"), "TextType", "string", "ReadRowNames", true);
for per = ["2000_12" "2013_26"]
    sub.("v_" + per) = verdict(sub.("up_" + per) - sub.("dn_" + per), sub.("p_" + per));
end

%% Exhibit 1: sell-off and rally betas, 2000-12 and 2013-26
% One row per market; the bar joins the rally beta and the sell-off beta and is coloured by the
% Wald test of their difference.
d = sub(MARKETS, :);
[~, o] = sort(d.up_2013_26 - d.dn_2013_26);             % widest 2013-26 gap at the top
order = MARKETS(o);
n = numel(order);
row = dictionary(order, 0:n-1);

fig = newfig(W, 3.3);
pos = [0.7408 0.4245 2.7065 2.3990; 3.5412 0.4245 2.7065 2.3990];
per = ["2000_12" "2013_26"]; titles = ["2000--2012" "2013--2026"]; letters = ["a" "b"];
for p = 1:2
    ax(p) = newaxes(fig, pos(p, :), [-0.8 1.7], [-0.7 n + 0.35], C); %#ok<SAGROW>
    gridlines(ax(p), [-0.5 0 0.5 1 1.5], [], C);
    plot(ax(p), [0 0], [-0.7 n + 0.35], Color=C.grey_bar, LineWidth=0.6);
    plot(ax(p), [1 1], [-0.7 n + 0.35], ":", Color=C.ref, LineWidth=0.7);
    for cc = order
        i = row(cc); up = d{cc, "up_" + per(p)}; dn = d{cc, "dn_" + per(p)};
        plot(ax(p), [dn up], [i i], Color=BAR(d{cc, "v_" + per(p)}), LineWidth=4.2);
        plot(ax(p), dn, i, "v", MarkerSize=MS, MarkerFaceColor=C.ink, MarkerEdgeColor=C.ink);
        plot(ax(p), up, i, "^", MarkerSize=MS, MarkerFaceColor=C.ink, MarkerEdgeColor=C.ink);
    end
    xticks(ax(p), [-0.5 0 0.5 1 1.5]);
    xticklabels(ax(p), ["$-$0.5" "0" "0.5" "1.0" "1.5"]);
    yticks(ax(p), []);
    text(ax(p), 1.04, n - 0.05, "one-for-one", FontSize=7.5, Color=C.ref);
    paneltitle(ax(p), letters(p), titles(p));
end
ylabels(ax(1), 0:n-1, mname(order, ["GB" "FR"], NAMES));
% annotations
text(ax(1), 0.55, row("CH"), "safe haven", FontSize=7.5, Color=C.blue);
y0 = row("FR"); y1 = row("GB");
plot(ax(2), [0.30 0.27 0.27 0.30], [y0 y0 y1 y1], Color=C.red, LineWidth=0.7);
text(ax(2), 0.23, (y0 + y1)/2, "new since 2013", FontSize=7.5, Color=C.red, HorizontalAlignment="right");
ov = overlay(fig, W, 3.3);
text(ov, W/2 + 0.06, 0.10, "beta to the US 10-year yield (bp per bp)", FontSize=8.5, Color=C.ink, ...
    HorizontalAlignment="center");
toplegend(ov, W/2 + 0.04, 3.15, {"up", C.ink, "sell-off beta"; "down", C.ink, "rally beta"; ...
    "bar", C.red_mid, "imports sell-offs more"; "bar", C.blue_mid, "imports rallies more"; ...
    "bar", C.grey_bar, "no significant difference"}, MS, 0.17);
savefig_pdf(fig, fullfile(figdir, "ex1_selloff_rally_betas.pdf"));

%% Exhibit 2: asymmetry against the current-account balance (2000-12) and the budget balance (2013-26)
xs = readtable(fullfile(proc, "xsec_fundamentals.csv"), "TextType", "string", "ReadRowNames", true, ...
    "VariableNamingRule", "preserve");
fit = readtable(fullfile(proc, "xsec_fit.csv"));
st = jsondecode(fileread(fullfile(proc, "xsec_stats.json")));
% market -> (x, y, alignment) of its label, in data units; a hairline joins far labels
LABELS = {
    {"ZA" -1.75 0.68 "left"; "CZ" -2.9 0.50 "left"; "PL" -4.45 0.535 "center"; "HU" -5.6 0.445 "right";
     "ES" -5.5 0.30 "right"; "IT" -0.8 0.38 "left"; "AU" -5.1 0.02 "right"; "NZ" -4.55 -0.11 "right";
     "GB" -2.44 -0.135 "center"; "FR" -0.45 0.135 "right"; "JP" 2.92 0.165 "center"; "DE" 4.35 -0.055 "left";
     "SE" 5.95 -0.215 "center"; "CH" 9.13 -0.335 "center"; "NO" 13.59 0.205 "center"}
    {"ZA" -4.45 1.63 "left"; "HU" -3.55 1.18 "left"; "IT" -4.85 0.93 "right"; "PL" -3.0 0.82 "left";
     "ES" -5.3 0.71 "right"; "GB" -5.75 0.54 "right"; "FR" -4.2 0.565 "left"; "CZ" -1.25 0.42 "left";
     "AU" -5.95 0.40 "right"; "NZ" -1.25 0.12 "left"; "JP" -4.6 -0.07 "right"; "IN" -8.02 0.27 "center";
     "NO" 9.12 -0.05 "center"; "CH" 0.6 -0.12 "left"; "CA" -1.46 -0.21 "center"}};
spec = struct("per", {"0" "1"}, "x", {"ca0" "bb1"}, "y", {"gap0" "gap1"}, "v", {"v_2000_12" "v_2013_26"}, ...
    "title", {"2000--2012: current accounts" "2013--2026: budgets"}, "what", {"current-account" "budget"}, ...
    "years", {"2000--12" "2013--25"}, "xl", {[-9.6 15.6] [-10.2 10.6]}, "yl", {[-0.42 0.86] [-0.42 1.9]}, ...
    "xt", {-5:5:15 -10:5:10}, "yt", {-0.4:0.2:0.8 0:0.5:1.5});

fig = newfig(W, 3.15);
pos = [0.5136 0.3829 2.6608 2.2907; 3.5653 0.3829 2.6608 2.2907];
for p = 1:2
    s = spec(p); xl = s.xl; yl = s.yl;
    ax(p) = newaxes(fig, pos(p, :), xl, yl, C);
    fill(ax(p), [xl(1) 0 0 xl(1)], [yl(1) yl(1) yl(2) yl(2)], hex2rgb(C.red_wash), EdgeColor="none");
    gridlines(ax(p), s.xt, s.yt, C);
    plot(ax(p), [0 0], yl, "--", Color=C.ref, LineWidth=0.7);
    plot(ax(p), xl, [0 0], Color=C.grey_bar, LineWidth=0.6);
    ytop = yl(2) - 0.06*(yl(2) - yl(1));
    text(ax(p), -0.35, ytop, "$\leftarrow$ deficit", FontSize=7.5, Color=C.red, HorizontalAlignment="right");
    text(ax(p), 0.35, ytop, "surplus $\rightarrow$", FontSize=7.5, Color=C.mute);
    f = fit(fit.period == str2double(s.per), :);
    plot(ax(p), f.x, f.fit, Color=C.ref, LineWidth=0.9);
    pts = [MARKETS "IN" "IL" "CL"];
    pts = pts(~isnan(xs{pts, s.x}) & ~isnan(xs{pts, s.y}));
    v = sub{pts, s.v};
    v(isnan(sub{pts, "p_" + extractAfter(s.v, 2)})) = "none";
    for grp = ["none" "oneway" "haven"]                        % grey points underneath
        k = v == grp;
        plot(ax(p), xs{pts(k), s.x}, xs{pts(k), s.y}, "o", LineStyle="none", MarkerSize=MS - 0.8*(grp == "none"), ...
            MarkerFaceColor=PT(grp), MarkerEdgeColor=PT(grp));
    end
    L = LABELS{p};
    for r = 1:size(L, 1)
        cc = L{r, 1}; px = xs{cc, s.x}; py = xs{cc, s.y};
        h = text(ax(p), L{r, 2}, L{r, 3}, mname(cc, ["GB" "FR"], NAMES), FontSize=7.5, HorizontalAlignment=L{r, 4}, ...
            Color=ifelse(sub{cc, s.v} ~= "none", C.ink, C.mute));
        if abs(L{r, 2} - px) > 0.8 || abs(L{r, 3} - py) > 0.09
            leader(ax(p), h, px, py, C.grey_bar);
        end
    end
    text(ax(p), 0.97, 0.66, ["each point of", s.what + " deficit:", sprintf("$+$%.2f asymmetry", -st.("x" + s.per).slope)], ...
        Units="normalized", FontSize=7.5, Color=C.ink, HorizontalAlignment="right", VerticalAlignment="top");
    xticks(ax(p), s.xt); yticks(ax(p), s.yt);
    xticklabels(ax(p), ticklabels(s.xt, "%g")); yticklabels(ax(p), ticklabels(s.yt, "%.1f"));
    xlabel(ax(p), sprintf("%s balance, \\%% of GDP (%s average)", s.what, s.years), FontSize=8.5);
    paneltitle(ax(p), letters(p), s.title);
end
ylabel(ax(1), "asymmetry: sell-off minus rally beta", FontSize=8.5);
ov = overlay(fig, W, 3.15);
toplegend(ov, W/2 + 0.04, 3.0, {"dot", C.red, "imports sell-offs more"; "dot", C.blue, "imports rallies more"; ...
    "dotsmall", C.grey_pt, "no significant difference"; "line", C.ref, "fitted line"}, MS, 0.17);
savefig_pdf(fig, fullfile(figdir, "ex2_fault_line.pdf"));

%% Exhibit 3: (a) US 10y yield, real yield and breakeven; (b) each market's 2026 rise against its betas
us = readtable(fullfile(proc, "us_daily.csv"));
us = us(us.date >= datetime(2025, 1, 1), :);
t = readtable(fullfile(proc, "test_2026.csv"), "TextType", "string", "ReadRowNames", true, ...
    "VariableNamingRule", "preserve");                    % keeps the column called "end"
t = t(MARKETS, :);
t.half = 1.645*t.se;
[~, o] = sort(t.actual); t = t(o, :);                    % largest rise at the top

fig = newfig(W, 4.55);
start = datetime(2026, 2, 27);
last = us.date(end);
t0 = datetime(2025, 1, 1);
dx = @(d) days(d - t0);                                    % dates as days since 1 Jan 2025
a1 = newaxes(fig, [0.7624 3.1864 5.4636 1.1588], dx([us.date(1) last + days(285)]), [1.4 5.8], C);
fill(a1, dx([start last + days(6) last + days(6) start]), [1.4 1.4 5.8 5.8], hex2rgb(C.band), FaceAlpha=0.6, ...
    EdgeColor="none");
gridlines(a1, [], 2:5, C);
series = ["DGS10" C.ink "nominal"; "DFII10" C.red "real (TIPS)"; "T10YIE" C.grey_pt "breakeven"];
for r = 1:3
    ok = ~isnan(us.(series(r, 1)));
    sd = us.date(ok); sv = us.(series(r, 1))(ok);
    plot(a1, dx(sd), sv, Color=series(r, 2), LineWidth=1.15);
    chg = (sv(end) - sv(sd == start))*100;
    text(a1, dx(sd(end) + days(10)), sv(end), sprintf("%s %.2f\\%%, %s bp", series(r, 3), sv(end), ...
        replace(replace(sprintf("%+.0f", chg), "-", "$-$"), "+", "$+$")), FontSize=7.5, Color=C.ink);
end
text(a1, dx(start + days(7)), 5.62, "since 27 February", FontSize=7.5, Color=C.mute);
yticks(a1, 2:5);
xticks(a1, dx(t0 + calmonths(0:6:18)));
xticklabels(a1, string(t0 + calmonths(0:6:18), "MMM yyyy"));
ylabel(a1, "\%", FontSize=8.5);
paneltitle(a1, "a", "the US 10-year yield and its parts");

% (b) grey bar: the rise implied by pre-2026 betas; thin bar: the rest, up to the actual rise (red if
% above, blue if below); a triangle instead of a tick where the rise is outside the 90% range
STORY = dictionary(["JP" "FR" "HU"], ["BoJ to 1.25\%; fiscal plans" "budget crisis; just inside its range" ...
    "April election: convergence rally"]);
nt = height(t);
a2 = newaxes(fig, [0.7624 0.3829 5.4636 2.3755], [-130 290], [-0.7 nt - 0.3], C);
gridlines(a2, -100:50:250, [], C);
plot(a2, [0 0], [-0.7 nt - 0.3], Color=C.grey_bar, LineWidth=0.6);
cc = string(t.Properties.RowNames)';
for i = 0:nt-1
    r = t(i + 1, :);
    rest = r.actual - r.predicted;
    out = abs(rest) > r.half;
    hbar(a2, i, 0, r.predicted, 0.62, C.grey_bar);
    hbar(a2, i, r.predicted, r.actual, 0.3, ifelse(rest > 0, C.red_mid, C.blue_mid));
    if out
        plot(a2, r.actual, i, ifelse(rest > 0, "^", "v"), MarkerSize=MS + 1.6, ...
            MarkerFaceColor=ifelse(rest > 0, C.red, C.blue), MarkerEdgeColor=ifelse(rest > 0, C.red, C.blue));
    else
        plot(a2, [r.actual r.actual], [i - 0.38 i + 0.38], Color=C.ink, LineWidth=1.3);
    end
    if isKey(STORY, cc(i + 1))
        text(a2, max(r.actual, r.predicted) + ifelse(out, 9, 6), i, STORY(cc(i + 1)), FontSize=7.5, ...
            Color=ifelse(out, C.red, C.ink));
    end
end
yticks(a2, []);
ylabels(a2, 0:nt-1, mname(cc, "JP", NAMES));
xticks(a2, -100:50:250);
xticklabels(a2, ticklabels(-100:50:250, "%d"));
xlabel(a2, "rise in the 10-year yield, February to September 2026 (bp)", FontSize=8.5);
paneltitle(a2, "b", "each market's rise: imported from Treasuries, and the rest");
ov = overlay(fig, W, 4.55);
boxlegend(ov, [4.076 1.264 2.087 0.612], {"patch", C.grey_bar, "imported: what Treasuries explain"; ...
    "split", [C.red_mid C.blue_mid], "the rest: not explained by Treasuries"; ...
    "tick", C.ink, "actual rise, within its usual range"; "up", C.red, "actual rise, beyond it"}, MS + 1.6);
savefig_pdf(fig, fullfile(figdir, "ex3_test_2026.pdf"));
fprintf("figures written to %s\n", figdir);


%% ---------------------------------------------------------------------------------------------
function v = verdict(gap, p)
% "oneway" if sell-offs are imported significantly more (p < 0.10), "haven" if rallies are
v = repmat("none", size(gap));
v(p < 0.10 & gap > 0) = "oneway";
v(p < 0.10 & gap < 0) = "haven";
end

function s = mname(cc, bold, NAMES)
% Market names, some in bold
s = NAMES(cc);
b = ismember(cc, bold);
s(b) = "\textbf{" + s(b) + "}";
end

function out = ifelse(c, a, b)
if c, out = a; else, out = b; end
end

function fig = newfig(w, h)
fig = figure(Units="inches", Position=[0 0 w h], Color="w", Visible="off");
set(fig, "defaultTextInterpreter", "latex", "defaultTextFontSize", 8);
end

function ax = newaxes(fig, pos, xl, yl, C)
% Axes in inches with 2.5pt outward ticks; top and right edges are added in savefig_pdf
ax = axes(fig, Units="inches", Position=pos, Box="off", LineWidth=0.6, XColor=C.frame, YColor=C.frame, ...
    TickDir="out", TickLength=[2.5/72/max(pos(3:4)) 0], FontSize=8, TickLabelInterpreter="latex", ...
    XLim=xl, YLim=yl, NextPlot="add", Layer="top");
ax.Title.Interpreter = "latex"; ax.XLabel.Interpreter = "latex"; ax.YLabel.Interpreter = "latex";
ax.XLabel.Color = C.ink; ax.YLabel.Color = C.ink;
ax.XAxis.TickLabelColor = C.ink; ax.YAxis.TickLabelColor = C.ink;
end

function gridlines(ax, xs, ys, C)
% Grid drawn as lines, so it sits above shaded areas and below the data
for x = xs, plot(ax, [x x], ax.YLim, Color=C.grid, LineWidth=0.45); end
for y = ys, plot(ax, ax.XLim, [y y], Color=C.grid, LineWidth=0.45); end
end

function paneltitle(ax, letter, txt)
title(ax, "\textbf{(" + letter + ")} " + txt, FontSize=9, FontWeight="normal", Color="#1a1a1a");
end

function ylabels(ax, ys, labels)
% Category names to the left of the axes, without tick marks
yl = ax.YLim;
for i = 1:numel(ys)
    text(ax, -0.012, (ys(i) - yl(1))/diff(yl), labels(i), Units="normalized", FontSize=8, ...
        HorizontalAlignment="right", Color="#1a1a1a");
end
end

function s = ticklabels(v, fmt)
s = replace(compose(fmt, v), "-", "$-$");
end

function hbar(ax, y, x0, x1, h, c)
fill(ax, [x0 x1 x1 x0], y + [-h -h h h]/2, hex2rgb(c), EdgeColor="none");
end

function leader(ax, h, px, py, c)
% A hairline from a label's box to its point, stopping 1.5pt short of the box and 2.5pt short of the point
drawnow
e = h.Extent;                                                % data units
sx = ax.Position(3)/diff(ax.XLim); sy = ax.Position(4)/diff(ax.YLim);   % inches per data unit
cx = e(1) + e(3)/2; cy = e(2) + e(4)/2;
dx = (px - cx)*sx; dy = (py - cy)*sy; len = hypot(dx, dy);
s0 = min(e(3)*sx/2/abs(dx), e(4)*sy/2/abs(dy))*len + 1.5/72;  % where the line leaves the box
s1 = len - 2.5/72;
if s1 > s0
    plot(ax, cx + [s0 s1]/len*dx/sx, cy + [s0 s1]/len*dy/sy, Color=c, LineWidth=0.5);
end
end

function ov = overlay(fig, w, h)
% Invisible axes over the whole figure, in inches, for figure-level text and legends
ov = axes(fig, Units="inches", Position=[0 0 w h], XLim=[0 w], YLim=[0 h], Visible="off", NextPlot="add", ...
    Clipping="off");
end

function icon(ov, kind, c, x, y, len, ms)
% One legend handle, len inches wide, centred vertically on y
switch kind
    case "up",   plot(ov, x + len/2, y, "^", MarkerSize=ms, MarkerFaceColor=c, MarkerEdgeColor=c);
    case "down", plot(ov, x + len/2, y, "v", MarkerSize=ms, MarkerFaceColor=c, MarkerEdgeColor=c);
    case "dot",  plot(ov, x + len/2, y, "o", MarkerSize=ms, MarkerFaceColor=c, MarkerEdgeColor=c);
    case "dotsmall", plot(ov, x + len/2, y, "o", MarkerSize=ms - 0.8, MarkerFaceColor=c, MarkerEdgeColor=c);
    case "bar",  plot(ov, [x x + len], [y y], Color=c, LineWidth=4.2);
    case "line", plot(ov, [x x + len], [y y], Color=c, LineWidth=0.9);
    case "patch", fill(ov, x + [0 len len 0], y + [-1 -1 1 1]*0.035, hex2rgb(c), EdgeColor="none");
    case "split"
        fill(ov, x + [0 len len 0]/2, y + [-1 -1 1 1]*0.035, hex2rgb(c(1)), EdgeColor="none");
        fill(ov, x + len/2 + [0 len len 0]/2, y + [-1 -1 1 1]*0.035, hex2rgb(c(2)), EdgeColor="none");
    case "tick", plot(ov, x + len/2 + [0 0], y + [-1 1]*0.052, Color=c, LineWidth=1.3);
end
end

function toplegend(ov, xc, y, items, ms, len)
% A one-row legend centred on xc (inches): handle, label, handle, label...
gap = 0.07; sep = 0.21;
h = gobjects(size(items, 1), 1); w = zeros(size(h));
for r = 1:size(items, 1)
    h(r) = text(ov, 0, y, items{r, 3}, FontSize=8, Color="#1a1a1a", VerticalAlignment="middle");
end
drawnow
for r = 1:numel(h), w(r) = h(r).Extent(3); end
x = xc - (sum(w) + numel(w)*(len + gap) + (numel(w) - 1)*sep)/2;
for r = 1:numel(h)
    icon(ov, items{r, 1}, items{r, 2}, x, y, len, ms);
    h(r).Position(1) = x + len + gap;
    x = x + len + gap + w(r) + sep;
end
end

function boxlegend(ov, box, items, ms)
% A one-column legend filling box = [left bottom width height] (inches), first item at the top
len = 0.17; gap = 0.07; pad = 0.06;
n = size(items, 1);
for r = 1:n
    y = box(2) + box(4) - pad - (r - 0.5)*(box(4) - 2*pad)/n;
    icon(ov, items{r, 1}, items{r, 2}, box(1) + pad, y, len, ms);
    text(ov, box(1) + pad + len + gap, y, items{r, 3}, FontSize=7.5, Color="#1a1a1a", VerticalAlignment="middle");
end
end

function savefig_pdf(fig, file)
% Draw the top and right edges by hand (Box="on" would mirror the ticks), then export as vectors at
% the exact figure size
for ax = findobj(fig, "Type", "axes", "Visible", "on")'
    plot(ax, ax.XLim([1 2 2]), ax.YLim([2 2 1]), Color=ax.XColor, LineWidth=ax.LineWidth, Clipping="off");
end
exportgraphics(fig, file, ContentType="vector", Padding="figure");
close(fig)
end
