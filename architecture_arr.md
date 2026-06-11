




**1. User Requests (The Front-End)**
* **Overseerr**: A web interface that allows you, your friends, or your family to browse for movies and TV shows and click a button to request them.
* **Jellyseerr**: A modified version of Overseerr specifically built to integrate directly with Jellyfin and Emby media servers.
* **Seer**: A mored interface that merge Overseerr and Jellyseerr.

**2. Core Media Management (The "Arrs")**
* **Sonarr**: The brain for TV shows. It monitors upcoming episodes, grabs them when they release, and renames/organizes the files.
* **Radarr**: The brain for Movies. It monitors for releases in your desired quality (like 4K or 1080p) and organizes them.
* **Lidarr**: The brain for Music. It tracks artists, albums, and singles, organizing audio files and fetching album art.
* **Readarr**: The brain for written media. It tracks and organizes e-books and audiobooks.
* **Chaptarr**: A newer, highly anticipated fork/replacement for Readarr, built to modernize how self-hosted servers handle audiobooks and e-books.

**3. Search and Bypass**
* **Prowlarr**: A central search hub. Instead of setting up torrent sites in every single Arr app, you put them in Prowlarr once, and it syncs them to all the Arrs automatically.
* **Byparr**: A background proxy tool. When Prowlarr tries to search a website but gets blocked by a Cloudflare captcha or anti-bot screen, Byparr solves the check and lets the search continue.

**4. Download Clients**
* **qBittorrent**: A highly popular, fast, open-source application for downloading torrents.
* **Deluge**: Another lightweight open-source torrent downloader, favored by some for its ability to handle massive amounts of torrents simultaneously.
* **SABnzbd**: A downloader specifically for Usenet (an alternative to torrenting that uses decentralized newsgroup servers to download files at max internet speeds).

**5. Privacy Tunnel**
* **Gluetun**: A lightweight VPN client running in a container. You route your download clients (like qBittorrent) through Gluetun so your real IP address is hidden from your Internet Service Provider.

**6. Automation Utilities**
* **Bazarr**: A companion application that scans your downloaded movies and TV shows and automatically downloads matching subtitles in your preferred languages.
* **Recyclarr**: A command-line tool that automatically updates Sonarr and Radarr with the best community-tested quality profiles, ensuring you do not download bloated or poorly encoded files.
* **Cleanuparr**: A digital janitor. If a download gets stuck at 99%, or if a torrent turns out to be fake, Cleanuparr deletes the bad file and tells Sonarr/Radarr to try downloading a different one.

**7. Manga and Comics**
* **Tranga**: An automated tracker and downloader built specifically for manga. It monitors scanlation websites and downloads new chapters as soon as they are translated.
* **Komga**: A specialized media server designed entirely for reading comic books and manga. It organizes your downloaded archives into readable galleries.
* **Suwayomi**: A self-hosted server based on the popular Tachiyomi app. It allows you to download, sync, and read manga across all your mobile devices and browsers.

**8. Media Presentation**
* **Jellyfin**: The main media server. It acts like your own personal Netflix, taking all the raw video and audio files from your hard drive and streaming them cleanly to your TV, phone, or computer.


```mermaid
flowchart TB
    %% Global Nodes
    User([👤 End User])
    Internet(((🌐 Internet)))

    %% Groupings
    subgraph Requests [1. User Requests]
        direction LR
        Seer[Seer <br> <small>Overseerr / Jellyseerr</small>]
    end

    subgraph Presentation [2. Media Servers]
        Jellyfin[Jellyfin]
    end

    subgraph Manga [3. Manga Subsystem]
        direction TB
        Tranga[Tranga]
        Komga[Komga]
        Suwayomi[Suwayomi]
        
        Komga -.->|Read Library| Tranga
        Komga -.->|Read Library| Suwayomi
    end

    subgraph Arrs [4. Core Media Management]
        direction TB
        Sonarr[📺 Sonarr]
        Radarr[🎬 Radarr]
        Lidarr[🎵 Lidarr]
        Readarr[📚 Readarr]
        Chaptarr[📑 Chaptarr]
    end

    subgraph Utils [Automation Utilities]
        Bazarr[Bazarr]
        Recyclarr[Recyclarr]
        Cleanuparr[Cleanuparr]
    end

    subgraph Indexing [5. Search & Bypass]
        Prowlarr[Prowlarr]
        Byparr[Byparr]
        Prowlarr -.->|Cloudflare Bypass| Byparr
    end

    subgraph Downloaders [6. Download Clients]
        direction TB
        qBittorrent[qBittorrent]
        Deluge[Deluge]
        SABnzbd[SABnzbd]
    end

    subgraph Network [7. Privacy Tunnel]
        Gluetun[Gluetun VPN]
    end

    %% ====================
    %% CONNECTIONS
    %% ====================

    %% User Interaction
    User ==>|Search & Request| Seer
    User ===>|Stream Media| Jellyfin
    User ===>|Request Manga| Tranga
    User ===>|Read Manga| Komga
    User ===>|Request Manga| Suwayomi

    %% Pipeline Connections
    Utils -.->|Maintains Profiles/Queues| Arrs
    Seer ==>|Send Approvals/Requests| Arrs

    Arrs ==>|Search for Files| Indexing
    Indexing --->|Scrape Trackers/Indexers| Internet

    Arrs ==>|Send Magnets/NZBs| Downloaders
    Downloaders ===>|Route Traffic| Network
    Network --->|Download Anonymously| Internet

    Arrs -.->|Send Library Updates| Jellyfin
    
    %% Manga Connections
    Tranga --->|Fetch Chapters| Internet
    Suwayomi --->|Fetch Chapters| Internet

    %% ====================
    %% STYLING
    %% ====================
    classDef userNode fill:#6366f1,stroke:#4338ca,stroke-width:3px,color:#fff
    classDef internetNode fill:#0ea5e9,stroke:#0369a1,stroke-width:3px,color:#fff
    classDef mediaNode fill:#10b981,stroke:#047857,stroke-width:2px,color:#fff
    classDef requestNode fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff
    classDef arrNode fill:#f59e0b,stroke:#b45309,stroke-width:2px,color:#fff
    classDef utilNode fill:#eab308,stroke:#a16207,stroke-width:2px,color:#fff
    classDef indexNode fill:#f97316,stroke:#c2410c,stroke-width:2px,color:#fff
    classDef dlNode fill:#ef4444,stroke:#b91c1c,stroke-width:2px,color:#fff
    classDef netNode fill:#64748b,stroke:#334155,stroke-width:2px,color:#fff

    class User userNode;
    class Internet internetNode;
    class Jellyfin,Komga,Suwayomi,Tranga mediaNode;
    class Seer requestNode;
    class Sonarr,Radarr,Lidarr,Readarr,Chaptarr arrNode;
    class Bazarr,Recyclarr,Cleanuparr utilNode;
    class Prowlarr,Byparr indexNode;
    class qBittorrent,Deluge,SABnzbd dlNode;
    class Gluetun netNode;
```
