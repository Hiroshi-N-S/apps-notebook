# apps-notebook

Notebook apps

- [apps-notebook](#apps-notebook)
  - [References](#references)
  - [Deployment](#deployment)
  - [Configuring Authentication](#configuring-authentication)
    - [Configure GenericOAuthenticator for Authentication using Keycloak](#configure-genericoauthenticator-for-authentication-using-keycloak)

## References

- [Argo CD](https://argo-cd.readthedocs.io/en/stable/)
- [JupyterHub](https://z2jh.jupyter.org/en/latest/jupyterhub/index.html)

## Deployment

Deploying apps from the git repository

``` sh
git clone https://github.com/Hiroshi-N-S/apps-notebook.git

sh apps-notebook/bootstrap/init.sh
```

## Configuring Authentication

### [Configure GenericOAuthenticator for Authentication using Keycloak](https://z2jh.jupyter.org/en/stable/administrator/authentication.html#genericoauthenticator-openid-connect)

1. Configure or Create a `Client` for Accessing Keycloak

    Authenticate to the Keycloak `Administrative console` and navigate to `Clients`.

    Select `Create client` and follow the instructions to create a new Keycloak client for JupyterHub. Fill in the specified inputs as follows:

    ``` yaml
    Settings:
        General Settings:
            Client type: OpenID Connect
            Client ID: jupyterhub
            Name: jupyterhub
            Description: Client for jupyterhub
            Always display in UI: true
        Capability config:
            Client authentication: true
            Authorization: false
            Authetication flow:
                Standard flow: true
                Direct access grants: true
                Implicit flow: false
                Service accounts roles: true
                OAuth 2.0 Device Authorization Grant: false
                OIDC CIBA Grant: false
        Login settings:
            Root URL: https://mint.local/notebooks
            Home URL: "/"
            Valid redirect URIs:
                - "https://mint.local/notebooks/*"
            Varid post logout redirect URIs:
                - "https://mint.local/notebooks/*"
            Web origins:
                - https://mint.local/notebooks
    ```

2. Configure or Create a `Realm roles` for JupyterHub

    Authenticate to the Keycloak `Administrative console` and navigate to `Realm roles`.

    Select `Create role` and follow the instructions to create a new role for JupyterHub. Fill in the specified inputs as follows:

    ``` yaml
    Roles:
      - Name: jupyterhub-admin
        Description: Admin role for JupyterHub
      - Name: jupyterhub-user
        Description: Allowed role for JupyterHub
    ```
