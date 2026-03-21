# fuseki-ops

Docker deployments for [Apache Jena](https://jena.apache.org/) stack, including CLI tools and Fuseki SPARQL server. Each versioned subdirectory is self-contained.

> **Local development only.** This setup is not hardened for production:
> - Default credentials (`admin` / `password`) are weak and committed to the example env file
> - No TLS — all traffic, including credentials, is sent in plaintext over HTTP
> - The `semantic-web` network is internal but Fuseki's admin API is exposed on the host port with no additional access controls
>
> Do not expose this service to the public internet or untrusted networks without addressing the above.

## Images

| Directory | Contents | Type |
|-----------|----------|------|
| `jena-6.0.0/` | Jena 6.0.0 CLI tools (`arq`, `riot`, `sparql`, `tdb2`, …) | One-shot CLI |
| `fuseki-6.0.0/` | Fuseki 6.0.0 SPARQL server with web UI | Long-running service |

## Prerequisites

- Docker with Compose v2

---

## Jena CLI (`jena-6.0.0/`)

### Build

```bash
docker build -t jena --build-arg JENA_VERSION=6.0.0 jena-6.0.0/
```

### Usage

Mount a directory containing your `.rq` query files and `.ttl` data files to `/rdf` (the container working directory):

```bash
# SPARQL query against a local Turtle file
docker run --rm -v $(pwd):/rdf jena arq --query query.rq --data data.ttl

# Validate / convert RDF syntax
docker run --rm -v $(pwd):/rdf jena riot --validate data.ttl
docker run --rm -v $(pwd):/rdf jena riot --out NTRIPLES data.ttl

# Query a remote SPARQL endpoint
docker run --rm jena arq --query query.rq --service http://host.docker.internal:3040/ds/query
```

### Available tools

| Tool | Purpose |
|------|---------|
| `arq`, `sparql` | SPARQL query (SELECT, CONSTRUCT, ASK, DESCRIBE) |
| `update` | SPARQL Update (INSERT/DELETE) |
| `rsparql`, `rupdate` | Query/update a remote SPARQL endpoint |
| `riot` | Parse, validate, and convert RDF (Turtle, N-Triples, JSON-LD, RDF/XML, …) |
| `rdfparse`, `rdfcat`, `rdfcopy`, `rdfdiff`, `rdfcompare` | RDF file utilities |
| `rdfxml`, `ntriples`, `nquads`, `turtle`, `trig` | Format-specific parsers |
| `rdfpatch` | Apply RDF Patch changesets |
| `shacl` | SHACL validation |
| `shex` | ShEx validation |
| `infer` | RDFS / OWL inference |
| `qparse`, `uparse` | Parse and print SPARQL query/update syntax trees |
| `rset` | Read and display SPARQL result sets |
| `tdb2.tdbloader`, `tdb2.xloader` | Bulk-load RDF into a TDB2 dataset |
| `tdb2.tdbquery` | Query a TDB2 dataset directly |
| `tdb2.tdbupdate` | SPARQL Update against a TDB2 dataset |
| `tdb2.tdbdump`, `tdb2.tdbstats` | Inspect a TDB2 dataset |
| `tdb2.tdbbackup`, `tdb2.tdbcompact` | Backup and compact a TDB2 dataset |
| `tdb1.*`, `tdbloader`, `tdbquery`, … | TDB1 equivalents (legacy) |
| `iri` | Parse and normalise IRIs |
| `langtag` | Parse and validate BCP 47 language tags |
| `juuid` | Generate UUIDs |
| `schemagen` | Generate Java classes from an OWL/RDFS schema |
| `wwwenc`, `wwwdec`, `utf8` | URL encoding / UTF-8 utilities |

---

## Fuseki SPARQL Server (`fuseki-6.0.0/`)

### Configuration

Copy and edit the env file before first use:

```bash
cp fuseki-6.0.0/.env.example fuseki-6.0.0/.env
```

| Variable | Default | Description |
|----------|---------|-------------|
| `FUSEKI_PORT` | `3040` | Host port Fuseki is exposed on |
| `FUSEKI_ADMIN_USER` | `admin` | Admin username |
| `FUSEKI_ADMIN_PASSWORD` | `password` | Admin password |
| `DOCKER_NETWORK` | `semantic-web` | External Docker network name |

### Build

```bash
docker compose -f fuseki-6.0.0/docker-compose.yaml build --build-arg JENA_VERSION=6.0.0
```

### Run

The dataset mode is set by the `command` in `fuseki-6.0.0/docker-compose.yaml`. The default is in-memory. To switch to persistent TDB2, comment/uncomment the two `command` lines in the compose file, then:

```bash
docker compose -f fuseki-6.0.0/docker-compose.yaml up
```

> **Note:** Use `docker compose up` rather than `docker compose run --service-ports`. Due to a bug in Compose v2.29.x, the latter does not reliably publish ports when the service is on a non-default network.

Fuseki will be available at `http://localhost:3040` (or whatever `FUSEKI_PORT` in [fuseki-6.0.0/.env](./fuseki-6.0.0/.env) is set to). All endpoints require HTTP Basic Auth.

### Debugging

To run a one-shot diagnostic container that probes the Fuseki service (DNS, ping, HTTP):

```bash
docker compose -f fuseki-6.0.0/docker-compose.yaml -f fuseki-6.0.0/docker-compose.debug.yaml up
```

### Web UI and SPARQL Endpoints

The web UI is available at `http://localhost:3040`. The `/ds` dataset also exposes protocol endpoints directly:

| Endpoint | URL |
|----------|-----|
| SPARQL Query | `http://localhost:3040/ds/query` |
| SPARQL Update | `http://localhost:3040/ds/update` |
| Graph Store | `http://localhost:3040/ds/data` |
| Liveness | `http://localhost:3040/$/ping` |
