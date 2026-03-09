#!/usr/bin/env python3
"""
Simple Python Web Server for LA Metro Transit App
Bypasses CORS issues by serving files from localhost
"""

import http.server
import socketserver
import os
import urllib.request
import urllib.parse
import json
from urllib.error import HTTPError, URLError

PORT = 8000

class TransitAPIHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Debug: log request path
        try:
            print(f"➡️  GET {self.path}")
        except Exception:
            pass
        
        # Parse URL
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path or '/'
        
        # Health check endpoint
        if path.startswith('/health'):
            try:
                print('🩺 Health check requested')
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    'status': 'OK',
                    'message': 'LA Metro Transit Python server is running',
                    'timestamp': __import__('datetime').datetime.utcnow().isoformat() + 'Z'
                }).encode('utf-8'))
            except Exception as e:
                self.send_error(500, f"Health endpoint error: {str(e)}")
            return
        
        # Handle API proxy requests
        if path.startswith('/api/'):
            self.handle_api_proxy(parsed)
            return
        
        # Serve static files
        super().do_GET()
    
    def handle_api_proxy(self, parsed):
        """Handle API proxy requests to bypass CORS"""
        try:
            path = parsed.path
            query = parsed.query
            parts = path.split('/')
            # Expected: ['', 'api', '{type}', '{endpoint...}']
            if len(parts) < 4:
                self.send_error(400, "Invalid API path")
                return
            
            api_type = parts[2]  # transitland or swiftly
            endpoint_part = '/'.join(parts[3:])  # e.g., 'vehicles'
            endpoint = endpoint_part
            if query:
                endpoint = f"{endpoint_part}?{query}"
            
            # Get API key from headers
            api_key = self.headers.get('X-API-Key')
            if not api_key:
                self.send_error(400, "API key required")
                return
            
            # Build target URL based on API type
            if api_type == 'transitland':
                # TransitLand v2 REST base path requires '/rest'
                target_url = f"https://transit.land/api/v2/rest/{endpoint}"
                # Pass API key as 'apikey' query parameter per docs
                sep = '&' if '?' in target_url else '?'
                target_url = f"{target_url}{sep}apikey={api_key}"
                headers = {
                    'Accept': 'application/json'
                }
            elif api_type == 'swiftly':
                target_url = f"https://api.goswift.ly/{endpoint}"
                headers = {
                    'Accept': 'application/json',
                    'Authorization': api_key
                }
            else:
                self.send_error(400, "Unknown API type")
                return
            
            print(f"🔄 Proxying request to: {target_url}")
            
            # Make request to target API
            req = urllib.request.Request(target_url, headers=headers)
            with urllib.request.urlopen(req) as response:
                data = response.read()
                content_type = response.headers.get('Content-Type', 'application/json')
                
                # Send response back to client
                self.send_response(200)
                self.send_header('Content-Type', content_type)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
                self.send_header('Access-Control-Allow-Headers', 'Content-Type, X-API-Key')
                self.end_headers()
                self.wfile.write(data)
                
                print(f"✅ Success: {endpoint}")
                
        except HTTPError as e:
            error_msg = f"API Error: {e.code}"
            print(f"❌ {error_msg}")
            self.send_error(e.code, error_msg)
        except URLError as e:
            error_msg = f"Network Error: {e.reason}"
            print(f"❌ {error_msg}")
            self.send_error(500, error_msg)
        except Exception as e:
            error_msg = f"Proxy Error: {str(e)}"
            print(f"❌ {error_msg}")
            self.send_error(500, error_msg)
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, X-API-Key')
        self.end_headers()
    
    def end_headers(self):
        """Add CORS headers to all responses"""
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

def main():
    # Change to the directory containing this script
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # Create server
    with socketserver.TCPServer(("", PORT), TransitAPIHandler) as httpd:
        print(f"🚇 LA Metro Transit Server running on http://localhost:{PORT}")
        print(f"📁 Serving files from: {os.getcwd()}")
        print(f"🔗 Main app: http://localhost:{PORT}/index-working-with-location-sharing.html")
        print(f"🔗 TransitLand proxy: http://localhost:{PORT}/api/transitland/*")
        print(f"🔗 Swiftly proxy: http://localhost:{PORT}/api/swiftly/*")
        print(f"🔗 Test page: http://localhost:{PORT}/transitland-server-test.html")
        print("\n💡 Press Ctrl+C to stop the server")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped")

if __name__ == "__main__":
    main()
