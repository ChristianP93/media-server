# Guide: Adding Indexers to Prowlarr

Prowlarr manages indexers (torrent trackers) and automatically syncs them with Sonarr and Radarr.

---

## Accessing Prowlarr

1. Open http://localhost:9696 (or http://prowlarr.media.local)
2. On first access, create an admin account

---

## Types of Indexers

| Type | Description | Examples |
|------|-------------|----------|
| **Public** | Accessible to everyone, no registration | 1337x, RARBG, YTS, The Pirate Bay |
| **Semi-Private** | Require free registration | TorrentGalaxy, LimeTorrents |
| **Private** | Invite only, require ratio maintenance | IPTorrents, TorrentLeech, HD-Torrents |

---

## Adding a Public Indexer

### Step 1: Go to Indexers
- Side menu → **Indexers**
- Click **+ Add Indexer**

### Step 2: Search for the Indexer
- In the search bar, type the name (e.g., "1337x")
- Click on the indexer from the list

### Step 3: Configure
For public indexers, configuration is minimal:

```
Name: 1337x (or leave default)
Enable RSS: ✓ (for automatic searches)
Enable Automatic Search: ✓
Enable Interactive Search: ✓
```

### Step 4: Test and Save
- Click **Test** to verify the connection
- If test passes, click **Save**

### Recommended Public Indexers

| Indexer | Content | Notes |
|---------|---------|-------|
| **1337x** | General | Very reliable |
| **YTS** | Movies (small sizes) | Great for limited storage |
| **EZTV** | TV Shows | Specialized in TV |
| **Nyaa** | Anime | Best for anime |
| **RuTracker** | General | Russian, excellent selection |

---

## Adding a Private Indexer

Private indexers require authentication credentials.

### Step 1: Get Credentials from the Tracker

Log into the private tracker website and find:
- **API Key** (preferred) - Usually in: Profile → Settings → API
- **Cookie** - Alternative if API not available
- **Username/Password** - Some trackers require this

### Step 2: Add the Indexer
- **Indexers** → **+ Add Indexer**
- Search for the tracker name (e.g., "IPTorrents")

### Step 3: Configure Authentication

#### Method 1: API Key (Recommended)
```
API Key: [paste your API key]
```

#### Method 2: Cookie
```
Cookie: [paste the session cookie]
```

To get the cookie:
1. Log into the tracker in your browser
2. Open DevTools (F12) → Application → Cookies
3. Copy the session cookie value

#### Method 3: Username/Password
```
Username: [your username]
Password: [your password]
```

### Step 4: Additional Settings

```
Enable RSS: ✓
Enable Automatic Search: ✓
Enable Interactive Search: ✓
Download Client: (leave empty to use default)
```

### Step 5: Test and Save
- Click **Test**
- If it fails, verify credentials
- If it passes, click **Save**

---

## Configuring FlareSolverr (Anti-Cloudflare)

Some indexers are protected by Cloudflare. FlareSolverr automatically solves CAPTCHAs.

### Step 1: Add FlareSolverr as Proxy
- **Settings** → **Indexers** → **+** (under "Indexer Proxies")
- Select **FlareSolverr**

### Step 2: Configure
```
Name: FlareSolverr
Tags: (leave empty to apply to all)
Host: http://flaresolverr:8191
Request Timeout: 60
```

### Step 3: Save
- Click **Test** then **Save**

### Step 4: Assign to Indexers
When adding a Cloudflare-protected indexer:
```
Tags: flaresolverr (if you used tags)
```
Or FlareSolverr will be used automatically if you didn't set tags.

---

## Syncing with Sonarr and Radarr

Once indexers are added, sync them with the apps.

### Step 1: Go to Apps
- **Settings** → **Apps**

### Step 2: Add Sonarr
- Click **+** → **Sonarr**
- Configure:
```
Name: Sonarr
Sync Level: Full Sync
Prowlarr Server: http://prowlarr:9696
Sonarr Server: http://sonarr:8989
API Key: [Sonarr API key - see ./scripts/stack.sh creds]
```
- **Test** → **Save**

### Step 3: Add Radarr
- Click **+** → **Radarr**
- Configure:
```
Name: Radarr
Sync Level: Full Sync
Prowlarr Server: http://prowlarr:9696
Radarr Server: http://radarr:7878
API Key: [Radarr API key - see ./scripts/stack.sh creds]
```
- **Test** → **Save**

### Step 4: Sync
- **Settings** → **Apps** → **Sync App Indexers**
- Indexers will automatically appear in Sonarr/Radarr

---

## Troubleshooting

### "Connection refused" or "Timeout"
- Verify the indexer is online
- Try manually accessing the tracker website
- If protected by Cloudflare, configure FlareSolverr

### "Unauthorized" or "Invalid credentials"
- Regenerate API key on the tracker website
- Verify the cookie hasn't expired
- Some trackers require IP whitelisting

### "No results found"
- The indexer might not have that content
- Try a manual search on the tracker website
- Check category filters

### Indexers don't appear in Sonarr/Radarr
- Go to Prowlarr → Settings → Apps
- Click **Sync App Indexers**
- Verify Sync Level is "Full Sync"

---

## Recommended Indexer List

### Public (No Registration)
- **1337x** - General, very reliable
- **YTS** - Compressed movies, great quality/size ratio
- **EZTV** - TV Shows
- **Nyaa** - Anime (Japanese)
- **RuTracker** - General, excellent selection

### Semi-Private (Free Registration)
- **TorrentGalaxy** - General
- **LimeTorrents** - General

### Private (Invite Only)
- **IPTorrents** - General, easy to maintain
- **TorrentLeech** - General
- **HD-Torrents** - High quality
- **BroadcasTheNet** - TV Shows (hard to get in)
- **PassThePopcorn** - Movies (very exclusive)

---

## Privacy Notes

- Use a **VPN** when downloading torrents
- Private trackers monitor your ratio (upload/download)
- Don't share your credentials or API keys
- Some ISPs block torrent sites - use alternative DNS (1.1.1.1, 8.8.8.8)
