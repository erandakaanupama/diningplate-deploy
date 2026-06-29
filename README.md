# diningplate-deploy

Deployment and database artifacts for the DiningPlate platform: Docker image
builds, Compose stacks, and the database schema/model — decoupled from the
individual service repos.

> **`deploy.spec` is the source of truth** for the deployment topology (services,
> ports, versions, image builds, startup order, network). Update it before making
> changes here.

## Layout

```
diningplate-deploy/
├── deploy.spec                   # deployment spec — source of truth
├── compose/
│   ├── docker-compose.yml        # keycloak(+db) + configserver + eurekaserver + order-service + gatewayserver
│   ├── docker-compose.db.yml     # mysql 8.4
│   ├── .env                      # image tags / creds (generated; git-ignored)
│   └── .env.example              # template for .env
├── keycloak/
│   ├── realm/diningplate-realm.json  # realm, roles, clients, seed users (imported on start)
│   └── themes/diningplate/           # branded login / registration pages
├── scripts/
│   ├── build-jars.ps1            # assemble each service's jar (gradlew clean assemble)
│   ├── docker-build.ps1          # build all service images, generate compose/.env
│   └── build-all.ps1             # pipeline: build-jars.ps1 -> docker-build.ps1
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
├── diningplate-configserver/  # 8090
├── eurekaserver/              # 8091
├── order-service/            # 8080
└── gatewayserver/            # 8092
```

## Build images

Build the service jars and Docker images in one shot (dependency order:
configserver → eurekaserver → order-service → gatewayserver):

```powershell
.\scripts\build-all.ps1
```

`build-all.ps1` runs `build-jars.ps1` (each service's `gradlew clean assemble`) then
`docker-build.ps1` (reads each `gradle.properties` `version`, writes `compose/.env`,
tags the images). Run the stages on their own if you only need one:

```powershell
.\scripts\build-jars.ps1     # jars only
.\scripts\docker-build.ps1   # images from existing jars
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

# services (includes keycloak + keycloak-db; brought up in dependency order)
docker compose -f compose/docker-compose.yml up -d
```

> **Push the config repo first.** The gateway pulls its resource-server settings
> (`jwk-set-uri`, issuer, CORS) from `diningplate-config/gatewayserver.yaml`, which the
> config server clones from GitHub on start. Commit and push that file before bringing
> the stack up, or the gateway won't load the security config.

## Security / identity (Keycloak)

The gateway is an **OAuth2 Resource Server**: every route under
`/diningplate/order-service/**` requires a valid Bearer JWT from the `diningplate`
realm, and access is enforced per route by realm role (`CUSTOMER`, `KITCHEN`,
`DELIVERY`, `ADMIN`). `/actuator/**` stays public.

- **Keycloak** runs in production mode (`start --import-realm`) on host **7080**
  (container 8080), backed by a dedicated **Postgres** (`keycloak-db`). Admin console:
  `http://localhost:7080/admin` (default `admin`/`admin` — override via `.env`).
- The realm, roles, the public PKCE client `diningplate-web`, and one **dev user per
  role** (`<role>1@diningplate.test` / `Password123`) are imported from
  `keycloak/realm/diningplate-realm.json`. Import happens only against an empty DB —
  to re-import after edits, recreate the `keycloak-db-data` volume
  (`docker compose -f compose/docker-compose.yml down -v keycloak-db`).
- Login / registration use Keycloak-hosted pages branded by
  `keycloak/themes/diningplate`. Customers self-register (auto-assigned `CUSTOMER`);
  staff are admin-provisioned via the console.

Fetch a token and call the gateway:

```powershell
$token = (Invoke-RestMethod -Method Post `
  -Uri http://localhost:7080/realms/diningplate/protocol/openid-connect/token `
  -Body @{ grant_type='password'; client_id='diningplate-web';
           username='admin1@diningplate.test'; password='Password123' }).access_token

Invoke-RestMethod -Uri http://localhost:8092/diningplate/order-service/api/v1/menu `
  -Headers @{ Authorization = "Bearer $token" }
```

## Database

`db/schema/dining_plate.sql` is the source of truth for the schema, generated
from `db/model/dining-plate_models.mwb` (MySQL Workbench). `order-service` runs
with `spring.jpa.hibernate.ddl-auto: validate`, so the schema must be applied
out-of-band — apply the schema, then any scripts under `db/migration/` in order:

```powershell
Get-Content db/schema/dining_plate.sql | docker exec -i diningplate-db mysql -uroot -psecret
```
