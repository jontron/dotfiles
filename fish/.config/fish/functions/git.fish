# better diffs
if command -qs delta
	git config --global core.pager delta
	git config --global interactive.diffFilter 'delta --color-only'
	git config --global delta.syntax-theme Nord
	git config --global delta.line-numbers true
	git config --global delta.decorations true
end


abbr -a gd 'git diff'
abbr -a gs 'git status -sb'
