# Copy and serve YUM repos

## Example

Repos will be mirrored to `REPO_DIR` on the host.

```bash
REPO_DIR=~/data/repos

docker run --rm -v $REPO_DIR:/var/repo copy-yum-repo \
  http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.5.0.0/hdp.repo \
  http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.4.0.1/ambari.repo

docker run -d --name yum-repo -p 80:80 -h yum-repo -v $REPO_DIR:/var/repo serve-yum-repo
```
