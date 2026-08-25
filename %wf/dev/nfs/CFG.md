<!-- 2026-08-25-Tue-W34 -->

## NFSv4 server setup (Arch, PC side)

```bash
# /etc/exports
/srv/nfs/share 192.168.1.0/24(rw,sync,no_subtree_check,fsid=0,no_root_squash)
```

```bash
sudo mkdir -p /srv/nfs/share
sudo systemctl enable --now nfs-server.service
sudo systemctl enable --now rpcbind.service   # v4 mostly doesn't need it, but harmless
sudo exportfs -rav
sudo exportfs -v   # verify
```

Static IP on the eth interface (PC side), matching your 192.168.1.x scheme:
```
# /etc/systemd/network/eth-direct.network (or NetworkManager equivalent)
[Match]
Name=<eth-iface>

[Network]
Address=192.168.1.2/24
```

Firewall (PC), if you run one — allow NFSv4 port only:
```bash
sudo ufw allow from 192.168.1.0/24 to any port 2049 proto tcp
```
NFSv4 is single-port (2049) — no need to open mountd/statd/lockd ports like v3.

## Laptop side (client)

```bash
sudo mkdir -p /mnt/pc-share
sudo mount -t nfs4 192.168.1.2:/ /mnt/pc-share
```

fstab entry:
```
192.168.1.2:/ /mnt/pc-share nfs4 _netdev,noauto,x-systemd.automount 0 0
```

## Related — brief

- **Auth**: default setup trusts IP/UID from client (`no_root_squash` is convenient on a private link, but is exactly what you should drop once on shared LAN — squash root, map UIDs)
- **Encryption**: NFSv4 traffic is plaintext by default — irrelevant on direct cable, matters on shared router
- **Kerberos (sec=krb5p)**: proper NFSv4 auth+encryption; heavier setup cost
- **Firewall scoping**: once on router, restrict 2049 to laptop's specific IP, not whole subnet
- **idmapd**: NFSv4 needs matching domain in `/etc/idmapd.conf` on both ends or you'll get nobody:nogroup mapping issues
- **WireGuard tunnel alternative**: run NFS over a wg0 point-to-point instead of bare LAN — sidesteps krb5 complexity, gets encryption + auth for free

Say which of these you want expanded once you've decided what matters for your router setup.


---
wg0 and sshfs are not the same — different trust model and perf profile.

**sshfs**
- FUSE, single TCP stream, userspace → higher latency, syscall overhead per op
- Auth: SSH keys, per-mount
- No separate daemon config; auth+transport bundled in the ssh session
- Struggles under concurrent/parallel IO (single stream head-of-line blocking)

**NFSv4 over wg0**
- wg0 only replaces the *transport* — NFS protocol itself unchanged: still kernel-space client/server, still supports parallel RPCs, real page-cache-backed IO, proper locking semantics
- WireGuard: kernel-space, UDP, negligible overhead (~few % vs raw link), noise protocol crypto — auth is asymmetric keys at the tunnel level, decoupled from per-file access control (which NFS/exports still handles)
- End result: same NFSv4 performance characteristics you already have on direct cable, just tunneled — sshfs is a fundamentally slower FUSE passthrough by comparison

So: wg0+NFS ≈ your current setup, encrypted, minimal perf loss. sshfs ≈ different (slower) filesystem semantics entirely, not a drop-in.

## Related — brief
- **NFS over TLS (nfs 6.x kernels)**: newer alternative to krb5p, avoids kerberos infra, also avoids needing wg0 — worth checking your kernel version
- **wg0 setup cost**: still needs keypairs + peer config on both ends, roughly comparable effort to krb5p
- **MTU/fragmentation**: wg adds ~60B overhead, can matter for jumbo frames if you use them

Want the NFS-over-TLS option expanded, or the wg0 config itself?

---
Kernel 6.13 supports it (feature landed 6.5+). Good — mTLS gives you transport auth too, so you can layer that with UID mapping cleanly.

## NFS over mTLS

Generate CA + certs (self-signed CA is fine for LAN):
```bash
# on either machine
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -subj "/CN=home-ca"

# server cert
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr -subj "/CN=pc-nfs"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 3650 -sha256

# client cert
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr -subj "/CN=laptop-nfs"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 3650 -sha256
```

**PC (server):**
```bash
sudo pacman -S ktls-utils
sudo mkdir -p /etc/nfs-certs
sudo cp ca.crt server.crt server.key /etc/nfs-certs/
sudo chmod 600 /etc/nfs-certs/server.key
```

`/etc/tlshd.conf`:
```ini
[authenticate.server]
x509.truststore= /etc/nfs-certs/ca.crt
x509.certificate= /etc/nfs-certs/server.crt
x509.private_key= /etc/nfs-certs/server.key
```

`/etc/exports`:
```
/srv/nfs/share 192.168.1.0/24(rw,sync,no_subtree_check,fsid=0,sec=sys,xprtsec=mtls)
```

```bash
sudo systemctl enable --now tlshd.service
sudo exportfs -rav
```

**Laptop (client):**
```bash
sudo pacman -S ktls-utils
sudo mkdir -p /etc/nfs-certs
sudo cp ca.crt client.crt client.key /etc/nfs-certs/
sudo chmod 600 /etc/nfs-certs/client.key
```

`/etc/tlshd.conf`:
```ini
[authenticate.client]
x509.truststore= /etc/nfs-certs/ca.crt
x509.certificate= /etc/nfs-certs/client.crt
x509.private_key= /etc/nfs-certs/client.key
```

```bash
sudo systemctl enable --now tlshd.service
sudo mount -t nfs4 -o xprtsec=mtls 192.168.1.2:/ /mnt/pc-share
```

fstab:
```
192.168.1.2:/ /mnt/pc-share nfs4 xprtsec=mtls,_netdev,noauto,x-systemd.automount 0 0
```

## Root squash / UID mapping

Note: TLS is transport-only — doesn't touch auth/uid mapping (span 4-1). Handle separately.

**Option A — squash (simplest):** drop `no_root_squash` from exports:
```
/srv/nfs/share 192.168.1.0/24(rw,sync,no_subtree_check,fsid=0,root_squash,sec=sys,xprtsec=mtls)
```
Root on laptop → mapped to `nobody:nogroup` on PC. Non-root UIDs still pass through as-is (need matching UID/GID on both sides or you get permission mismatches).

**Option B — explicit UID mapping (idmapd, `sec=sys`):**
```ini
# /etc/idmapd.conf, both machines — must match
[General]
Domain = home.lan
```
Only affects *name* mapping (owner shown as username), not permission enforcement — `sec=sys` still trusts client-supplied UIDs numerically.

**Option C — all_squash (tightest):**
```
/srv/nfs/share 192.168.1.0/24(rw,sync,no_subtree_check,fsid=0,all_squash,anonuid=1000,anongid=1000,sec=sys,xprtsec=mtls)
```
Every laptop UID → single fixed PC UID. Good if laptop is single-user and you don't need per-user separation on the share.

Given single-user laptop → PC access, **all_squash + anonuid/anongid** is probably the right fit — flat, no UID-sync maintenance burden across machines.

## Related — brief
- **`sec=sys` vs `sec=krb5`**: mTLS auths the *transport*, not the RPC user identity — krb5 still the only way to cryptographically auth per-user; irrelevant here if single-user
- **Certificate renewal**: 3650-day certs above = no rotation hassle, but no revocation path either
- **`xprtsec=tls` vs `mtls`**: tls-only skips client cert (server-auth only) — simpler, but client not authenticated at transport layer


---
**No — stick with NFSv4.** SMB/CIFS solves a different problem than what you've built here.

## Why not switch

- **You already have mTLS+krb5-equivalent auth working.** SMB3 does have encryption (`seal`) but Samba's TLS/cert tooling on Linux-to-Linux is far less mature than the native kernel `xprtsec` path you just set up — you'd be trading a clean kernel-native solution for a userspace Samba layer.
- **UID mapping**: NFS's `all_squash`/`anonuid` is exactly the right primitive for single-user Linux↔Linux. SMB's identity model (SIDs, `idmap.conf`, `vfs_shadow_copy` cruft) is built for mixed Windows/Linux environments — pure overhead here.
- **Performance**: NFSv4 client is Linux-kernel-native (page cache integration, direct I/O paths). SMB client (`cifs.ko`) works but historically has had weaker throughput/latency on Linux-to-Linux vs NFS, especially with many small files.
- **Locking/semantics**: NFSv4 has POSIX-correct locking; SMB's oplock/lease model is a layer of translation that doesn't map perfectly onto POSIX apps.

CIFS/SMB earns its keep when a Windows box is in the mix, or you want easy discovery/browsing (Nautilus/Explorer style). Neither applies to a Linux PC ↔ Linux laptop link.

## Related — brief
- **9P (Plan9)**: another option if you were doing VM passthrough — not relevant to bare-metal LAN
- **SSHFS**: already covered — slower FUSE path, not competitive here either
- **When SMB *would* win**: dual-boot Windows partition, or media server also serving phones/TVs (better client compatibility than NFS)

Continue with the NFS+mTLS setup as-is.
