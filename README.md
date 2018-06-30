# Copy and serve YUM/APT repos

## Usage

Repos will be mirrored to `REPO_DIR` on the host.
`REPO_HOST` is the hostname that serves local repos.  Add this to `/etc/hosts` with the appropriate IP.

```bash
REPO_DIR=~/data/repos
REPO_HOST=repo
```

### Copy full YUM repo

```
# docker build -t copy-yum-repo copy-yum-repo
docker run --rm -v ${REPO_DIR}:/var/repo copy-yum-repo \
  repo http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.5.0.0/hdp.repo
```

### Download only some packages

```
docker run --rm -v ${REPO_DIR}:/var/repo copy-yum-repo \
  pkg http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.5.0.0/hdp.repo "kafka*" "zookeeper*"
```

### Generate local repo file

```
docker run --rm -v ${REPO_DIR}:/var/repo copy-yum-repo \
  repo-file ${REPO_HOST} http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.6.2.2/ambari.repo
```

### Copy full YUM repo, and generate local repo file in one step

As simple as defining `REPO_HOST` in docker environment.

```
docker run --rm -v ${REPO_DIR}:/var/repo -e REPO_HOST copy-yum-repo \
  repo http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.6.2.2/ambari.repo
```

### Copy APT mirror

```
# docker build -t apt-mirror apt-mirror
docker run --rm -v ${REPO_DIR}:/var/spool/apt-mirror/mirror apt-mirror \
  http://public-repo-1.hortonworks.com/HDP/debian7/2.x/updates/2.6.3.0/hdp.list \
  http://public-repo-1.hortonworks.com/ambari/debian7/2.x/updates/2.6.0.0/ambari.list
```

### Run nginx to serve local repos

```
# docker build -t serve-yum-repo serve-yum-repo
docker run -d --name repo -p 80:80 -h repo -v ${REPO_DIR}:/var/repo serve-yum-repo
```
