# Agents

## Cursor Cloud specific instructions

### Project Overview

Coze Studio is an AI agent development platform with a Go backend (Hertz framework) and a React+TypeScript frontend (Rush.js monorepo, ~130 packages).

### System Requirements

- **Node.js** >= 21 (despite `.nvmrc` saying `lts/iron`, `rush.json` requires `nodeSupportedVersionRange: ">=21"`)
- **Go** 1.24.x (use 1.24.4+; Go 1.24.0 has a link error with `sonic/loader`)
- **Docker** with Docker Compose
- **Python 3** with `python3-venv` package

### Running the Frontend Dev Server

```bash
cd frontend/apps/coze-studio
WEB_SERVER_PORT=8888 IS_OPEN_SOURCE=true CUSTOM_VERSION=release npx rsbuild dev --host 0.0.0.0
```

The dev server starts on port 8080 and proxies `/api` requests to the Go backend on port 8888. Initial build takes ~3.5 minutes.

### Running the Go Backend

```bash
# Build
export APP_ENV=debug
bash scripts/setup/server.sh

# Start
cd bin && source .env.debug && ./opencoze -start
```

The server listens on `:8888`.

### Middleware (Docker Compose)

The debug middleware stack is defined in `docker/docker-compose-debug.yml`. **Important**: Bitnami Docker Hub images (elasticsearch, redis, etcd) are no longer available. Use the override file `docker/docker-compose-debug.override.yml` which substitutes:

| Original Image | Replacement |
|---|---|
| `bitnami/elasticsearch:8.18.0` | `docker.elastic.co/elasticsearch/elasticsearch:8.18.0` |
| `bitnami/redis:8.0` | `redis:8.0` |
| `bitnami/etcd:3.5` | `quay.io/coreos/etcd:v3.5.18` |

Start middleware:
```bash
cd docker
cp .env.debug.example .env.debug
docker compose -f docker-compose-debug.yml -f docker-compose-debug.override.yml --env-file .env.debug --profile middleware up -d
```

After middleware is healthy, set up ES indices:
```bash
source docker/.env.debug
bash docker/volumes/elasticsearch/setup_es.sh --index-dir docker/volumes/elasticsearch/es_index_schema --docker-host false --es-address "$ES_ADDR"
```

### Rush Monorepo

Use `rush update --bypass-policy` because the agent git hooks config (`core.hooksPath`) conflicts with Rush's git hooks installation. Rush uses pnpm 8.15.8 (auto-installed).

### Lint

- Frontend: `cd frontend/apps/coze-studio && npx eslint ./ --cache --quiet`
- Backend: `cd backend && go vet ./...`

### Tests

- Frontend: `cd frontend/apps/coze-studio && npx vitest --run --passWithNoTests`
- Backend: `cd backend && go test ./... -count=1 -short` (some workflow tests fail without full integration setup)

### LLM Model Configuration

Agent creation requires at least one LLM model configured in `docker/.env.debug` (or `backend/conf/model/` YAML files). Without model API keys, the UI will show "there is no llm model in use" when creating agents. See `docker/.env.example` for all `MODEL_*` environment variables.
