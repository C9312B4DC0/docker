# Docker Compose

## Dockhand bootstrap

Run `dockhand/compose.yaml` manually on the management host. Docker's local socket gives Dockhand control of that host. Host networking lets the host input firewall control access to the HTTPS listener.

1. Create the directory selected by `DOCKHAND_STACKS_DIR` on local disk and make it writable by UID and GID 1001. Use a dedicated directory for the Compose files Dockhand manages.
2. Provision a matching PEM certificate and key as `dockhand/tls/cert.pem` and `dockhand/tls/key.pem`. Give UID 1001 read access and restrict access to the key. The certificate must cover the listener address and be trusted by clients. The health check uses `cert.pem` as its trust bundle.
3. Keep the default loopback binding for first boot. Run `docker compose -f dockhand/compose.yaml up -d`. Use Settings → Authentication to create an admin and enable authentication before enabling management access.
4. Allow the HTTPS port from the management subnet in the host firewall. Deny it from other sources. Set `DOCKHAND_BIND` to the management interface address in a local `.env` and recreate the service. Verify that anonymous Docker API requests are denied and that an admin can sign in.
5. Back up the `dockhand-data` volume, including its database and encryption key, and the managed stack directory. Keep the recovery copy and host-specific settings private.

## Smoke test

In Dockhand, create a local stack named `dockhand-smoke` with `examples/smoke/compose.yaml`. Verify that the probe reaches healthy status and that its HTTP response inside the container is `dockhand-smoke-ok`. The probe uses container loopback and publishes no ports.
