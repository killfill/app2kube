# App2Kube

Generate kube manifests (deployment, service, ingress) from small `deploy.yaml` files.

# Installation

```bash
git clone https://github.com/killfill/app2kube.git
sudo ln -s $(pwd)/app2kube/run.sh /usr/local/bin/deploy
```

# Usage

Define an deploy.yaml file, like this:

```yaml
name: an-app
image: nginx
ingress:
    hostname: app.example.com
```

Then, just run:

```bash
deploy -h
deploy apply
```