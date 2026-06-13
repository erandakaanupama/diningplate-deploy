# diningplate-deploy

Deployment and database artifacts for the DiningPlate platform: Docker image
builds, Compose stacks, and the database schema/model — decoupled from the
individual service repos.

## Layout

```
diningplate-deploy/
├── compose/
│   ├── docker-compose.yml        # configserver + order-service
│   ├── docker-compose.db.yml     # mysql 8.4
│   ├── .env                      # image tags / creds (generated; git-ignored)
│   └── .env.example              # template for .env
├── scripts/
│   └── docker-build.ps1          # build service images, generate compose/.env
├── db/
│   ├── schema/dining_plate.sql   # full schema (source of truth)
│   ├── migration/                # incremental change scripts
│   └── model/                    # MySQL Workbench .mwb model
└── .gitignore
```

## Prerequisites

The service repos are expected to be checked out as **siblings** of this repo:

```
<workspace>/
├── diningplate-deploy/        # this repo
├── diningplate-configserver/
└── order-service/
```

## Build images

Reads each service's `version` from its `gradle.properties`, writes
`compose/.env`, then builds the images:

```powershell
.\scripts\docker-build.ps1
```

## Run the stack

The compose files read image tags and DB credentials from `compose/.env`
(generate it via the build script, or copy `compose/.env.example` to
`compose/.env`). Because `.env` sits next to the compose files, Compose loads it
automatically when you point at those files — no need to run from a particular
directory.

They use an external network, so create it once:

```powershell
docker network create diningplate-net

# database
docker compose -f compose/docker-compose.db.yml up -d

# services
docker compose -f compose/docker-compose.yml up -d
```

## Database

`db/schema/dining_plate.sql` is the source of truth for the schema, generated
from `db/model/dining-plate_models.mwb` (MySQL Workbench). `order-service` runs
with `spring.jpa.hibernate.ddl-auto: validate`, so the schema must be applied
out-of-band — apply the schema, then any scripts under `db/migration/` in order:

```powershell
Get-Content db/schema/dining_plate.sql | docker exec -i diningplate-db mysql -uroot -psecret
```
