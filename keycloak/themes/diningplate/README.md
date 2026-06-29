# DiningPlate Keycloak theme

Branding for the Keycloak-hosted **login / registration / forgot-password** pages so
they look native to DiningPlate while Keycloak still owns the credential flow
(Authorization Code + PKCE), brute-force protection, and MFA.

## Layout

```
diningplate/login/
  theme.properties              # extends parent=keycloak, appends css/diningplate.css
  resources/css/diningplate.css # brand colors / button / link overrides
```

## Activation

Mounted into the Keycloak container at `/opt/keycloak/themes/diningplate`
(see `compose/docker-compose.yml`) and selected by the realm's
`"loginTheme": "diningplate"` (see `keycloak/realm/diningplate-realm.json`).

## Iterating during development

Keycloak in production mode (`start`) caches themes. To see CSS edits without a
restart, set on the `keycloak` service:

```yaml
KC_SPI_THEME_CACHE_THEMES: "false"
KC_SPI_THEME_CACHE_TEMPLATES: "false"
KC_SPI_THEME_STATIC_MAX_AGE: "-1"
```

Remove these before production.

## Adding a logo

CSS-only theming inherits the parent templates, which render the realm name as the
header. To show an image logo, override `login/template.ftl` (copy from the base
`keycloak` theme) and reference an asset under `resources/img/`, or set the header via
CSS `content`. Keep template overrides minimal so future Keycloak upgrades stay easy.
