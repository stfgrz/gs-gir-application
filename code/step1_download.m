function step1_download(which, raw)
%STEP1_DOWNLOAD  Download the public data behind the writing sample.
%
%   Sources: FRED (St. Louis Fed), IMF DataMapper, Japan Ministry of Finance.
%   Raw files go to data/raw/<source>/, one file per series, untouched.
%   step1_download                   everything
%   step1_download(["fred" "imf"])   some sources only
%   step1_download(which, raw)       into another folder

if nargin < 1 || isempty(which), which = ["fred" "imf" "mof"]; end
if nargin < 2, raw = fullfile(fileparts(fileparts(mfilename("fullpath"))), "data", "raw"); end

% FRED: US Treasury yields, KW decomposition, VIX, Brent
FRED_DAILY = ["DGS10" "DGS2" ...                       % Treasury constant-maturity yields
              "DFII10" "T10YIE" ...                   % 10y TIPS real yield, breakeven
              "THREEFYTP10" "THREEFY10" ...           % KW 10y term premium, fitted yield
              "VIXCLS" "DCOILBRENTEU"];
% OECD long-term (10y) government bond yields, monthly
OECD_CC = ["CA" "AU" "NZ" "GB" "SE" "NO" "CH" "JP" "DE" "FR" "IT" "ES" "KR" "IL" "MX" "CL" "ZA" ...
           "PL" "HU" "CZ"];
FRED_MONTHLY = ["IRLTLT01" + OECD_CC + "M156N" "INDIRLTLT01STM"];

if ismember("fred", which)
    for sid = [FRED_DAILY FRED_MONTHLY]
        url = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=" + sid;
        fprintf("fred %s\n", fetch(url, fullfile(raw, "fred", sid + ".csv"), 60));
        pause(0.3)
    end
end

% IMF World Economic Outlook (DataMapper API): budget and current-account balances
if ismember("imf", which)
    for ind = ["GGXCNL_NGDP" "BCA_NGDPD"]
        url = "https://www.imf.org/external/datamapper/api/v1/" + ind;
        fprintf("imf  %s\n", fetch(url, fullfile(raw, "imf", ind + ".json"), 60));
    end
end

% Japan Ministry of Finance: daily JGB yields (used to check the OECD Japan series)
if ismember("mof", which)
    base = "https://www.mof.go.jp/english/policy/jgbs/reference/interest_rate";
    fprintf("mof  %s\n", fetch(base + "/historical/jgbcme_all.csv", fullfile(raw, "cb", "jgbcme_all.csv"), 120));
    fprintf("mof  %s\n", fetch(base + "/jgbcme.csv", fullfile(raw, "cb", "jgbcme.csv"), 60));
end
end


function msg = fetch(url, dest, timeout)
% Download url to dest with curl (websave tends to stall on FRED)
[folder, file, ext] = fileparts(dest);
if ~isfolder(folder), mkdir(folder); end
[status, err] = system(sprintf('curl -sSL -m %d --fail -o "%s" "%s"', timeout, dest, url));
if status ~= 0 || ~isfile(dest)
    if isfile(dest), delete(dest); end
    err = strtrim(string(err));
    msg = sprintf("FAIL %s%s: %s", file, ext, extractBefore(err, min(strlength(err), 80) + 1));
    return
end
fid = fopen(dest); head = lower(char(fread(fid, 15)')); fclose(fid);
if startsWith(head, ["<!doctype" "<html"])
    delete(dest);
    msg = sprintf("FAIL (html) %s%s", file, ext);
    return
end
d = dir(dest);
msg = sprintf("ok   %s%s (%.0f kB)", file, ext, d.bytes/1e3);
end
