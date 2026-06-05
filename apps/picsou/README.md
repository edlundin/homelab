# Picsou

Self-hosted personal finance dashboard from `ghcr.io/zoeille/picsou-finance`.

Before first Argo sync, replace `POSTGRES_PASSWORD` in `.secrets.yaml` with a real random value or convert it to a sealed secret. Picsou persists generated app secrets under `/data/.secrets` when `JWT_SECRET` and `CRYPTO_ENCRYPTION_KEY` are blank.

Picsou stores sensitive financial data. Keep `picsou.oisd.io` private / protected.
