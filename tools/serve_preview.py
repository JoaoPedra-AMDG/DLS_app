"""Serve a release build at its GitHub Pages base path on loopback only."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlparse

root=Path(__file__).resolve().parents[1]/'build/web'
class Handler(SimpleHTTPRequestHandler):
 def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(root),**kwargs)
 def do_GET(self):
  if self.path=='/':
   self.send_response(302);self.send_header('Location','/DLS_app/');self.end_headers();return
  if not urlparse(self.path).path.startswith('/DLS_app/'):
   self.send_error(404);return
  self.path=self.path[len('/DLS_app'):]
  super().do_GET()

print('DLS preview: http://127.0.0.1:8798/DLS_app/',flush=True)
ThreadingHTTPServer(('127.0.0.1',8798),Handler).serve_forever()
