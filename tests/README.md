# Securebox ad hoc backups for web applications - Tests

> TODO: document better (fititnt, 2020-11-23 16:42 UTC)


### Bats
- See <https://github.com/sstephenson/bats>
- See <https://github.com/jetmartin/bats>

```bash
fititnt@bravo:/tmp$ git clone https://github.com/sstephenson/bats.git
Cloning into 'bats'...
remote: Enumerating objects: 576, done.
remote: Total 576 (delta 0), reused 0 (delta 0), pack-reused 576
Receiving objects: 100% (576/576), 116.32 KiB | 357.00 KiB/s, done.
Resolving deltas: 100% (274/274), done.
fititnt@bravo:/tmp$ cd bats
fititnt@bravo:/tmp/bats$ sudo ./install.sh /usr/local
[sudo] senha para fititnt: 
Installed Bats to /usr/local/bin/bats
fititnt@bravo:/tmp/bats$ bats
Bats 0.4.0
Usage: bats [-c] [-p | -t] <test> [<test> ...]

# Hummm... seems to exist a new version

fititnt@bravo:/tmp$ git clone https://github.com/bats-core/bats-core.git
Cloning into 'bats-core'...
remote: Enumerating objects: 54, done.
remote: Counting objects: 100% (54/54), done.
remote: Compressing objects: 100% (35/35), done.
remote: Total 3252 (delta 23), reused 30 (delta 11), pack-reused 3198
Receiving objects: 100% (3252/3252), 936.54 KiB | 1.28 MiB/s, done.
Resolving deltas: 100% (1818/1818), done.
fititnt@bravo:/tmp$ cd bats-core
fititnt@bravo:/tmp/bats-core$ git branch
* master
fititnt@bravo:/tmp/bats-core$ sudo ./install.sh /usr/local
Installed Bats to /usr/local/bin/bats
fititnt@bravo:/tmp/bats-core$ bats --version
Bats 1.2.1

```