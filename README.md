AWS::Zocalo
===========

NOTE: The API has not been formally released. Though likely to be
pretty stable, YMMV. Please raise an issue if you notice anything
weird.

A Perl client to the AWS Zocalo API

It will be available on CPAN soon, but you can install after cloning 
from github and using cpanminus. I will also add an Beta release to 
github releases.

Grab cpanm + local::lib
```bash
$ sudo apt-get install cpanminus liblocal-lib-perl
```

Configure local::lib if you haven't already done so:

```bash
$ perl -Mlocal::lib >> ~/.bashrc
$ eval $(perl -Mlocal::lib)
```

Install from git, you can then use:

```bash
$ dzil authordeps | cpanm
$ dzil listdeps   | cpanm
$ dzil install
```

or cpanm (once it's uploaded there):

```bash
cpanm AWS::Zocalo
```
