Find the merge and pull request a commit came from, also finding straight cherry-picks.

Install
=======

```Bash
gem install git-whence
```

or as standalone binary (needs any ruby)

```Bash
curl https://rubinjam.herokuapp.com/pack/git-whence > git-whence && chmod +x git-whence
```

Usage
=====

```Bash
git-whence 6d37485
Merge pull request #10486 from foo/bar

git-whence 6d37485 -o
-> open browser on github pull request page
```

Alternatives
============
 - [git-when-merge](https://github.com/mhagger/git-when-merged)
 - [git-get-merge](https://github.com/jianli/git-get-merge)

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/git-whence.png)](https://travis-ci.org/grosser/git-whence)
