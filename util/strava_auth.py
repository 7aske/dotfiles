#!/usr/bin/env python3
"""
Strava OAuth Token Script
Gets access token with activity:write scope using local callback server.

Usage:
  1. Create a Strava API app at https://www.strava.com/settings/api
  2. Set "Authorization Callback Domain" to: localhost
  3. Run: python strava_auth.py
  4. Enter your Client ID and Client Secret when prompted
"""

import http.server
import threading
import webbrowser
import urllib.parse
import urllib.request
import json
import sys

# ── Config ──────────────────────────────────────────────────────────────────
REDIRECT_PORT = 8000
REDIRECT_URI = f"http://localhost:{REDIRECT_PORT}/callback"
SCOPE = "activity:write,activity:read_all"  # add more scopes if needed

# ── OAuth state ──────────────────────────────────────────────────────────────
auth_code = None
server_done = threading.Event()


class CallbackHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        global auth_code
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)

        if "code" in params:
            auth_code = params["code"][0]
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(b"""
                <html><body style="font-family:sans-serif;padding:40px">
                <h2>&#10003; Authorized!</h2>
                <p>You can close this tab and return to the terminal.</p>
                </body></html>
            """)
        else:
            error = params.get("error", ["unknown"])[0]
            self.send_response(400)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(f"<html><body><h2>Error: {error}</h2></body></html>".encode())

        server_done.set()

    def log_message(self, format, *args):
        pass  # silence request logs


def exchange_code(client_id, client_secret, code):
    url = "https://www.strava.com/oauth/token"
    data = urllib.parse.urlencode({
        "client_id": client_id,
        "client_secret": client_secret,
        "code": code,
        "grant_type": "authorization_code",
    }).encode()

    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")

    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def main():
    print("=== Strava OAuth Token Generator ===\n")
    client_id = input("Enter your Strava Client ID: ").strip()
    client_secret = input("Enter your Strava Client Secret: ").strip()

    # Start local callback server
    server = http.server.HTTPServer(("localhost", REDIRECT_PORT), CallbackHandler)
    thread = threading.Thread(target=server.serve_forever)
    thread.daemon = True
    thread.start()

    # Build authorization URL
    auth_url = (
        f"https://www.strava.com/oauth/authorize"
        f"?client_id={client_id}"
        f"&redirect_uri={urllib.parse.quote(REDIRECT_URI)}"
        f"&response_type=code"
        f"&approval_prompt=force"
        f"&scope={SCOPE}"
    )

    print(f"\nOpening browser for Strava authorization...")
    print(f"If it doesn't open, visit:\n  {auth_url}\n")
    webbrowser.open(auth_url)

    # Wait for callback
    server_done.wait(timeout=120)
    server.shutdown()

    if not auth_code:
        print("Error: No authorization code received (timed out or denied).")
        sys.exit(1)

    # Exchange code for token
    print("Exchanging code for token...")
    try:
        token_data = exchange_code(client_id, client_secret, auth_code)
    except Exception as e:
        print(f"Token exchange failed: {e}")
        sys.exit(1)

    # Print results
    print("\n=== SUCCESS ===")
    print(f"  Access Token:  {token_data['access_token']}")
    print(f"  Refresh Token: {token_data['refresh_token']}")
    print(f"  Expires At:    {token_data['expires_at']} (Unix timestamp)")
    print(f"  Athlete ID:    {token_data['athlete']['id']}")
    print(f"  Scopes:        {token_data.get('scope', SCOPE)}")

    # Save to file
    out_file = "strava_tokens.json"
    with open(out_file, "w") as f:
        json.dump(token_data, f, indent=2)
    print(f"\nFull token response saved to: {out_file}")


if __name__ == "__main__":
    main()
