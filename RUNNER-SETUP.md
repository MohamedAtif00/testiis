# Self-Hosted Runner Setup (Windows Server VM)

Your workflow waits at **"Waiting for a runner..."** until a runner is installed on the VM.

## 1. Check GitHub

Repo → **Settings → Actions → Runners**

- **No runners** → install below
- **Offline** → start the service (step 5)
- **Idle (green)** → re-run the workflow

## 2. On the VM — install the runner

1. GitHub → **Settings → Actions → Runners → New self-hosted runner**
2. Select **Windows x64**
3. Run these on the VM (use the exact download URL and token from GitHub):

```powershell
mkdir C:\actions-runner
cd C:\actions-runner
# Download and extract (URLs from GitHub page)
./config.cmd --url https://github.com/MohamedAtif00/testiis --token YOUR_TOKEN
```

When asked for labels, press Enter to accept defaults (`self-hosted`, `Windows`, `X64`).

## 3. Install prerequisites on the VM

- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0)
- [Node.js 20 LTS](https://nodejs.org/)
- IIS + [ASP.NET Core Hosting Bundle](https://dotnet.microsoft.com/download/dotnet/10.0)
- [IIS URL Rewrite](https://www.iis.net/downloads/microsoft/url-rewrite)

## 4. IIS folders

Create and point IIS sites to:

- `C:\software\backend` (API, port 5031)
- `C:\software\frontend` (UI, port 8080)

App pools: **No Managed Code**

## 5. Run as a service

```powershell
cd C:\actions-runner
./svc.cmd install
./svc.cmd start
```

## 6. GitHub repository variables

Settings → Actions → Variables — add all 6 vars (see README).

## 7. Test

Push to `main` or **Actions → Re-run all jobs**. The job should start within seconds.

## VM network (VirtualBox)

- Use **Bridged Adapter** or **NAT** with internet access
- VM must reach `https://github.com` (outbound HTTPS)
