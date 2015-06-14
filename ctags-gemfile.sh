#! /bin/zsh
rm tags
ctags -R `bundle show --paths` > tags
