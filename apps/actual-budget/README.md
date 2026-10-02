# Actual Budget

Actual runs as one replica with the complete server data directory mounted at
`/data` on a Longhorn PVC. The PVC is enrolled in Longhorn's `default` recurring
job group, which includes the weekly backup job. The server uses the same image
digest and upload limits as the previous Docker Compose instance.

## Migration status

On 2026-10-02, a stopped-server archive of the VM's
`/opt/oisd/actualbudget/actual-data` and `docker-compose.yml` was saved outside
Git at `/Users/edlundin/Backups/actual-budget/actual-budget-full-2026-10-02.tar.gz`
and `/root/actual-budget-full-2026-10-02.tar.gz` on the `actual-budget` VM. Its
SHA-256 is
`e697bfbb5258b44bcd6a72d5ac33d1e91cae6256baba3e61e0f351d0341baf77`.
The archive contains the account database, including two GoCardless secret
records, and all synchronized budget files. Its SQLite databases passed
integrity checks. Treat it as sensitive: it contains account and bank connection
data.

The user chose this saved archive for cutover, accepting that changes made after
it was created may be missing. The old VM is now unreachable, so a fresh final
copy could not be made. The archive has been restored to the k3s PVC; all six
restored files hash-match the archive. The k3s pod is healthy, and
`https://budget.ison-mirfak.ts.net/login`,
`https://budget.oisd.dev/login`, and `https://budger.oisd.dev/login` return HTTP
200. The Actual Budget and Traefik extras Argo CD Applications are Synced and
Healthy at commit `dc6020a`.

The old Actual Budget VM still times out over SSH and direct HTTP, so its
container could not be stopped. The k3s service is the active instance. Do not
use or route traffic to the old VM if it becomes reachable; it may contain
changes that are absent from the selected archive and current k3s data. Keep it
isolated until it can be safely retired.
