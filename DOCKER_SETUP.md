# BarberPro - Docker Setup Guide

Run your entire BarberPro project in Docker containers!

---

## Prerequisites

- **Docker Desktop** installed ([download](https://www.docker.com/products/docker-desktop))
- **Docker Compose** (included with Docker Desktop)

Check installation:
```bash
docker --version
docker-compose --version
```

---

## Quick Start

### 1. Setup Environment File

```bash
# Copy the Docker environment template
cp .env.docker .env

# Edit .env with your Firebase credentials
# Update: FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL, etc.
```

### 2. Start All Services

```bash
# Start in background
docker-compose up -d

# Or view logs in foreground
docker-compose up
```

**Wait 30-60 seconds for services to start...**

### 3. Check Services

```bash
# List running containers
docker-compose ps

# View logs
docker-compose logs -f backend
docker-compose logs -f redis
docker-compose logs -f firestore-emulator
```

### 4. Access Services

- **Backend API:** http://localhost:3000
- **Swagger Docs:** http://localhost:3000/docs
- **Redis:** localhost:6379
- **Firestore Emulator:** localhost:8080

---

## Available Commands

### Start Services

```bash
# Start in background
docker-compose up -d

# Start specific service
docker-compose up -d backend

# Start with development profile (includes Firestore emulator)
docker-compose --profile dev up -d

# Rebuild images
docker-compose up -d --build
```

### Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (data loss!)
docker-compose down -v

# Stop specific service
docker-compose stop backend
```

### View Logs

```bash
# All services
docker-compose logs

# Follow logs
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs redis

# Last N lines
docker-compose logs --tail=50 backend
```

### Execute Commands

```bash
# Run command in backend container
docker-compose exec backend npm run build

# Interactive shell
docker-compose exec backend sh

# Check backend health
docker-compose exec backend curl http://localhost:3000/health
```

### Database & Cache

```bash
# Access Redis CLI
docker-compose exec redis redis-cli

# Common Redis commands:
# > PING                    # Test connection
# > KEYS *                  # List all keys
# > GET key_name            # Get value
# > DEL key_name            # Delete key
# > FLUSHDB                 # Clear all data
# > exit                    # Exit CLI
```

---

## Environment Configuration

Edit `.env` file to customize:

### Backend
```env
NODE_ENV=development|production
LOG_LEVEL=debug|info|warn|error
API_VERSION=v1
```

### Firebase
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
```

### Redis
```env
REDIS_HOST=redis    # Use service name for Docker
REDIS_PORT=6379
REDIS_PASSWORD=     # Set if needed
```

### JWT
```env
JWT_SECRET=your-secret-key-min-32-chars
JWT_EXPIRATION=3600
```

### Firestore Emulator (Development)
```env
# Uncomment to use local emulator instead of Firebase
FIRESTORE_EMULATOR_HOST=firestore-emulator:8080
```

---

## Development Workflow

### With Hot Reload

The backend source code is mounted as a volume, so changes are reflected:

```bash
# Start backend in watch mode
docker-compose up -d
docker-compose exec backend npm run start:dev
```

### Without Docker

If you prefer local development:

```bash
# Start only Redis and Firestore
docker-compose up -d redis firestore-emulator

# Run backend locally
cd backend
npm run start:dev
```

---

## Troubleshooting

### Port Already in Use

```bash
# Find what's using port 3000
# Windows:
netstat -ano | findstr :3000

# macOS/Linux:
lsof -i :3000

# Kill process or change port in docker-compose.yml
```

### Container Not Starting

```bash
# Check logs
docker-compose logs backend

# Restart service
docker-compose restart backend

# Rebuild from scratch
docker-compose down
docker-compose up -d --build
```

### Cannot Connect to Services

```bash
# Ensure containers are running
docker-compose ps

# Check network
docker network ls
docker network inspect barberpro_barberpro-network

# Test connectivity
docker-compose exec backend curl http://redis:6379
```

### Redis Connection Error

```bash
# Clear Redis and restart
docker-compose restart redis

# Or reset all data
docker-compose down -v
docker-compose up -d
```

---

## Production Deployment

### Build Image for Production

```bash
# Build without dev dependencies
docker build -f Dockerfile -t barberpro-backend:1.0.0 .

# Test image locally
docker run -p 3000:3000 \
  -e NODE_ENV=production \
  -e JWT_SECRET=your-secret \
  -e FIREBASE_PROJECT_ID=your-project \
  barberpro-backend:1.0.0
```

### Push to Registry

```bash
# Tag for Docker Hub
docker tag barberpro-backend:1.0.0 your-username/barberpro-backend:1.0.0

# Login to Docker Hub
docker login

# Push
docker push your-username/barberpro-backend:1.0.0
```

### Deploy to Cloud Run

```bash
# Build for Cloud Run
gcloud builds submit --tag gcr.io/PROJECT_ID/barberpro-backend

# Deploy
gcloud run deploy barberpro-backend \
  --image gcr.io/PROJECT_ID/barberpro-backend \
  --platform managed \
  --region us-central1 \
  --set-env-vars JWT_SECRET=your-secret
```

---

## Docker Compose Services

### Backend (NestJS)
- **Image:** Node.js 18 Alpine
- **Port:** 3000
- **Health Check:** Every 30s
- **Volumes:** Source code mounted for hot reload
- **Dependencies:** Redis

### Redis
- **Image:** Redis 7 Alpine
- **Port:** 6379
- **Health Check:** PING every 10s
- **Data:** Persisted in `redis_data` volume

### Firestore Emulator (dev profile only)
- **Image:** Google Cloud Firestore Emulator
- **Ports:** 8080 (Firestore), 8081 (API)
- **Data:** Persisted in `firestore_data` volume
- **Usage:** `docker-compose --profile dev up -d`

---

## Security Best Practices

1. **Don't commit .env** - Use `.env.example` template
2. **Use secrets in production** - Use Docker secrets or container orchestration
3. **Keep images updated** - Regularly pull latest base images
4. **Run as non-root** - Backend runs as `nodejs` user
5. **Use healthchecks** - Containers have built-in health checks
6. **Network isolation** - Services communicate on isolated `barberpro-network`

---

## Performance Tips

1. **Use named volumes** - Faster than bind mounts
2. **Limit logs** - Configure log rotation
3. **Resource limits** - Set memory/CPU limits
4. **Multi-stage builds** - Smaller images (used in Dockerfile)
5. **Alpine images** - Smaller base images

---

## Next Steps

1. **Setup Firebase credentials** in `.env`
2. **Run `docker-compose up -d`**
3. **Test API:** `curl http://localhost:3000/docs`
4. **Start developing!**

---

**Document:** BarberPro Docker Setup Guide  
**Version:** 1.0  
**Date:** December 9, 2025
