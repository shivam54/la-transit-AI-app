#!/usr/bin/env python3
"""
LA Transit App Server with API Support
Handles static files and API requests for the LA Transit application
"""

import http.server
import socketserver
import json
import urllib.request
import urllib.parse
from urllib.error import HTTPError, URLError
import ssl
import os
from datetime import datetime
import time

# Configuration
PORT = 8000
API_BASE_URL = "https://api.goswift.ly"
API_KEY = "YOUR_SWIFTLY_API_KEY"  # Replace with your actual API key

class LATransitHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Handle API requests
        if self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            # Handle static files
            super().do_GET()
    
    def handle_api_request(self):
        """Handle API requests by proxying to external APIs"""
        try:
            # Extract the API path
            api_path = self.path[5:]  # Remove '/api/' prefix
            
            # Handle different API endpoints
            if api_path.startswith('swiftly/'):
                self.handle_swiftly_api(api_path)
            elif api_path.startswith('metro/'):
                self.handle_metro_api(api_path)
            elif api_path.startswith('openai/'):
                self.handle_openai_api(api_path)
            else:
                self.send_error(404, "API endpoint not found")
                
        except Exception as e:
            print(f"API Error: {e}")
            self.send_error(500, f"Internal server error: {str(e)}")
    
    def handle_swiftly_api(self, api_path):
        """Handle Swiftly API requests"""
        try:
            # Construct the full URL
            url = f"{API_BASE_URL}/{api_path}"
            
            # Add API key if available
            if API_KEY != "YOUR_SWIFTLY_API_KEY":
                if '?' in url:
                    url += f"&key={API_KEY}"
                else:
                    url += f"?key={API_KEY}"
            
            # Make the request
            req = urllib.request.Request(url)
            req.add_header('User-Agent', 'LA-Transit-App/1.0')
            
            with urllib.request.urlopen(req, timeout=10) as response:
                data = response.read()
                content_type = response.headers.get('Content-Type', 'application/json')
                
                # Send response
                self.send_response(200)
                self.send_header('Content-Type', content_type)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
                self.send_header('Access-Control-Allow-Headers', 'Content-Type')
                self.end_headers()
                self.wfile.write(data)
                
        except HTTPError as e:
            print(f"Swiftly API HTTP Error: {e.code} - {e.reason}")
            self.send_error(e.code, f"API Error: {e.reason}")
        except URLError as e:
            print(f"Swiftly API URL Error: {e.reason}")
            self.send_error(502, f"API Connection Error: {e.reason}")
        except Exception as e:
            print(f"Swiftly API Error: {e}")
            self.send_error(500, f"API Error: {str(e)}")
    
    def handle_metro_api(self, api_path):
        """Handle Metro API requests with mock data"""
        try:
            # Mock Metro API responses
            mock_data = self.get_mock_metro_data(api_path)
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(mock_data).encode())
            
        except Exception as e:
            print(f"Metro API Error: {e}")
            self.send_error(500, f"API Error: {str(e)}")
    
    def handle_openai_api(self, api_path):
        """Handle OpenAI API requests"""
        try:
            # This would handle OpenAI API requests
            # For now, return a mock response
            mock_response = {
                "status": "success",
                "message": "OpenAI API endpoint reached",
                "timestamp": datetime.now().isoformat()
            }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(mock_response).encode())
            
        except Exception as e:
            print(f"OpenAI API Error: {e}")
            self.send_error(500, f"API Error: {str(e)}")
    
    def get_mock_metro_data(self, api_path):
        """Generate mock Metro data for testing"""
        current_time = int(time.time())
        
        if 'vehicle-positions' in api_path:
            return {
                "header": {
                    "gtfs_realtime_version": "2.0",
                    "timestamp": current_time
                },
                "entity": [
                    {
                        "id": "vehicle_001",
                        "vehicle": {
                            "trip": {
                                "trip_id": "trip_red_line_001",
                                "route_id": "red",
                                "direction_id": 0
                            },
                            "vehicle": {
                                "id": "red_001",
                                "label": "Red Line Train 1"
                            },
                            "position": {
                                "latitude": 34.0522,
                                "longitude": -118.2437
                            },
                            "timestamp": current_time,
                            "congestion_level": 0,
                            "occupancy_status": 1
                        }
                    },
                    {
                        "id": "vehicle_002",
                        "vehicle": {
                            "trip": {
                                "trip_id": "trip_blue_line_001",
                                "route_id": "blue",
                                "direction_id": 1
                            },
                            "vehicle": {
                                "id": "blue_001",
                                "label": "Blue Line Train 1"
                            },
                            "position": {
                                "latitude": 34.0622,
                                "longitude": -118.2537
                            },
                            "timestamp": current_time,
                            "congestion_level": 1,
                            "occupancy_status": 2
                        }
                    }
                ]
            }
        
        elif 'trip-updates' in api_path:
            return {
                "header": {
                    "gtfs_realtime_version": "2.0",
                    "timestamp": current_time
                },
                "entity": [
                    {
                        "id": "update_001",
                        "tripUpdate": {
                            "trip": {
                                "trip_id": "trip_red_line_001",
                                "route_id": "red",
                                "direction_id": 0
                            },
                            "stopTimeUpdate": [
                                {
                                    "stopSequence": 1,
                                    "stopId": "stop_001",
                                    "arrival": {
                                        "time": current_time + 300
                                    },
                                    "departure": {
                                        "time": current_time + 360
                                    }
                                }
                            ]
                        }
                    }
                ]
            }
        
        elif 'alerts' in api_path:
            return {
                "header": {
                    "gtfs_realtime_version": "2.0",
                    "timestamp": current_time
                },
                "entity": [
                    {
                        "id": "alert_001",
                        "alert": {
                            "activePeriod": [
                                {
                                    "start": current_time,
                                    "end": current_time + 3600
                                }
                            ],
                            "informedEntity": [
                                {
                                    "routeId": "red"
                                }
                            ],
                            "headerText": {
                                "translation": [
                                    {
                                        "text": "Red Line Service Alert",
                                        "language": "en"
                                    }
                                ]
                            },
                            "descriptionText": {
                                "translation": [
                                    {
                                        "text": "Minor delays due to signal maintenance",
                                        "language": "en"
                                    }
                                ]
                            }
                        }
                    }
                ]
            }
        
        else:
            return {
                "status": "success",
                "message": "Metro API endpoint reached",
                "endpoint": api_path,
                "timestamp": datetime.now().isoformat()
            }
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
    
    def log_message(self, format, *args):
        """Custom logging to show API requests"""
        if self.path.startswith('/api/'):
            print(f"[API] {self.address_string()} - {format % args}")
        else:
            print(f"[FILE] {self.address_string()} - {format % args}")

def main():
    """Start the server"""
    # Change to the directory containing this script
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # Create the server
    with socketserver.TCPServer(("", PORT), LATransitHandler) as httpd:
        print(f"🚇 LA Transit Server starting on port {PORT}")
        print(f"📁 Serving files from: {os.getcwd()}")
        print(f"🌐 Open your browser to: http://localhost:{PORT}")
        print(f"🤖 Enhanced chatbot: http://localhost:{PORT}/enhanced-chatbot-test.html")
        print(f"📱 Main app: http://localhost:{PORT}/index-working-with-location-sharing.html")
        print(f"🔧 API endpoints: http://localhost:{PORT}/api/")
        print("\n" + "="*50)
        print("Press Ctrl+C to stop the server")
        print("="*50 + "\n")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped by user")
            httpd.shutdown()

if __name__ == "__main__":
    main()
