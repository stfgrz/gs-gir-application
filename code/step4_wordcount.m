%% STEP4_WORDCOUNT  Words that count against the 800-word limit: title, key points and body text.
%
% Exhibits (titles, subtitles, notes, sources) are excluded, as charts sit outside the limit.
% Run: run code/step4_wordcount.m

root = fileparts(fileparts(mfilename("fullpath")));
tex = string(fileread(fullfile(root, "report", "writing_sample.tex"), "Encoding", "UTF-8"));
body = extractBefore(extractAfter(tex, "\begin{document}"), "\end{document}");
body = regexprep(body, '(?<!\\)%.*', " ", "dotexceptnewline");              % comments, not \%
body = regexprep(body, '\\begin\{figure\}.*?\\end\{figure\}', " ");         % exhibits
title = regexp(body, '\\title\{\\textsc\{(.*?)\}\}', "tokens", "once", "dotexceptnewline");
main = extractAfter(body, "\begin{keypoints}");
keypoints = extractBefore(main, "\end{keypoints}");
rest = extractAfter(main, "\end{keypoints}");
heads = regexp(rest, '\\section\*\{(.*?)\}', "tokens", "dotexceptnewline");
heads = join([heads{:}], " ");

n_title = numel(words(title)); n_kp = numel(words(keypoints)); n_body = numel(words(rest));
fprintf("title %d + key points %d + body %d (incl. %d in headings) = %d words\n", ...
    n_title, n_kp, n_body, numel(words(heads)), n_title + n_kp + n_body);


function w = words(s)
% Words of a piece of LaTeX: commands, references and braces out; a word has a letter or digit
s = regexprep(s, '\\begin\{itemize\}\[.*?\]\n', " ");
s = regexprep(s, '\\(ref|label)\{[^}]*\}', " ");
s = regexprep(s, '\\[a-zA-Z]+\*?', " ");
s = replace(s, ["~" "---" "{" "}"], " ");
s = erase(s, "\");
w = regexp(s, '\S+', "match");
w = w(~cellfun(@isempty, regexp(w, '[A-Za-z0-9]', "once")));
end
