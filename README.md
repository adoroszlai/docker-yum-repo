# Copy and serve YUM/APT repos

## Example

Repos will be mirrored to `REPO_DIR` on the host.

```bash
REPO_DIR=~/data/repos

# docker build -t copy-yum-repo copy-yum-repo
docker run --rm -v $REPO_DIR:/var/repo copy-yum-repo \
  http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.5.0.0/hdp.repo \
  http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.4.0.1/ambari.repo

# docker build -t apt-mirror apt-mirror
docker run --rm -v $REPO_DIR:/var/spool/apt-mirror/mirror apt-mirror \
  http://public-repo-1.hortonworks.com/HDP/debian7/2.x/updates/2.6.3.0/hdp.list \
  http://public-repo-1.hortonworks.com/ambari/debian7/2.x/updates/2.6.0.0/ambari.list

# docker build -t serve-yum-repo serve-yum-repo
docker run -d --name yum-repo -p 80:80 -h yum-repo -v $REPO_DIR:/var/repo serve-yum-repo
```
