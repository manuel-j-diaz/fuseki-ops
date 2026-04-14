# Jena 6.0.0

> Part of [fuseki-ops](../README.md).

Self-contained Docker image of the [Apache Jena 6.0.0](https://jena.apache.org/) CLI toolkit. Intended for one-shot use: run a command, get output, container exits.

## Pull or build

```bash
# Pull from GHCR (no login required)
docker pull ghcr.io/manuel-j-diaz/fuseki-ops/jena:latest

# — or build locally —
docker build -t jena --build-arg JENA_VERSION=6.0.0 .
```

The examples below use `jena` as the image name. Substitute the GHCR path if you pulled instead of building.

## Usage

Mount a directory containing your query and data files to `/rdf` (the container working directory), then pass any Jena tool as the command:

```bash
# SPARQL SELECT query against a local Turtle file
docker run --rm -v $(pwd):/rdf jena arq --query query.rq --data data.ttl

# SPARQL CONSTRUCT — output as Turtle
docker run --rm -v $(pwd):/rdf jena arq --query construct.rq --data data.ttl --out TTL

# Validate RDF syntax
docker run --rm -v $(pwd):/rdf jena riot --validate data.ttl

# Convert Turtle to N-Triples
docker run --rm -v $(pwd):/rdf jena riot --out NTRIPLES data.ttl

# Query a remote SPARQL endpoint (Fuseki running on the host)
docker run --rm -v $(pwd):/rdf jena arq --query query.rq --service http://host.docker.internal:3040/ds/query

# SHACL validation
docker run --rm -v $(pwd):/rdf jena shacl validate --shapes shapes.ttl --data data.ttl

# Bulk-load RDF into a TDB2 dataset on the host filesystem
docker run --rm -v $(pwd):/rdf jena tdb2.tdbloader --loc /rdf/mydb data.ttl
```

Logs go to STDERR; query results go to STDOUT — they do not mix.

## Available tools

<details>
<summary>Full tool list (click to expand)</summary>

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

</details>

## How the image is built

Single-stage build based on `eclipse-temurin:21-jre-alpine`.

`apache-jena-6.0.0.tar.gz` is downloaded from Maven Central and verified against its SHA1 checksum (fetched automatically by `download.sh`). After extraction, javadoc, source, and Windows batch files are stripped to reduce image size.

Bash is installed explicitly (`apk add bash`) because the Jena bin scripts require it. All tools are placed on `PATH` via `/jena/bin`. The container working directory is `/rdf` — files mounted there are accessible by relative path in tool arguments.

A `riot --version` smoke test runs at build time to confirm the tools are functional.
