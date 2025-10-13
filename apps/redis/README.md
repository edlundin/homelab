# Redis

Standalone Redis instance for caching and data storage across multiple applications in the cluster.

## Components

- **PersistentVolumeClaim**: 1Gi storage for Redis data persistence
- **Deployment**: Single Redis instance with Alpine Linux
- **Service**: ClusterIP service exposing Redis on port 6379

## Configuration

- **Image**: `redis:7-alpine`
- **Persistence**: Append-only file (AOF) enabled
- **Memory**: 256MB limit with LRU eviction policy
- **Resources**: 
  - Requests: 128Mi RAM, 50m CPU
  - Limits: 256Mi RAM, 200m CPU
- **Security**: Non-root user (999), dropped capabilities

## Connection

Applications can connect to Redis at: `redis://redis.redis.svc.cluster.local:6379`

### Database Usage
- **Database 0**: Available for SearXNG and other applications
- **Databases 1-15**: Available for other services as needed

## Storage

Uses the `local-path` storage class for persistent data storage.

## Health Checks

- **Liveness**: Redis ping command every 10 seconds
- **Readiness**: Redis ping command every 5 seconds

## Security

- Non-root container execution
- Read-only root filesystem disabled (Redis needs to write to /data)
- All capabilities dropped except required ones
- Security context with proper user/group ownership