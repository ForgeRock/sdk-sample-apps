# Docker Development Environment

This Docker setup provides a production-optimized environment for running all JavaScript sample applications in the `sdk-sample-apps/javascript` folder. Each application can be started with a simple Docker command that handles all dependencies, builds, and configurations automatically.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Available Applications](#available-applications)
- [Environment Configuration](#environment-configuration)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

---

## Prerequisites

- **Docker** (v20.10+)
- **Docker Compose** (v2.0+)
- **Git** (to clone the repository)

Verify your installation:

```bash
docker --version
docker-compose --version
```

---

## Quick Start

### 1. Configure Environment Variables (Optional)

Environment variables are **optional** - the Docker setup works out of the box with default values. However, to connect to your PingOne Advanced Identity Cloud, PingAM, or PingOne DaVinci instance, you'll need to configure them.

**Two ways to configure:**

**Option A: Root-level configuration (Recommended for API)**
```bash
# Copy the example file to the javascript/ directory
cp .env.example .env
# Edit .env with your PingOne/PingAM configuration
```
This automatically configures the todo-api backend.

**Option B: App-specific configuration (For frontend builds)**
```bash
# For specific apps, copy their .env.example file
cp reactjs-todo/.env.example reactjs-todo/.env
# Edit with your configuration
```
This bakes configuration into the frontend build.

### 2. Run an Application

Use Docker Compose profiles to start specific applications:

```bash
# React Todo App (with API)
docker-compose --profile reactjs-todo up

# Angular Todo App (with API)
docker-compose --profile angular-todo up

# Embedded Login (standalone)
docker-compose --profile embedded-login up

# Central Login OIDC (standalone)
docker-compose --profile central-login up

# React Todo DaVinci (with API)
docker-compose --profile reactjs-davinci up

# Angular Todo DaVinci (with API)
docker-compose --profile angular-davinci up

# Embedded Login DaVinci (standalone)
docker-compose --profile embedded-davinci up
```

### 3. Access the Application

Once the containers are running, access the applications at:

- **React/Angular/Embedded/Central Login apps**:
  - HTTPS: `https://localhost:8443`
  - HTTP: `http://localhost:8080`
- **Embedded Login DaVinci**:
  - `http://localhost:5829` or `https://localhost:5829`
- **Todo API** (when running with todo apps):
  - `http://localhost:9443`

**Note:** For HTTPS, you'll see a browser warning about self-signed certificates. This is expected - click "Advanced" and "Proceed to localhost" (exact wording varies by browser).

---

## Available Applications

### Applications with Todo API

These applications require the `todo-api` backend and will start it automatically:

| Profile | Application | Description | Ports |
|---------|-------------|-------------|-------|
| `reactjs-todo` | React Todo App | React 18 Todo app with PingOne AIC/AM integration | 8443 (HTTPS), 8080 (HTTP), 9443 (API) |
| `angular-todo` | Angular Todo App | Angular 17 Todo app with PingOne AIC/AM integration | 8443 (HTTPS), 8080 (HTTP), 9443 (API) |
| `reactjs-davinci` | React Todo DaVinci | React 18 Todo app with PingOne DaVinci flows | 8443 (HTTPS), 8080 (HTTP), 9443 (API) |
| `angular-davinci` | Angular Todo DaVinci | Angular 18 Todo app with PingOne DaVinci flows | 8443 (HTTPS), 8080 (HTTP), 9443 (API) |

### Standalone Applications

These applications run independently without the API:

| Profile | Application | Description | Ports |
|---------|-------------|-------------|-------|
| `embedded-login` | Embedded Login | Vanilla JS embedded login with PingOne AIC/AM | 8443 (HTTPS), 8080 (HTTP) |
| `central-login` | Central Login OIDC | Vanilla JS centralized OIDC login with PingOne AIC/AM | 8443 (HTTPS), 8080 (HTTP) |
| `embedded-davinci` | Embedded Login DaVinci | Vite-based embedded login with PingOne DaVinci | 5829 |

---

## Environment Configuration

### Environment Variables Overview

Environment variables are **optional** - applications will build and run with sensible defaults. However, to connect to your actual PingOne/PingAM instance, you'll need to configure them.

**Two configuration approaches:**

1. **Root-level `.env`** (in `javascript/` directory) - Automatically loaded by Docker Compose, used for todo-api runtime configuration
2. **App-specific `.env`** (in each app directory) - Baked into frontend builds at build time

The specific variables depend on whether you're using PingOne AIC/AM or PingOne DaVinci.

#### For PingOne AIC/AM Applications

Create a `.env` file in the app directory with these variables:

```bash
# PingOne Advanced Identity Cloud / PingAM Configuration
SERVER_URL=https://your-instance.forgeblocks.com/am
REALM_PATH=/alpha
WEB_OAUTH_CLIENT=your-oauth-client-id
JOURNEY_LOGIN=Login
JOURNEY_REGISTER=Registration
DEBUGGER_OFF=false

# For Todo apps only
APP_URL=https://localhost:8443
API_URL=http://localhost:9443
```

#### For PingOne DaVinci Applications

Create a `.env` file in the app directory with these variables:

```bash
# PingOne DaVinci Configuration
VITE_DAVINCI_URL=https://auth.pingone.com/<environment-id>/davinci/v1
VITE_COMPANY_ID=your-company-id
VITE_API_KEY=your-api-key
VITE_POLICY_ID=your-policy-id
```

**Important:**
- Environment variables are optional - apps will build/run without them (useful for testing Docker setup)
- To connect to your PingOne/PingAM instance, configure `.env` files with your actual values
- Root-level `.env` (javascript/.env) is automatically loaded by Docker Compose for the API
- App-specific `.env` files are copied into builds if they exist
- Never commit `.env` files to version control
- Use `.env.example` as a template (available at root and in each app directory)

---

## Usage Examples

### Starting Applications

#### React Todo App with API

```bash
# Start the application
docker-compose --profile reactjs-todo up

# Start in detached mode (background)
docker-compose --profile reactjs-todo up -d

# View logs
docker-compose logs -f reactjs-todo

# Stop the application
docker-compose --profile reactjs-todo down
```

#### Multiple Applications

You can run multiple applications simultaneously by specifying multiple profiles:

```bash
# Run both embedded login demos
docker-compose --profile embedded-login --profile embedded-davinci up
```

**Note:** Be aware of port conflicts when running multiple applications.

### Rebuilding After Changes

If you modify code or environment variables that affect the build:

```bash
# Rebuild and restart
docker-compose --profile reactjs-todo up --build

# Force rebuild without cache
docker-compose --profile reactjs-todo build --no-cache
docker-compose --profile reactjs-todo up
```

### Stopping Applications

```bash
# Stop services (preserves volumes)
docker-compose --profile reactjs-todo down

# Stop and remove volumes (clears database)
docker-compose --profile reactjs-todo down -v

# Stop all running services
docker-compose down
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f reactjs-todo
docker-compose logs -f todo-api

# Last 100 lines
docker-compose logs --tail=100 reactjs-todo
```

---

## Troubleshooting

### Build Errors

#### "Cannot find module" or dependency errors

**Solution:** Clear Docker cache and rebuild:

```bash
docker-compose build --no-cache --pull
docker-compose up
```

#### "COPY failed" or file not found errors

**Solution:** Ensure you're running commands from the `javascript/` directory:

```bash
cd sdk-sample-apps/javascript
docker-compose --profile reactjs-todo up
```

### Runtime Errors

#### "Connection refused" to API

**Problem:** The frontend app cannot connect to the todo-api.

**Solution:**
1. Check that `API_URL` in your `.env` file points to `http://localhost:9443`
2. Verify the todo-api container is healthy:
   ```bash
   docker-compose ps
   ```
3. Check API logs:
   ```bash
   docker-compose logs todo-api
   ```

#### "Invalid redirect URI" or OAuth errors

**Problem:** Mismatch between configured OAuth client and application URL.

**Solution:**
1. Verify `APP_URL` in `.env` matches your access URL (e.g., `https://localhost:8443`)
2. Configure your PingOne/PingAM OAuth client with the correct redirect URIs:
   - `https://localhost:8443/callback`
   - `http://localhost:8080/callback`

#### Browser shows "Your connection is not private"

**Problem:** Self-signed SSL certificate warning (expected behavior).

**Solution:**
- Click "Advanced" → "Proceed to localhost" (Chrome)
- Click "Advanced" → "Accept the Risk and Continue" (Firefox)
- This is safe for local development

### Port Conflicts

#### "Port is already allocated"

**Problem:** Another service is using the required port.

**Solution:**
1. Stop other applications using the port
2. Or modify `docker-compose.yml` to use different ports:
   ```yaml
   ports:
     - "9443:8443"  # Map external port 9443 to container port 8443
   ```

### Data Persistence

#### Todos not persisting between restarts

**Problem:** Database volumes may have been deleted.

**Solution:** Avoid using `docker-compose down -v` unless you want to clear data:

```bash
# Preserve data
docker-compose --profile reactjs-todo down

# Clear data (when needed)
docker-compose --profile reactjs-todo down -v
```

---

## Advanced Usage

### Building Individual Dockerfiles

You can build and run containers without docker-compose:

```bash
# Build React app
docker build -f Dockerfile.react --build-arg APP_NAME=reactjs-todo -t reactjs-todo .

# Run React app (env vars are baked into build, no runtime env needed)
docker run -p 8443:8443 -p 8080:8080 reactjs-todo

# Build and run API (can pass env vars if needed)
docker build -f Dockerfile.api -t todo-api .
docker run -p 9443:9443 -e PORT=9443 -e NODE_ENV=production todo-api
# Or use --env-file if you have a .env file:
# docker run -p 9443:9443 --env-file .env todo-api
```

### Custom Network Configuration

To integrate with existing Docker networks:

```yaml
# In docker-compose.yml
networks:
  ping-sdk-network:
    external: true
    name: my-existing-network
```

### Development Mode with Volume Mounting

For development with live code changes, you can mount source directories:

```yaml
# Add to service definition in docker-compose.yml
volumes:
  - ./reactjs-todo:/app/reactjs-todo
  - /app/reactjs-todo/node_modules  # Prevent overwriting
```

**Note:** The provided Dockerfiles are optimized for production. For active development with hot-reload, consider using the native `npm run` commands instead.

### Inspecting Containers

```bash
# Access container shell
docker exec -it reactjs-todo sh
docker exec -it todo-api sh

# Inspect container details
docker inspect reactjs-todo

# View container resource usage
docker stats
```

### Cleaning Up

```bash
# Remove all stopped containers
docker-compose down

# Remove all unused images
docker image prune -a

# Full cleanup (containers, images, volumes, networks)
docker system prune -a --volumes
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  Frontend Containers (React/Angular/Vanilla)        │
│  - Nginx serving static files                       │
│  - Self-signed SSL certificates                     │
│  - Ports: 8443 (HTTPS), 8080 (HTTP), 5829 (Vite)   │
└──────────────────┬──────────────────────────────────┘
                   │ HTTP API calls
                   ▼
┌─────────────────────────────────────────────────────┐
│  todo-api Container (Express.js)                    │
│  - Node.js runtime                                  │
│  - PouchDB database                                 │
│  - Port: 9443                                       │
│  - Persistent volumes for data                      │
└─────────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  PingOne AIC / PingAM / PingOne DaVinci             │
│  - OAuth/OIDC authentication                        │
│  - User management                                  │
│  - Journey/Flow orchestration                       │
└─────────────────────────────────────────────────────┘
```

### Build Process

1. **Build Stage:**
   - Copies source code and package files
   - Installs all dependencies with `npm ci`
   - Runs production builds (webpack/Angular CLI/Vite)
   - Outputs static files

2. **Runtime Stage:**
   - Nginx Alpine image (lightweight)
   - Copies only built assets
   - Generates self-signed certificates
   - Configures HTTPS and HTTP servers
   - Serves static files with SPA routing

---

## Security Considerations

1. **Self-Signed Certificates:** Only use for development. In production, use valid SSL certificates from a Certificate Authority.

2. **Environment Variables:** Never commit `.env` files. Use secrets management in production.

3. **Network Isolation:** The `ping-sdk-network` isolates containers. Expose only necessary ports.

4. **Non-Root User:** The API container runs as a non-root user for security.

5. **Production Deployment:** These Dockerfiles are production-optimized but may need additional hardening for public deployments (rate limiting, WAF, etc.).

---

## Additional Resources

- [ForgeRock JavaScript SDK Documentation](https://backstage.forgerock.com/docs/sdks/latest/index.html)
- [PingOne DaVinci Documentation](https://docs.pingidentity.com/bundle/davinci)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## Support

For issues specific to:
- **Docker setup:** Open an issue in this repository
- **Sample applications:** See the main README.md in each app directory
- **ForgeRock/Ping SDK:** Consult the official documentation or support channels

---

**Last Updated:** 2025-11-07
