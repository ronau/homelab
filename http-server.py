#!/usr/bin/env python3

from http.server import SimpleHTTPRequestHandler
from socketserver import TCPServer
import logging
import sys

try:
    PORT = int(sys.argv[1])
except:
    PORT = 8001

class GetHandler(SimpleHTTPRequestHandler):

    def do_GET(self):
        response = f"Request:\n{self.headers}"

        self.send_response(200, self.headers)
        self.end_headers()
        self.wfile.write(response.encode('utf-8'))


Handler = GetHandler
httpd = TCPServer(('', PORT), Handler)

httpd.serve_forever()
