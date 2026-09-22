#!/usr/bin/env python3
"""
AMC360 Development Server & Network Bridge
- Starts Laravel API backend on 127.0.0.1:8001
- Bridges inbound Wi-Fi requests from 0.0.0.0:8000 -> 127.0.0.1:8001
- Solves macOS Application Firewall blocking inbound PHP connections
"""
import os
import sys
import socket
import subprocess
import threading
import signal
import time

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
PORT = 8000
INTERNAL_PORT = 8001

def get_wifi_ip():
    try:
        # Try ipconfig for en0 (Wi-Fi on Mac)
        res = subprocess.run(["ipconfig", "getifaddr", "en0"], capture_output=True, text=True)
        ip = res.stdout.strip()
        if ip: return ip
    except Exception:
        pass
    try:
        # Fallback to UDP socket trick
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def start_laravel():
    print(f"[*] Starting Laravel backend on internal port {INTERNAL_PORT}...")
    proc = subprocess.Popen(
        [sys.executable if "php" in sys.executable else "php", "artisan", "serve", f"--host=127.0.0.1", f"--port={INTERNAL_PORT}"],
        cwd=BACKEND_DIR,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )
    return proc

def fwd(src, dst):
    try:
        while True:
            data = src.recv(4096)
            if not data: break
            dst.sendall(data)
    except:
        pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def handle_client(client_sock):
    try:
        backend_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        backend_sock.connect(("127.0.0.1", INTERNAL_PORT))
        threading.Thread(target=fwd, args=(client_sock, backend_sock), daemon=True).start()
        threading.Thread(target=fwd, args=(backend_sock, client_sock), daemon=True).start()
    except Exception:
        try: client_sock.close()
        except: pass

def start_tunnel():
    cf_bin = os.path.join(BACKEND_DIR, "cloudflared")
    if not os.path.exists(cf_bin):
        return None
    try:
        proc = subprocess.Popen(
            [cf_bin, "tunnel", "--url", f"http://127.0.0.1:{PORT}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        def monitor_tunnel():
            import re
            for line in iter(proc.stdout.readline, ""):
                if "trycloudflare.com" in line:
                    match = re.search(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com', line)
                    if match:
                        tunnel_url = match.group(0)
                        print("\n" + "=" * 60)
                        print("   🌍 PUBLIC INTERNET ACCESS (START APP ANYWHERE):")
                        print(f"   Tunnel URL:   {tunnel_url}")
                        print(f"   API Base URL: {tunnel_url}/api/v1")
                        print("=" * 60 + "\n")
                        with open(os.path.join(BACKEND_DIR, "tunnel_url.txt"), "w") as f:
                            f.write(tunnel_url)

                        # Auto-update mobile app_config.dart so mobile app picks up the live tunnel immediately
                        app_config_file = os.path.join(os.path.dirname(BACKEND_DIR), "mobile", "lib", "app", "configuration", "app_config.dart")
                        if os.path.exists(app_config_file):
                            try:
                                with open(app_config_file, "r") as acf:
                                    conf_content = acf.read()
                                conf_content = re.sub(
                                    r"static String apiBaseUrl = .*?;",
                                    f"static String apiBaseUrl = '{tunnel_url}/api/v1';",
                                    conf_content
                                )
                                with open(app_config_file, "w") as acf:
                                    acf.write(conf_content)
                                print("   [✓] Auto-synced live tunnel URL to mobile app_config.dart!")
                            except Exception as sync_err:
                                print(f"   [!] Could not sync app_config.dart: {sync_err}")
        threading.Thread(target=monitor_tunnel, daemon=True).start()
        return proc
    except Exception as e:
        print(f"[!] Could not start Cloudflare tunnel: {e}")
        return None

def main():
    wifi_ip = get_wifi_ip()

    # Sync Wi-Fi IP to mobile AppConfig
    app_config_file = os.path.join(os.path.dirname(BACKEND_DIR), "mobile", "lib", "app", "configuration", "app_config.dart")
    if os.path.exists(app_config_file):
        try:
            import re
            with open(app_config_file, "r") as acf:
                conf_content = acf.read()
            conf_content = re.sub(
                r"static const String currentWifiUrl = .*?;",
                f"static const String currentWifiUrl = 'http://{wifi_ip}:{PORT}/api/v1';",
                conf_content
            )
            with open(app_config_file, "w") as acf:
                acf.write(conf_content)
        except Exception:
            pass

    print("=" * 60)
    print("   AMC360 — Local Development Server & Network Bridge")
    print("=" * 60)
    print(f"   Local Address:      http://127.0.0.1:{PORT}")
    print(f"   Network / Mobile:   http://{wifi_ip}:{PORT}")
    print(f"   API Base URL:       http://{wifi_ip}:{PORT}/api/v1")
    print("-" * 60)
    print(f"   Enter this API URL in the mobile app if needed:")
    print(f"   http://{wifi_ip}:{PORT}/api/v1")
    print("=" * 60)

    # Start Laravel
    laravel_proc = start_laravel()

    # Log Laravel output in background
    def print_logs():
        for line in iter(laravel_proc.stdout.readline, ""):
            if "Server running" not in line and "Ctrl+C" not in line:
                if line.strip():
                    print(f"[Laravel] {line.strip()}")
    threading.Thread(target=print_logs, daemon=True).start()

    # Wait 1 sec for Laravel to bind
    time.sleep(1)

    # Start TCP Bridge on 0.0.0.0:8000
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind(("0.0.0.0", PORT))
        server.listen(64)
        print(f"[✓] Network bridge active on 0.0.0.0:{PORT} (accepts mobile Wi-Fi connections)")
        print(f"[✓] Server is READY for mobile connections!\n")
    except Exception as e:
        print(f"[!] Error binding to port {PORT}: {e}")
        laravel_proc.terminate()
        sys.exit(1)

    # Start Cloudflare Public Tunnel
    tunnel_proc = start_tunnel()

    def shutdown(sig, frame):
        print("\n[*] Stopping AMC360 backend...")
        try: server.close()
        except: pass
        try: laravel_proc.terminate()
        except: pass
        if tunnel_proc:
            try: tunnel_proc.terminate()
            except: pass
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    while True:
        try:
            client, _ = server.accept()
            threading.Thread(target=handle_client, args=(client,), daemon=True).start()
        except (socket.error, KeyboardInterrupt):
            break

if __name__ == "__main__":
    main()
