# Preparation 2: Configure your Version Control System (VCS) client

👉 open a terminal

<details>
<summary>Terminal</summary>

- press `Control`+`Shift`+<code>`</code>

or
- navigate to `Menu` > `Terminal` > `New Terminal`

#### References 🔗

- [Keyboard shortcuts for **Linux**](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-linux.pdf)
- [Keyboard shortcuts for **Mac**](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-macos.pdf)
- [Keyboard shortcuts for **Windows**](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-windows.pdf)
</details><br/>

👉 set your name and email

<details>
<summary>Git</summary>

```sh
git config --global user.email alex@example.com
git config --global user.name Alex
```
</details><br/>

(👉) validate the config

<details>
<summary>git</summary>

You can inspect the global git config in your home directory.

```sh
cat ~/.gitconfig
```
</details>

### Customize

<details>
<summary>git config</summary>

You may find some of the following configs useful:
```
[alias]
        a = add
        br = branch
        c = commit
        ca = commit --amend
        cm = commit -m
        co = checkout
        d = diff
        gl = config --global -l
        l = log
        last = log -1 HEAD
        p = push
        s = status -sb
        se = !git rev-list --all | xargs git grep -F
        st = status -sb
        sw = switch
        unstage = reset HEAD --
[init]
        defaultBranch = main
```
</details>

<details>
<summary>shell</summary>

```sh
alias g=git
```
 💡 Tip: add this to your shell profile/aliases.

</details>

## References 🔗

- [git-config](https://git-scm.com/docs/git-config)
- [First-Time Git Setup](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup)
- [Cloud Workstations](https://cloud.google.com/workstations/docs/version-control#commit_changes)
</details><br/>
