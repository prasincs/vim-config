About
====

I got tired of replicating the same vim settings for all the computers I use. Hence this project. If you want to use it for your own projects, you're welcome to do so.
This project has been used in various versions of Linux, BSD and OS X (on MacVim)

Usage
====

After cloning the repository at a location, say, `$HOME/vim-config`, you want to make symbolic links of vim to `$HOME/.vim` and vimrc to `$HOME/.vimrc`
and then run  `git submodule update --init --recursive`

Or, you can just clone using `git clone git@github.com:prasincs/vim-config --recursive`
You'd want to symlink `$CONFIG_DIR/vimrc` to `$HOME/.vimrc` and `$CONFIG_DIR/gvimrc` to `$HOME/.gvimrc`. Additionally, I use `$HOME/.vimrc_local` to store things specific to my machines, or when I'm debugging scripts.

Features
===

They're all included using Pathogen from the vim/bundles directory. 

Major ones

* Syntastic
* Powerline -- I know I should use the Python version but it's way too much yak shaving
* Fireplace (for Clojure)
* Surround -- I rarely use it but it's handy to have around
* NERDCommenter
* Tagbar
* Ctrl-P
* Go support
* Javascript support with Tagbar using DoctorJS

Basically.. the dependences for getting the whole thing to work are

Vim - compiled with python support. You'd want this for the Python support and eventually the updated python version of Powerline

Node.js -- with npm -g doctorjs


I'll be adding a more serious features list that'd be updated as I add/remove things, tweak features but currently there are too few users to bother really. Although it could help me remember what I'm doing better.
