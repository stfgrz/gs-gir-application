%% MAIN  Rebuild the numbers, exhibits and word count of the writing sample from public data
%
% step1_download    FRED, IMF DataMapper, Japan MOF  -> data/raw/
% step2_analysis    all estimates                    -> data/processed/ (and the numbers in the text)
% step3_figures     the three exhibits               -> figures/
% step4_wordcount   words counted against the 800 limit
% The note itself: cd report; latexmk -pdf writing_sample.tex
%
% The raw data in data/raw are the vintage downloaded on 11th November 2026. Downloading again
% picks up later observations and revisions, so it is off by default.

addpath(fileparts(mfilename("fullpath")))
refresh = false;
if refresh
    step1_download
end
step2_analysis            % each step starts from a clean workspace
step3_figures
step4_wordcount
