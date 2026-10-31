import os
from http.server import BaseHTTPRequestHandler, HTTPServer
 
VERSION = os.environ.get("APP_VERSION", "dev")[:7]
 
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = b"ok"
        else:
            body = ("SRE portfolio app, version " + VERSION).encode()
        self.send_response(500 if self.path == "/health" else 200)
        self.end_headers()
        self.wfile.write(body)
 
HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
