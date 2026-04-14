# Apache Jena and Fuseki Images

[![Jena CI](https://github.com/manuel-j-diaz/fuseki-ops/actions/workflows/jena.yaml/badge.svg)](https://github.com/manuel-j-diaz/fuseki-ops/actions/workflows/jena.yaml)
[![Fuseki CI](https://github.com/manuel-j-diaz/fuseki-ops/actions/workflows/fuseki.yaml/badge.svg)](https://github.com/manuel-j-diaz/fuseki-ops/actions/workflows/fuseki.yaml)
[![Jena](https://img.shields.io/badge/Jena-6.0.0-blue)](https://jena.apache.org/)
[![Fuseki](https://img.shields.io/badge/Fuseki-6.0.0-blue)](https://jena.apache.org/documentation/fuseki2/)
[![License](https://img.shields.io/github/license/manuel-j-diaz/fuseki-ops)](LICENSE)

Docker images for [Apache Jena](https://jena.apache.org/) 6.0.0: CLI tools and Fuseki SPARQL server.

> **Local development only.** Not hardened for production — default credentials, no TLS, admin API exposed on host port. Do not expose to untrusted networks without hardening.

| Image | Description | Docs |
|-------|-------------|------|
| `jena` | Jena 6.0.0 CLI tools (`arq`, `riot`, `shacl`, `tdb2`, …) — one-shot containers | [jena/](jena/README.md) |
| `fuseki` | Fuseki 6.0.0 SPARQL server with web UI — long-running service | [fuseki/](fuseki/README.md) |

## Quick start

### Option 1: Pull from GHCR

Pre-built images are published to GitHub Container Registry. No login required.

```bash
# Jena CLI — run a SPARQL query
docker run --rm -v $(pwd):/rdf ghcr.io/manuel-j-diaz/fuseki-ops/jena:latest \
  arq --query query.rq --data data.ttl

# Fuseki — start with an in-memory dataset
docker run --rm -p 3030:3030 ghcr.io/manuel-j-diaz/fuseki-ops/fuseki:latest \
  --ui /fuseki/webapp --mem /ds
```

Available tags:

| Tag | Example | Description |
|-----|---------|-------------|
| `latest` | `latest` | Most recent build from `main` |
| version | `6.0.0` | Pinned to a release (from git tag `jena/v6.0.0` or `fuseki/v6.0.0`), no leading `v` |
| SHA | `a1b2c3d` | Pinned to a specific commit SHA |

### Option 2: Build from source

Requires Docker with Compose v2.

```bash
# Jena CLI
docker build -t jena --build-arg JENA_VERSION=6.0.0 jena/
docker run --rm -v $(pwd):/rdf jena arq --query query.rq --data data.ttl
```

```bash
# Fuseki (see fuseki/README.md for full setup including networking)
cp fuseki/.env.example fuseki/.env
docker network create --internal semantic-web
docker compose -f fuseki/docker-compose.yaml build --build-arg JENA_VERSION=6.0.0
docker compose -f fuseki/docker-compose.yaml up -d
# Web UI → http://localhost:3040
```

## License

Apache Jena and Apache Jena Fuseki are licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0). This repository is licensed under the same terms. See [LICENSE](LICENSE).
