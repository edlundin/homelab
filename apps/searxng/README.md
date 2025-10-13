# SearXNG

SearXNG is a free internet metasearch engine which aggregates results from various search services and databases. Users are neither tracked nor profiled.

## Deployment

This SearXNG instance is deployed on the K3s cluster and accessible at:
- **URL**: https://search.oisd.io

## Components

- **ConfigMap**: SearXNG configuration with security settings and engine preferences
- **Deployment**: SearXNG application pods (2 replicas for HA)
- **Service**: ClusterIP service in `searxng` namespace
- **External Service**: Routes traffic from `traefik` namespace to SearXNG service
- **IngressRoute**: HTTPS ingress configuration for `search.oisd.io`

## Configuration

- **Image**: `searxng/searxng:latest`
- **Replicas**: 2 (for high availability)
- **Resources**: 
  - Requests: 256Mi RAM, 100m CPU
  - Limits: 512Mi RAM, 500m CPU
- **Port**: 8080
- **Security**: Non-root user (977), dropped capabilities, security context

## Features

- Privacy-focused search with no user tracking
- Aggregates results from multiple search engines
- Rate limiting and security headers via Traefik middleware chain
- Health checks for reliability
- TLS termination with wildcard certificate

## Engines Enabled

- Brave, DuckDuckGo, Google, Bing, Startpage, Wikipedia
- Disabled engines: Yahoo, Wikidata, currency converter (for performance)

## Redis Cache

- **Backend**: Standalone Redis 7 Alpine with persistent storage
- **Connection**: `redis://redis.redis.svc.cluster.local:6379/0`
- **Benefits**: Faster search results, reduced load on search engines
- **Storage**: 1Gi persistent volume with AOF persistence
- **Database**: Uses Redis database 0

## Networking

- **Main Service**: `searxng.searxng.svc.cluster.local:8080`
- **External Service**: `searxng-external.traefik.svc.cluster.local:8080` 
- **Redis Cache**: `redis.redis.svc.cluster.local:6379`
- **Ingress**: `search.oisd.io` (HTTPS with wildcard TLS)
- **Middlewares**: `default-chain` (security headers + rate limiting)

## Monitoring

Health checks are available at `/healthz` endpoint.

## Updates

The deployment uses the `latest` tag and will be updated automatically by ArgoCD when new images are available.

## Security

- HTTPS only via TLS redirect and wildcard certificate
- Security headers via Traefik middleware (XSS protection, content sniffing prevention, etc.)
- Rate limiting (50 requests/second average, 100 burst)
- No user tracking or profiling
- Container security hardening (non-root, dropped capabilities)