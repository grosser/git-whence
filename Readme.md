Find the merge and pull request a commit came from, also finding straight cherry-picks.

Install
=======

```Bash
gem install git-whence
```

or as standalone binary (needs any ruby)

```Bash
curl -sL https://github.com/grosser/git-whence/releases/download/v0.3.0/git-autobisect > /usr/local/bin/git-whence && \
chmod +x /usr/local/bin/git-whence && \
git-whence --version
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
