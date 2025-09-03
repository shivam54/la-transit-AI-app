const express = require('express');
const cors = require('cors');
const axios = require('axios');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8002;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

// API Configuration
const SWIFTLY_API_KEY = process.env.SWIFTLY_API_KEY || 'b565d854fa4038e9c2b9eb1e4dd0179d';
const SWIFTLY_BASE_URL = 'https://api.goswift.ly';

// WeatherMap API Configuration
const WEATHERMAP_API_KEY = process.env.WEATHERMAP_API_KEY || 'b8499f5e2ddcaf0fded45f08f7d69c88';
const WEATHERMAP_BASE_URL = 'https://api.openweathermap.org/data/2.5';

// TomTom Traffic API Configuration
const TOMTOM_API_KEY = process.env.TOMTOM_API_KEY || 'CsAIb00M3RlKfsEJaRhT8Ugz8tdzaAcT';
const TOMTOM_BASE_URL = 'https://api.tomtom.com/traffic/services/4';

// Serve the main HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index-working-with-location-sharing.html'));
});

// Proxy endpoint for TransitLand API
app.get('/api/transitland/*', async (req, res) => {
    try {
        const apiKey = req.headers['x-api-key'];
        if (!apiKey) {
            return res.status(400).json({ error: 'API key required' });
        }

        const endpoint = req.params[0];
        const url = `https://transit.land/api/v2/${endpoint}`;
        
        console.log(`🔄 Proxying request to: ${url}`);
        
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Authorization': `Token ${apiKey}`
            }
        });

        if (response.ok) {
            const data = await response.json();
            console.log(`✅ Success: ${endpoint}`);
            res.json(data);
        } else {
            const errorText = await response.text();
            console.log(`❌ Error: ${response.status} - ${errorText}`);
            res.status(response.status).json({ 
                error: `API Error: ${response.status}`,
                details: errorText 
            });
        }
    } catch (error) {
        console.log(`❌ Proxy error: ${error.message}`);
        res.status(500).json({ error: `Proxy Error: ${error.message}` });
    }
});

// Proxy WeatherMap API requests
app.get('/api/weather/weather', async (req, res) => {
    try {
        // Build the full WeatherMap API URL
        let weatherUrl = `${WEATHERMAP_BASE_URL}/weather`;
        
        // Add query parameters if present
        if (Object.keys(req.query).length > 0) {
            const queryString = new URLSearchParams(req.query).toString();
            weatherUrl += `?${queryString}`;
        }
        
        // Always add API key for WeatherMap
        weatherUrl += weatherUrl.includes('?') ? '&' : '?';
        weatherUrl += `appid=${WEATHERMAP_API_KEY}&units=imperial`;
        
        console.log(`🌤️ Proxying WeatherMap request to: ${weatherUrl}`);
        
        // Make the request to WeatherMap API
        const response = await axios({
            method: 'GET',
            url: weatherUrl,
            headers: {
                'User-Agent': 'LA-Transit-App/1.0',
                'Content-Type': 'application/json'
            },
            timeout: 10000
        });
        
        // Send the response back
        res.status(response.status).json(response.data);
        console.log(`✅ Successfully proxied WeatherMap API response`);
        
    } catch (error) {
        console.error(`❌ WeatherMap API Error:`, error.message);
        
        if (error.response) {
            res.status(error.response.status).json({
                error: 'WeatherMap API Error',
                message: error.response.data || error.message
            });
        } else {
            res.status(500).json({
                error: 'Network Error',
                message: error.message
            });
        }
    }
});

// Generic WeatherMap API proxy for other endpoints
app.use('/api/weather/*', async (req, res) => {
    try {
        // Extract the WeatherMap API path
        const weatherPath = req.path.replace('/api/weather/', '');
        
        // Build the full WeatherMap API URL
        let weatherUrl = `${WEATHERMAP_BASE_URL}/${weatherPath}`;
        
        // Add query parameters if present
        if (Object.keys(req.query).length > 0) {
            const queryString = new URLSearchParams(req.query).toString();
            weatherUrl += `?${queryString}`;
        }
        
        // Always add API key for WeatherMap
        weatherUrl += weatherUrl.includes('?') ? '&' : '?';
        weatherUrl += `appid=${WEATHERMAP_API_KEY}&units=imperial`;
        
        console.log(`🌤️ Proxying WeatherMap request to: ${weatherUrl}`);
        
        // Make the request to WeatherMap API
        const response = await axios({
            method: req.method,
            url: weatherUrl,
            headers: {
                'User-Agent': 'LA-Transit-App/1.0',
                'Content-Type': 'application/json'
            },
            data: req.method !== 'GET' ? req.body : undefined,
            timeout: 10000
        });
        
        // Send the response back
        res.status(response.status).json(response.data);
        console.log(`✅ Successfully proxied WeatherMap API response`);
        
    } catch (error) {
        console.error(`❌ WeatherMap API Error:`, error.message);
        
        if (error.response) {
            res.status(error.response.status).json({
                error: 'WeatherMap API Error',
                message: error.response.data || error.message
            });
        } else {
            res.status(500).json({
                error: 'Network Error',
                message: error.message
            });
        }
    }
});

// Proxy TomTom Traffic API requests
app.get('/api/tomtom/incidentDetails/s3/34.0522,-118.2437/10/2/true/true/true/true/true/true/true', async (req, res) => {
    try {
        // Build the full TomTom API URL
        let tomtomUrl = `${TOMTOM_BASE_URL}/incidentDetails/s3/34.0522,-118.2437/10/2/true/true/true/true/true/true/true`;
        
        // Add query parameters if present
        if (Object.keys(req.query).length > 0) {
            const queryString = new URLSearchParams(req.query).toString();
            tomtomUrl += `?${queryString}`;
        }
        
        // Always add API key for TomTom
        tomtomUrl += tomtomUrl.includes('?') ? '&' : '?';
        tomtomUrl += `key=${TOMTOM_API_KEY}`;
        
        console.log(`🚦 Proxying TomTom Traffic request to: ${tomtomUrl}`);
        
        // Make the request to TomTom API
        const response = await axios({
            method: 'GET',
            url: tomtomUrl,
            headers: {
                'User-Agent': 'LA-Transit-App/1.0',
                'Content-Type': 'application/json'
            },
            timeout: 10000
        });
        
        // Send the response back
        res.status(response.status).json(response.data);
        console.log(`✅ Successfully proxied TomTom Traffic API response`);
        
    } catch (error) {
        console.error(`❌ TomTom Traffic API Error:`, error.message);
        
        if (error.response) {
            res.status(error.response.status).json({
                error: 'TomTom Traffic API Error',
                message: error.response.data || error.message
            });
        } else {
            res.status(500).json({
                error: 'Network Error',
                message: error.message
            });
        }
    }
});

// Generic TomTom Traffic API proxy for other endpoints
app.use('/api/tomtom/*', async (req, res) => {
    try {
        // Extract the TomTom API path
        const tomtomPath = req.path.replace('/api/tomtom/', '');
        
        // Build the full TomTom API URL
        let tomtomUrl = `${TOMTOM_BASE_URL}/${tomtomPath}`;
        
        // Add query parameters if present
        if (Object.keys(req.query).length > 0) {
            const queryString = new URLSearchParams(req.query).toString();
            tomtomUrl += `?${queryString}`;
        }
        
        // Always add API key for TomTom
        tomtomUrl += tomtomUrl.includes('?') ? '&' : '?';
        tomtomUrl += `key=${TOMTOM_API_KEY}`;
        
        console.log(`🚦 Proxying TomTom Traffic request to: ${tomtomUrl}`);
        
        // Make the request to TomTom API
        const response = await axios({
            method: req.method,
            url: tomtomUrl,
            headers: {
                'User-Agent': 'LA-Transit-App/1.0',
                'Content-Type': 'application/json'
            },
            data: req.method !== 'GET' ? req.body : undefined,
            timeout: 10000
        });
        
        // Send the response back
        res.status(response.status).json(response.data);
        console.log(`✅ Successfully proxied TomTom Traffic API response`);
        
    } catch (error) {
        console.error(`❌ TomTom Traffic API Error:`, error.message);
        
        if (error.response) {
            res.status(error.response.status).json({
                error: 'TomTom Traffic API Error',
                message: error.response.data || error.message
            });
        } else {
            res.status(500).json({
                error: 'Network Error',
                message: error.message
            });
        }
    }
});

// Proxy Swiftly API requests
app.get('/api/swiftly/real-time/lametro/gtfs-rt-vehicle-positions', async (req, res) => {
    try {
        // Build the full Swiftly API URL
        let swiftlyUrl = `${SWIFTLY_BASE_URL}/realtime/lametro/gtfs-rt-vehicle-positions`;
        
        // Add query parameters if present
        if (Object.keys(req.query).length > 0) {
            const queryString = new URLSearchParams(req.query).toString();
            swiftlyUrl += `?${queryString}`;
        }
        
        console.log(`🔄 Proxying Swiftly request to: ${swiftlyUrl}`);
        
        // Make the request to Swiftly API
        const response = await axios({
            method: 'GET',
            url: swiftlyUrl,
            headers: {
                'Authorization': SWIFTLY_API_KEY,
                'User-Agent': 'LA-Transit-App/1.0',
                'Content-Type': 'application/json'
            },
            timeout: 10000
        });
        
        // Send the response back
        res.status(response.status).json(response.data);
        console.log(`✅ Successfully proxied Swiftly API response`);
        
    } catch (error) {
        console.error(`❌ Swiftly API Error:`, error.message);
        
        if (error.response) {
            res.status(error.response.status).json({
                error: 'Swiftly API Error',
                message: error.response.data || error.message
            });
        } else {
            res.status(500).json({
                error: 'Network Error',
                message: error.message
            });
        }
    }
});

// Generic Swiftly API proxy for other endpoints
app.use('/api/swiftly/*', async (req, res) => {
    try {
        // Extract the Swiftly API path
        const swiftlyPath = req.path.replace('/api/swiftly/', '');
        
        // Build the full Swiftly API URL
        let swiftlyUrl = `${SWIFTLY_BASE_URL}/realtime/${swiftlyPath}`;
        
        // Add query parameters if present
        if (Object.keys(req.query).length > 0) {
            const queryString = new URLSearchParams(req.query).toString();
            swiftlyUrl += `?${queryString}`;
        }
        
        console.log(`🔄 Proxying Swiftly request to: ${swiftlyUrl}`);
        
        // Make the request to Swiftly API
        const response = await axios({
            method: req.method,
            url: swiftlyUrl,
            headers: {
                'Authorization': SWIFTLY_API_KEY,
                'User-Agent': 'LA-Transit-App/1.0',
                'Content-Type': 'application/json'
            },
            data: req.method !== 'GET' ? req.body : undefined,
            timeout: 10000
        });
        
        // Send the response back
        res.status(response.status).json(response.data);
        console.log(`✅ Successfully proxied Swiftly API response`);
        
    } catch (error) {
        console.error(`❌ Swiftly API Error:`, error.message);
        
        if (error.response) {
            res.status(error.response.status).json({
                error: 'Swiftly API Error',
                message: error.response.data || error.message
            });
        } else {
            res.status(500).json({
                error: 'Network Error',
                message: error.message
            });
        }
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'LA Transit App Server is running',
        timestamp: new Date().toISOString(),
        apis: {
            swiftly: SWIFTLY_API_KEY !== 'your_swiftly_api_key_here' ? '✅ Set' : '❌ Not Set',
            weathermap: WEATHERMAP_API_KEY !== 'your_weathermap_api_key_here' ? '✅ Set' : '❌ Not Set',
            tomtom: TOMTOM_API_KEY !== 'your_tomtom_api_key_here' ? '✅ Set' : '❌ Not Set'
        }
    });
});

// Start the server
app.listen(PORT, () => {
    console.log(`🚀 LA Transit App Server started!`);
    console.log(`📡 Server running on: http://localhost:${PORT}`);
    console.log(`🔑 API Keys Status:`);
    console.log(`   • Swiftly: ${SWIFTLY_API_KEY !== 'your_swiftly_api_key_here' ? '✅ Set' : '❌ Not Set'}`);
    console.log(`   • WeatherMap: ${WEATHERMAP_API_KEY !== 'your_weathermap_api_key_here' ? '✅ Set' : '❌ Not Set'}`);
    console.log(`   • TomTom Traffic: ${TOMTOM_API_KEY !== 'your_tomtom_api_key_here' ? '✅ Set' : '❌ Not Set'}`);
    console.log();
    console.log(`📋 Available endpoints:`);
    console.log(`   • Main App: http://localhost:${PORT}/`);
    console.log(`   • Health Check: http://localhost:${PORT}/health`);
    console.log(`   • Swiftly Proxy: http://localhost:${PORT}/api/swiftly/...`);
    console.log(`   • WeatherMap Proxy: http://localhost:${PORT}/api/weather/...`);
    console.log(`   • TomTom Traffic Proxy: http://localhost:${PORT}/api/tomtom/...`);
    console.log();
    console.log(`🌐 Your app can now make requests to all APIs via this server!`);
    console.log(`   • Swiftly: fetch('http://localhost:${PORT}/api/swiftly/lametro/gtfs-rt-vehicle-positions')`);
    console.log(`   • Weather: fetch('http://localhost:${PORT}/api/weather/weather?q=Los Angeles')`);
    console.log(`   • Traffic: fetch('http://localhost:${PORT}/api/tomtom/incidentDetails/s3/34.0522,-118.2437/10/2/true/true/true/true/true/true/true')`);
    console.log();
    console.log(`🔄 Press Ctrl+C to stop the server`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Server stopped by user');
    process.exit(0);
});
