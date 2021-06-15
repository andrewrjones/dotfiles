dir=~/.dotfiles                    # dotfiles directory
olddir=~/.dotfiles.bk              # old dotfiles backup directory
# list of files/folders to symlink in homedir
files="bashrc psqlrc vimrc gitconfig tmux.conf zshrc"

# create dotfiles_old in homedir
echo -n "Creating $olddir for backup of any existing dotfiles in ~ ..."
mkdir -p $olddir
echo "done"

# change to the dotfiles directory
echo -n "Changing to the $dir directory ..."
cd $dir
echo "done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
for file in $files; do
    if [ -f ~/.$file ]; then
        echo "Moving $file from ~ to $olddir"
        mv ~/.$file $olddir
    fi
    echo "Creating symlink to $file in home directory."
    ln -s $dir/$file ~/.$file
done
