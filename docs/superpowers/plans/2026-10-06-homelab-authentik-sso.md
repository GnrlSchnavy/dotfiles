# Homelab Authentik SSO Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a single-sign-on solution for the homelab cluster using Authentik as the identity provider, so family members have one set of credentials for Jellyfin, Jellyseerr, and other cluster services.

**Architecture:** Authentik runs on the cluster with dedicated PostgreSQL storage. Jellyfin and Jellyseerr authenticate via OIDC. Services without native OIDC support authenticate through Traefik's forward-auth middleware, which proxies to Authentik's outpost. Family members get individual accounts in Authentik with group-based permissions for controlling who can access what.

**Tech Stack:** 
- Authentik (identity provider)
- PostgreSQL (Authentik backend)
- Traefik (ingress & forward auth)
- Jellyfin + OIDC plugin
- Jellyseerr (uses Jellyfin auth)
- Kubernetes (1.24+)

**Spec:** User notes in `.claude/projects/-Users-yvan-sytac-projects-personal-dotfiles/memory/` referencing Jellyfin SSO and homelab cluster setup.

## Global Constraints

- Authentik runs only on the cluster (no external managed service)
- PostgreSQL is Authentik-exclusive (no shared database)
- All services must be accessible via single Authentik login where possible
- Family group permissions control access (not just binary allow/deny)
- Work in phases: Jellyfin+Jellyseerr first, remaining services later

## Review Focus

1. **OIDC redirect URIs:** Jellyfin OIDC client config must match exactly what Jellyfin sends; mismatches cause silent auth failures
2. **Forward-auth header mismatch:** Traefik middleware and Authentik outpost must use the same remote-user header format
3. **Group sync timing:** Family group membership in Authentik doesn't auto-reflect in Jellyfin; verify sync after group changes
4. **Password policy conflict:** Authentik's password requirements may conflict with what users remember; document requirements upfront
5. **Token expiry and refresh:** Jellyfin + Jellyseerr must handle token refresh correctly; stale tokens cause silent lockouts

---

## Phase 1: Authentik Infrastructure

### Task 1: Deploy PostgreSQL for Authentik

**Files:**
- Create: `nix/cluster/authentik-postgres.nix`
- Modify: `nix/cluster/default.nix` (add postgres module)
- Test: Manual verification after deployment

**Interfaces:**
- Produces: PostgreSQL Service `authentik-postgres.authentik.svc.cluster.local:5432`, database `authentik`, user `authentik`, password from secret

**Steps:**

- [ ] **Step 1: Create PostgreSQL deployment manifest**

Create `nix/cluster/authentik-postgres.nix`:

```nix
{ pkgs, ... }:

{
  imports = [];

  # StatefulSet for PostgreSQL with persistent storage
  kubernetes.resources.statefulSets.authentik-postgres = {
    metadata.namespace = "authentik";
    spec = {
      serviceName = "authentik-postgres";
      replicas = 1;
      selector.matchLabels.app = "authentik-postgres";
      template = {
        metadata.labels.app = "authentik-postgres";
        spec = {
          containers = [{
            name = "postgres";
            image = "postgres:15-alpine";
            ports = [{ containerPort = 5432; }];
            env = [
              {
                name = "POSTGRES_DB";
                value = "authentik";
              }
              {
                name = "POSTGRES_USER";
                value = "authentik";
              }
              {
                name = "POSTGRES_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "authentik-postgres-secret";
                  key = "password";
                };
              }
            ];
            volumeMounts = [{
              name = "postgres-storage";
              mountPath = "/var/lib/postgresql/data";
            }];
          }];
          volumes = [];
        };
      };
      volumeClaimTemplates = [{
        metadata.name = "postgres-storage";
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "local-path";
          resources.requests.storage = "20Gi";
        };
      }];
    };
  };

  # Service for PostgreSQL
  kubernetes.resources.services.authentik-postgres = {
    metadata.namespace = "authentik";
    spec = {
      selector.app = "authentik-postgres";
      ports = [{ port = 5432; targetPort = 5432; }];
      clusterIP = "None"; # Headless service for StatefulSet
    };
  };

  # Secret for PostgreSQL password
  kubernetes.resources.secrets.authentik-postgres-secret = {
    metadata.namespace = "authentik";
    type = "Opaque";
    data.password = "change-me-base64-encoded"; # Replace with actual base64
  };
}
```

- [ ] **Step 2: Generate secure PostgreSQL password**

Run locally:
```bash
# Generate a 32-character random password and base64-encode it
python3 -c "import base64, secrets; pwd = secrets.token_urlsafe(32); print(base64.b64encode(pwd.encode()).decode())"
```

Save the output for the Secret's `data.password` field in the manifest above.

- [ ] **Step 3: Add authentik namespace and postgres module to cluster config**

Modify `nix/cluster/default.nix` to include the new module and namespace:

```nix
kubernetes.namespaces.authentik.metadata.labels.name = "authentik";

imports = [
  ./authentik-postgres.nix
  # ... other imports
];
```

- [ ] **Step 4: Deploy and verify PostgreSQL**

```bash
# Apply the kubernetes manifests via your cluster deployment method
# (adjust for your nix-based k8s workflow)

# Verify the StatefulSet rolled out
kubectl rollout status statefulset/authentik-postgres -n authentik

# Verify the PVC is bound
kubectl get pvc -n authentik

# Test connectivity (from a temp pod or directly if accessible)
kubectl run -it --rm debug --image=postgres:15-alpine --restart=Never -- \
  psql postgresql://authentik:PASSWORD@authentik-postgres.authentik.svc.cluster.local/authentik
```

Expected: `psql` prompt connects successfully.

- [ ] **Step 5: Commit PostgreSQL setup**

```bash
git add nix/cluster/authentik-postgres.nix nix/cluster/default.nix
git commit -m "infra: add PostgreSQL StatefulSet for Authentik"
```

---

### Task 2: Deploy Authentik with OIDC Provider

**Files:**
- Create: `nix/cluster/authentik.nix`
- Create: `nix/cluster/authentik-config.yaml` (ConfigMap template)
- Modify: `nix/cluster/default.nix` (add authentik module)
- Test: Manual verification of Authentik UI availability

**Interfaces:**
- Consumes: PostgreSQL Service from Task 1 (`authentik-postgres.authentik.svc.cluster.local:5432`)
- Produces: Authentik Service `authentik.authentik.svc.cluster.local:9000`, OIDC provider endpoint `/application/o/authorize/`, JWT signing key in Secret `authentik-secret-key`

**Steps:**

- [ ] **Step 1: Create Authentik Deployment manifest**

Create `nix/cluster/authentik.nix`:

```nix
{ pkgs, ... }:

{
  kubernetes.resources.deployments.authentik-server = {
    metadata.namespace = "authentik";
    spec = {
      replicas = 1;
      selector.matchLabels.app = "authentik-server";
      template = {
        metadata.labels.app = "authentik-server";
        spec = {
          containers = [{
            name = "authentik-server";
            image = "ghcr.io/goauthentik/authentik:2024.8"; # Use latest stable
            ports = [
              { containerPort = 9000; name = "http"; }
              { containerPort = 9443; name = "https"; }
            ];
            env = [
              { name = "AUTHENTIK_REDIS__HOST"; value = "authentik-redis"; }
              { name = "AUTHENTIK_REDIS__PORT"; value = "6379"; }
              { name = "AUTHENTIK_POSTGRESQL__HOST"; value = "authentik-postgres"; }
              { name = "AUTHENTIK_POSTGRESQL__PORT"; value = "5432"; }
              { name = "AUTHENTIK_POSTGRESQL__NAME"; value = "authentik"; }
              { name = "AUTHENTIK_POSTGRESQL__USER"; value = "authentik"; }
              {
                name = "AUTHENTIK_POSTGRESQL__PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "authentik-postgres-secret";
                  key = "password";
                };
              }
              {
                name = "AUTHENTIK_SECRET_KEY";
                valueFrom.secretKeyRef = {
                  name = "authentik-secret-key";
                  key = "secret";
                };
              }
              { name = "AUTHENTIK_LOG_LEVEL"; value = "debug"; }
              { name = "AUTHENTIK_BOOTSTRAP_TOKEN"; value = "changeme"; }
            ];
            volumeMounts = [{
              name = "media";
              mountPath = "/media";
            }];
          }];
          volumes = [{
            name = "media";
            emptyDir = {};
          }];
        };
      };
    };
  };

  # Service
  kubernetes.resources.services.authentik = {
    metadata.namespace = "authentik";
    spec = {
      selector.app = "authentik-server";
      ports = [
        { port = 9000; targetPort = 9000; name = "http"; }
        { port = 9443; targetPort = 9443; name = "https"; }
      ];
    };
  };

  # Secret for Authentik's signing key
  kubernetes.resources.secrets.authentik-secret-key = {
    metadata.namespace = "authentik";
    type = "Opaque";
    data.secret = "change-me-base64-encoded"; # Replace with actual base64
  };

  # TODO: Add Redis deployment for session/cache store
}
```

- [ ] **Step 2: Generate Authentik secret key**

```bash
python3 -c "import base64, secrets; key = secrets.token_urlsafe(64); print(base64.b64encode(key.encode()).decode())"
```

Update `data.secret` in `authentik-secret-key` Secret.

- [ ] **Step 3: Add Redis (cache/session store)**

Add to the same `authentik.nix` file:

```nix
  kubernetes.resources.deployments.authentik-redis = {
    metadata.namespace = "authentik";
    spec = {
      replicas = 1;
      selector.matchLabels.app = "authentik-redis";
      template = {
        metadata.labels.app = "authentik-redis";
        spec = {
          containers = [{
            name = "redis";
            image = "redis:7-alpine";
            ports = [{ containerPort = 6379; }];
          }];
        };
      };
    };
  };

  kubernetes.resources.services.authentik-redis = {
    metadata.namespace = "authentik";
    spec = {
      selector.app = "authentik-redis";
      ports = [{ port = 6379; targetPort = 6379; }];
    };
  };
```

- [ ] **Step 4: Add Ingress for Authentik UI**

Add to `authentik.nix`:

```nix
  kubernetes.resources.ingresses.authentik = {
    metadata = {
      namespace = "authentik";
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
        "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
      };
    };
    spec = {
      ingressClassName = "traefik";
      tls = [{
        hosts = [ "authentik.example.com" ]; # Replace with your domain
        secretName = "authentik-tls";
      }];
      rules = [{
        host = "authentik.example.com";
        http.paths = [{
          path = "/";
          pathType = "Prefix";
          backend.service = {
            name = "authentik";
            port.number = 9000;
          };
        }];
      }];
    };
  };
```

- [ ] **Step 5: Deploy Authentik**

```bash
kubectl apply -f nix/cluster/authentik.nix

# Wait for deployment
kubectl rollout status deployment/authentik-server -n authentik
kubectl rollout status deployment/authentik-redis -n authentik

# Get the service IP or domain
kubectl get ingress -n authentik
```

- [ ] **Step 6: Access Authentik UI and create admin user**

Navigate to `https://authentik.example.com/if/flow/initial-setup/` in your browser. Complete the initial setup:
- Set admin username and password
- Confirm bootstrap token matches what you set in the env var

Take a screenshot or note the admin credentials in your password manager.

- [ ] **Step 7: Commit Authentik setup**

```bash
git add nix/cluster/authentik.nix nix/cluster/default.nix
git commit -m "infra: deploy Authentik identity provider with Redis"
```

---

### Task 3: Configure Authentik OIDC Provider

**Files:**
- Modify: Authentik UI (no code changes, manual configuration)
- Create: `docs/authentik-oidc-setup.md` (guide for future reference)
- Test: Manual verification of OIDC provider endpoint

**Interfaces:**
- Consumes: Authentik Service from Task 2
- Produces: OIDC Client credentials (Client ID, Client Secret) and endpoint URL for Jellyfin to consume

**Steps:**

- [ ] **Step 1: Create OIDC Provider in Authentik UI**

1. Log into Authentik admin console at `https://authentik.example.com/if/admin/`
2. Navigate to **System > Providers** → **Create → OAuth2/OpenID Connect**
3. Fill in:
   - **Name:** `jellyfin-oidc`
   - **Authorization flow:** (select the default authorization flow)
   - **Allowed redirect URIs:** 
     ```
     http://jellyfin.example.com/sso/oidc/callback
     https://jellyfin.example.com/sso/oidc/callback
     ```
   - **Scopes:** Select `openid`, `profile`, `email`
   - **Access token expiry:** `hours=24` (or your preference)
   - **Refresh token expiry:** `days=30`

4. Save and note the **Client ID** and **Client Secret** (you'll need these in Task 4)

- [ ] **Step 2: Create OIDC Application in Authentik UI**

1. Navigate to **Applications > Applications** → **Create**
2. Fill in:
   - **Name:** `jellyfin`
   - **Slug:** `jellyfin`
   - **Provider:** Select the OIDC provider from Step 1
   - **Authorization flow:** (default is fine)

3. Save

- [ ] **Step 3: Create default user group for family**

1. Navigate to **Directory > Groups** → **Create**
2. Create a group:
   - **Name:** `family`
   - **Parent:** (leave empty)

3. Save

Later, family member accounts will be added to this group.

- [ ] **Step 4: Document OIDC configuration**

Create `docs/authentik-oidc-setup.md`:

```markdown
# Authentik OIDC Configuration

## OIDC Provider Details

- **Provider Name:** jellyfin-oidc
- **OIDC Discovery Endpoint:** https://authentik.example.com/application/o/jellyfin/.well-known/openid-configuration
- **Authorization Endpoint:** https://authentik.example.com/application/o/authorize/
- **Token Endpoint:** https://authentik.example.com/application/o/token/
- **Userinfo Endpoint:** https://authentik.example.com/application/o/userinfo/

## Client Credentials

**Client ID:** (from Authentik UI — Providers > jellyfin-oidc)
**Client Secret:** (from Authentik UI — Providers > jellyfin-oidc)

Store Client Secret securely; it will be needed for Jellyfin configuration.

## Redirect URIs

- http://jellyfin.example.com/sso/oidc/callback
- https://jellyfin.example.com/sso/oidc/callback

## Scopes

openid, profile, email

## Token Expiry

- Access token: 24 hours
- Refresh token: 30 days

## Test

```bash
# Verify OIDC discovery endpoint
curl https://authentik.example.com/application/o/jellyfin/.well-known/openid-configuration | jq .
```

Should return JSON with `authorization_endpoint`, `token_endpoint`, `issuer`, etc.
```

Commit:
```bash
git add docs/authentik-oidc-setup.md
git commit -m "docs: Authentik OIDC configuration reference"
```

---

## Phase 2: Jellyfin & Jellyseerr Integration

### Task 4: Configure Jellyfin with OIDC

**Files:**
- Modify: Jellyfin Helm values or deployment config (e.g., `nix/cluster/jellyfin.nix`)
- Create: `nix/cluster/jellyfin-oidc-plugin.nix` (plugin installation config)
- Test: Manual verification of login via OIDC

**Interfaces:**
- Consumes: OIDC Client credentials from Task 3 (`client-id`, `client-secret`, OIDC discovery endpoint)
- Produces: Jellyfin accessible at `jellyfin.example.com` with OIDC login button

**Steps:**

- [ ] **Step 1: Install Jellyfin OIDC plugin**

Jellyfin requires the OIDC plugin. Add to Jellyfin deployment (if using Helm, add to values):

```nix
# In your jellyfin.nix deployment

kubernetes.resources.deployments.jellyfin = {
  # ... existing spec ...
  spec.template.spec.containers = [{
    # ... existing container config ...
    env = [
      # ... existing env vars ...
      {
        name = "JELLYFIN_PLUGIN_REPOSITORY_URL";
        value = "https://repo.jellyfin.org/releases/plugin/manifest.json";
      }
    ];
    volumeMounts = [
      # ... existing mounts ...
      {
        name = "jellyfin-plugins";
        mountPath = "/config/plugins";
      }
    ];
  }];
  spec.template.spec.volumes = [
    # ... existing volumes ...
    {
      name = "jellyfin-plugins";
      persistentVolumeClaim.claimName = "jellyfin-plugins-pvc";
    }
  ];
};

# Persistent volume claim for plugins
kubernetes.resources.persistentVolumeClaims.jellyfin-plugins-pvc = {
  metadata.namespace = "jellyfin";
  spec = {
    accessModes = [ "ReadWriteOnce" ];
    storageClassName = "local-path";
    resources.requests.storage = "1Gi";
  };
};
```

- [ ] **Step 2: Install SSO plugin manually or via plugin manager**

In Jellyfin UI:
1. Go to **Dashboard > Plugins > Repositories**
2. Add repository: `https://repo.jellyfin.org/releases/plugin/manifest.json`
3. Go to **Catalog** → search for "SSO"
4. Install "SSO Authentication" plugin by jellyfin-contrib
5. Restart Jellyfin

- [ ] **Step 3: Configure OIDC in Jellyfin UI**

1. Go to **Dashboard > Plugins > My Plugins > SSO Authentication > Settings**
2. Fill in:
   - **OpenID Connect Discovery URL:** `https://authentik.example.com/application/o/jellyfin/.well-known/openid-configuration`
   - **Client ID:** (from Task 3)
   - **Client Secret:** (from Task 3)
   - **Redirect URI:** `https://jellyfin.example.com/sso/oidc/callback` (must match Task 3)
   - **Scopes:** `openid profile email`
   - **Username claim:** `preferred_username`
   - **Email claim:** `email`
   - **Auto-create users:** Yes (so first-time users from Authentik are automatically created)
   - **Enable OIDC button on login screen:** Yes

3. Save

- [ ] **Step 4: Test OIDC login**

1. Go to Jellyfin login page (`https://jellyfin.example.com`)
2. Verify an **"OpenID Connect"** or **"Authentik"** button appears
3. Click it and log in with an Authentik account
4. Verify you are redirected back to Jellyfin and logged in

Expected: You should see your Jellyfin dashboard without a separate password.

- [ ] **Step 5: Commit Jellyfin OIDC integration**

```bash
git add nix/cluster/jellyfin.nix nix/cluster/jellyfin-oidc-plugin.nix
git commit -m "feat: enable OIDC single sign-on in Jellyfin"
```

---

### Task 5: Configure Jellyseerr with Jellyfin Auth

**Files:**
- Modify: Jellyseerr deployment config (e.g., `nix/cluster/jellyseerr.nix`)
- Test: Manual verification of Jellyseerr login via Jellyfin account

**Interfaces:**
- Consumes: Jellyfin Service URL and credentials (already available)
- Produces: Jellyseerr accessible at `jellyseerr.example.com`, users can log in with Jellyfin accounts

**Steps:**

- [ ] **Step 1: Deploy Jellyseerr**

If not already deployed, add to your cluster:

```nix
kubernetes.resources.deployments.jellyseerr = {
  metadata.namespace = "jellyseerr";
  spec = {
    replicas = 1;
    selector.matchLabels.app = "jellyseerr";
    template = {
      metadata.labels.app = "jellyseerr";
      spec = {
        containers = [{
          name = "jellyseerr";
          image = "fallenbagel/jellyseerr:latest";
          ports = [{ containerPort = 5055; }];
          env = [
            {
              name = "JELLYFIN_URL";
              value = "https://jellyfin.example.com";
            }
            {
              name = "LOG_LEVEL";
              value = "debug";
            }
          ];
          volumeMounts = [{
            name = "jellyseerr-config";
            mountPath = "/app/config";
          }];
        }];
        volumes = [{
          name = "jellyseerr-config";
          persistentVolumeClaim.claimName = "jellyseerr-config-pvc";
        }];
      };
    };
  };
};

kubernetes.resources.services.jellyseerr = {
  metadata.namespace = "jellyseerr";
  spec = {
    selector.app = "jellyseerr";
    ports = [{ port = 5055; targetPort = 5055; }];
  };
};

kubernetes.resources.persistentVolumeClaims.jellyseerr-config-pvc = {
  metadata.namespace = "jellyseerr";
  spec = {
    accessModes = [ "ReadWriteOnce" ];
    storageClassName = "local-path";
    resources.requests.storage = "2Gi";
  };
};
```

- [ ] **Step 2: Access Jellyseerr initial setup**

1. Navigate to `https://jellyseerr.example.com` (or `http://localhost:5055` if not behind ingress yet)
2. Follow the setup wizard

- [ ] **Step 3: Configure Jellyfin connection in Jellyseerr**

In the setup wizard:
1. **Jellyfin URL:** `https://jellyfin.example.com` (or internal URL if accessible from pod)
2. **API Key:** (create one in Jellyfin: Dashboard > Users > admin > API Keys, or provide later)
3. **Enable external Jellyfin login:** Yes

This allows users to log in to Jellyseerr using their Jellyfin credentials (which are now Authentik credentials via OIDC).

- [ ] **Step 4: Complete initial setup**

Finish the setup wizard and verify:
1. Jellyseerr dashboard is accessible
2. Login screen shows Jellyfin login option
3. You can log in with your Jellyfin (Authentik) account

- [ ] **Step 5: Commit Jellyseerr configuration**

```bash
git add nix/cluster/jellyseerr.nix
git commit -m "feat: configure Jellyseerr with Jellyfin external authentication"
```

---

## Phase 3: User & Group Management

### Task 6: Create Family Accounts and Groups in Authentik

**Files:**
- Modify: None (manual UI configuration)
- Create: `docs/family-accounts-setup.md` (reference guide)
- Test: Verify each family member can log in

**Interfaces:**
- Consumes: Authentik service from Task 2
- Produces: User accounts for each family member, group memberships configured

**Steps:**

- [ ] **Step 1: Plan family accounts and groups**

In `docs/family-accounts-setup.md`, document your family structure. Example:

```markdown
# Family Accounts & Groups

## Users

| Name | Authentik Username | Email | Groups |
|------|-------------------|-------|--------|
| Parent 1 | parent1 | parent1@example.com | family, admin |
| Parent 2 | parent2 | parent2@example.com | family, admin |
| Child 1 | child1 | child1@example.com | family, kids |
| Child 2 | child2 | child2@example.com | family, kids |

## Groups

| Group | Members | Purpose |
|-------|---------|---------|
| family | (all users) | Grants access to Jellyfin and Jellyseerr |
| admin | parent1, parent2 | Full system administration |
| kids | child1, child2 | Restricted content access (enforced in Jellyfin) |
```

Adjust to your actual family and access model.

- [ ] **Step 2: Create user accounts in Authentik UI**

For each family member:

1. In Authentik admin console, go to **Directory > Users** → **Create**
2. Fill in:
   - **Username:** (lowercase, no spaces, e.g., `parent1`)
   - **Name:** (human-readable, e.g., `Parent 1`)
   - **Email:** (personal or family email)
   - **Set a password:** Generate a strong one and store securely, or set to temporary and let user reset on first login

3. Save

Repeat for each family member.

- [ ] **Step 3: Create user groups in Authentik UI**

For each group (e.g., `admin`, `kids`):

1. Go to **Directory > Groups** → **Create**
2. Fill in:
   - **Name:** (e.g., `admin`)
   - **Parent:** (leave empty unless nested)

3. Save

- [ ] **Step 4: Assign users to groups**

1. Go to **Directory > Groups** → select a group (e.g., `family`)
2. Click **Edit**
3. Under **Users**, add each family member by selecting them
4. Save

Repeat for each group.

- [ ] **Step 5: Verify user login**

For each account, test:
1. Go to Jellyfin login page
2. Click the OIDC button
3. Enter username and password
4. Verify you land back in Jellyfin as that user

Take screenshots or notes if any issues arise.

- [ ] **Step 6: Document the setup**

Finalize `docs/family-accounts-setup.md` with:
- List of all accounts created
- Group assignments
- Password management strategy (e.g., stored in Proton Pass)
- How to reset a user's password (in Authentik UI)

```bash
git add docs/family-accounts-setup.md
git commit -m "docs: family account and group configuration guide"
```

---

### Task 7: Verify End-to-End SSO Flow

**Files:**
- Create: `tests/sso-verification.sh` (bash script to test OIDC endpoints)
- Test: Run the verification script; manual testing by each family member

**Interfaces:**
- Consumes: All services from Tasks 1–6
- Produces: Confidence that the SSO flow works correctly

**Steps:**

- [ ] **Step 1: Create verification test script**

Create `tests/sso-verification.sh`:

```bash
#!/bin/bash

set -e

AUTHENTIK_URL="https://authentik.example.com"
JELLYFIN_URL="https://jellyfin.example.com"
JELLYSEERR_URL="https://jellyseerr.example.com"
CLIENT_ID="<your-client-id>"
REDIRECT_URI="$JELLYFIN_URL/sso/oidc/callback"

echo "=== SSO Verification Tests ==="

# Test 1: OIDC Discovery
echo "[1/4] Testing OIDC discovery endpoint..."
DISCOVERY_URL="$AUTHENTIK_URL/application/o/jellyfin/.well-known/openid-configuration"
DISCOVERY=$(curl -s "$DISCOVERY_URL")

if echo "$DISCOVERY" | grep -q "authorization_endpoint"; then
  echo "✓ OIDC discovery endpoint is reachable"
  echo "  Issuer: $(echo "$DISCOVERY" | jq -r '.issuer')"
else
  echo "✗ OIDC discovery endpoint failed"
  exit 1
fi

# Test 2: Authentik health
echo "[2/4] Testing Authentik health..."
if curl -s -o /dev/null -w "%{http_code}" "$AUTHENTIK_URL/api/v3/core/system/" | grep -q "200\|401"; then
  echo "✓ Authentik API is reachable"
else
  echo "✗ Authentik is not responding"
  exit 1
fi

# Test 3: Jellyfin health
echo "[3/4] Testing Jellyfin health..."
if curl -s -o /dev/null -w "%{http_code}" "$JELLYFIN_URL/health" | grep -q "200"; then
  echo "✓ Jellyfin is reachable"
else
  echo "✗ Jellyfin is not responding"
  exit 1
fi

# Test 4: Jellyseerr health
echo "[4/4] Testing Jellyseerr health..."
if curl -s -o /dev/null -w "%{http_code}" "$JELLYSEERR_URL/api/v1/status" | grep -q "200\|401"; then
  echo "✓ Jellyseerr is reachable"
else
  echo "✗ Jellyseerr is not responding"
  exit 1
fi

echo ""
echo "=== All SSO infrastructure tests passed ==="
echo ""
echo "Next steps: Test login flows manually:"
echo "1. Go to $JELLYFIN_URL, click OIDC login, log in with a test account"
echo "2. Verify you land back in Jellyfin as that user"
echo "3. Go to $JELLYSEERR_URL, verify you are auto-logged-in or can log in with Jellyfin credentials"
```

- [ ] **Step 2: Run the verification script**

```bash
chmod +x tests/sso-verification.sh
./tests/sso-verification.sh
```

Expected output:
```
=== SSO Verification Tests ===
[1/4] Testing OIDC discovery endpoint...
✓ OIDC discovery endpoint is reachable
  Issuer: https://authentik.example.com
[2/4] Testing Authentik health...
✓ Authentik API is reachable
[3/4] Testing Jellyfin health...
✓ Jellyfin is reachable
[4/4] Testing Jellyseerr health...
✓ Jellyseerr is reachable

=== All SSO infrastructure tests passed ===
```

- [ ] **Step 3: Manual end-to-end testing by family members**

Have each family member:
1. Navigate to `https://jellyfin.example.com`
2. Click the OIDC login button
3. Enter their Authentik credentials
4. Verify they land in Jellyfin and can see appropriate content
5. Navigate to `https://jellyseerr.example.com`
6. Verify they are already logged in (or can log in via Jellyfin credentials)
7. Report any issues

Document any issues found and their resolutions.

- [ ] **Step 4: Commit verification script**

```bash
git add tests/sso-verification.sh
git commit -m "test: add SSO infrastructure verification script"
```

---

## Phase 3B: Forward Auth for Other Services (Future)

**When ready** to add more services (e.g., other apps without OIDC support):

- [ ] Configure Traefik forward-auth middleware to proxy to Authentik outpost
- [ ] Deploy Authentik outpost pod in cluster
- [ ] Add middleware annotation to Traefik Ingress rules

This is out of scope for this plan but documented in `docs/authentik-forward-auth.md` for later.

---

## Summary

**Deliverables:**
1. Authentik identity provider running on cluster with PostgreSQL backend
2. Jellyfin configured with OIDC login (SSO button on login page)
3. Jellyseerr integrated with Jellyfin authentication
4. Family member accounts created in Authentik with appropriate group permissions
5. Verification script confirms all components working end-to-end

**Post-Implementation Checklist:**
- [ ] All family members have tested login
- [ ] Password reset process is documented
- [ ] Backup strategy for Authentik data (PostgreSQL snapshots) is configured
- [ ] Authentik admin credentials are stored securely
- [ ] Upcoming: Configure forward-auth for other cluster services
