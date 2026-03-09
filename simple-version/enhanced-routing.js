// Enhanced Routing System for LA Transit App
// Smart local-first geocoding that works like Google Maps

class EnhancedRoutingSystem {
    constructor() {
        this.apis = {
            nominatim: 'https://nominatim.openstreetmap.org',
            osrm: 'https://router.project-osrm.org',
            photon: 'https://photon.komoot.io',
            // Add Google Maps API for enhanced features
            googleMaps: 'https://maps.googleapis.com/maps/api',
            googlePlaces: 'https://maps.googleapis.com/maps/api/place'
        };
        
        // Enhanced API configuration
        this.apiConfig = {
            // Photon for fast geocoding
            photon: {
                enabled: true,
                timeout: 2000,
                maxResults: 10
            },
            // Google Maps for Street View and rich POI data
            googleMaps: {
                enabled: false, // Set to true when you get API key
                apiKey: '', // Add your Google Maps API key here
                timeout: 3000,
                features: ['streetview', 'places', 'geocoding'],
                // Enhanced configuration
                streetViewSize: '400x300',
                nearbySearchRadius: 500, // meters
                maxNearbyResults: 10,
                autocompleteTypes: 'establishment|geocode'
            },
            // Nominatim as fallback
            nominatim: {
                enabled: true,
                timeout: 1500,
                maxResults: 5
            }
        };
        
        this.cache = new Map();
        this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
        
        // Enhanced local database with rich POI data
        this.localGeocodingDB = {
            // Universities
            'usc': { lat: 34.0224, lng: -118.2851, name: 'University of Southern California', type: 'university', poi: { rating: 4.5, photos: 3, reviews: 1200 } },
            'ucla': { lat: 34.0689, lng: -118.4452, name: 'UCLA (University of California, Los Angeles)', type: 'university', poi: { rating: 4.6, photos: 5, reviews: 2100 } },
            'cal state la': { lat: 34.0669, lng: -118.1689, name: 'California State University, Los Angeles', type: 'university', poi: { rating: 4.2, photos: 2, reviews: 800 } },
            
            // Major Landmarks
            'hollywood sign': { lat: 34.1341, lng: -118.3216, name: 'Hollywood Sign', type: 'landmark', poi: { rating: 4.7, photos: 8, reviews: 3500, streetview: true } },
            'griffith observatory': { lat: 34.1185, lng: -118.3004, name: 'Griffith Observatory', type: 'landmark', poi: { rating: 4.8, photos: 6, reviews: 4200, streetview: true } },
            'santa monica pier': { lat: 34.0089, lng: -118.5001, name: 'Santa Monica Pier', type: 'landmark', poi: { rating: 4.5, photos: 4, reviews: 2800, streetview: true } },
            'venice beach': { lat: 33.9850, lng: -118.4695, name: 'Venice Beach', type: 'landmark', poi: { rating: 4.4, photos: 5, reviews: 3200, streetview: true } },
            'disneyland': { lat: 33.8121, lng: -117.9190, name: 'Disneyland Resort', type: 'theme_park', poi: { rating: 4.6, photos: 7, reviews: 15000, streetview: true } },
            'universal studios': { lat: 34.1381, lng: -118.3534, name: 'Universal Studios Hollywood', type: 'theme_park', poi: { rating: 4.4, photos: 6, reviews: 8500, streetview: true } },
            'getty center': { lat: 34.0780, lng: -118.4743, name: 'Getty Center', type: 'museum', poi: { rating: 4.7, photos: 5, reviews: 6800, streetview: true } },
            'lacma': { lat: 34.0638, lng: -118.3595, name: 'LACMA (Los Angeles County Museum of Art)', type: 'museum', poi: { rating: 4.3, photos: 4, reviews: 4200, streetview: true } },
            
            // Airports
            'lax': { lat: 33.9416, lng: -118.4085, name: 'Los Angeles International Airport (LAX)', type: 'airport', poi: { rating: 3.8, photos: 3, reviews: 5600, streetview: true } },
            'burbank airport': { lat: 34.2006, lng: -118.3587, name: 'Hollywood Burbank Airport', type: 'airport', poi: { rating: 4.2, photos: 2, reviews: 1200, streetview: true } },
            'long beach airport': { lat: 33.8177, lng: -118.1516, name: 'Long Beach Airport', type: 'airport', poi: { rating: 4.1, photos: 2, reviews: 800, streetview: true } },
            
            // Shopping Centers
            'the grove': { lat: 34.0762, lng: -118.3585, name: 'The Grove', type: 'shopping', poi: { rating: 4.3, photos: 4, reviews: 3200, streetview: true } },
            'beverly center': { lat: 34.0762, lng: -118.3765, name: 'Beverly Center', type: 'shopping', poi: { rating: 4.1, photos: 3, reviews: 2800, streetview: true } },
            'south coast plaza': { lat: 33.6889, lng: -117.8847, name: 'South Coast Plaza', type: 'shopping', poi: { rating: 4.4, photos: 4, reviews: 4200, streetview: true } },
            
            // Sports Venues
            'dodger stadium': { lat: 34.0736, lng: -118.2400, name: 'Dodger Stadium', type: 'stadium', poi: { rating: 4.5, photos: 5, reviews: 6800, streetview: true } },
            'staple center': { lat: 34.0430, lng: -118.2673, name: 'Crypto.com Arena (formerly Staples Center)', type: 'stadium', poi: { rating: 4.4, photos: 4, reviews: 5200, streetview: true } },
            'rose bowl': { lat: 34.1614, lng: -118.1676, name: 'Rose Bowl Stadium', type: 'stadium', poi: { rating: 4.6, photos: 4, reviews: 3800, streetview: true } },
            
            // Popular Streets
            'rodeo drive': { lat: 34.0676, lng: -118.3977, name: 'Rodeo Drive', type: 'street', poi: { rating: 4.3, photos: 5, reviews: 2400, streetview: true } },
            'hollywood boulevard': { lat: 34.1016, lng: -118.3267, name: 'Hollywood Boulevard', type: 'street', poi: { rating: 4.2, photos: 4, reviews: 3600, streetview: true } },
            'sunset boulevard': { lat: 34.0928, lng: -118.3287, name: 'Sunset Boulevard', type: 'street', poi: { rating: 4.1, photos: 3, reviews: 2800, streetview: true } },
            'wilshire boulevard': { lat: 34.0522, lng: -118.2437, name: 'Wilshire Boulevard', type: 'street', poi: { rating: 4.0, photos: 3, reviews: 2200, streetview: true } },
            
            // Restaurants & Entertainment
            'in-n-out burger': { lat: 34.0522, lng: -118.2437, name: 'In-N-Out Burger', type: 'restaurant', poi: { rating: 4.5, photos: 3, reviews: 15000, streetview: true } },
            'pink\'s hot dogs': { lat: 34.0839, lng: -118.3004, name: 'Pink\'s Hot Dogs', type: 'restaurant', poi: { rating: 4.2, photos: 3, reviews: 4200, streetview: true } },
            'musso & frank grill': { lat: 34.1016, lng: -118.3267, name: 'Musso & Frank Grill', type: 'restaurant', poi: { rating: 4.4, photos: 4, reviews: 2800, streetview: true } },
            
            // Hospitals
            'cedars-sinai': { lat: 34.0762, lng: -118.3765, name: 'Cedars-Sinai Medical Center', type: 'hospital', poi: { rating: 4.3, photos: 2, reviews: 1200, streetview: true } },
            'ucla medical center': { lat: 34.0689, lng: -118.4452, name: 'UCLA Medical Center', type: 'hospital', poi: { rating: 4.4, photos: 2, reviews: 1800, streetview: true } },
            'usc medical center': { lat: 34.0224, lng: -118.2851, name: 'USC Medical Center', type: 'hospital', poi: { rating: 4.2, photos: 2, reviews: 900, streetview: true } }
        };
        
        // Street coordinate ranges for LA
        this.streetRanges = {
            'figueroa': { 
                lat: { min: 34.0, max: 34.1 }, 
                lng: { min: -118.3, max: -118.2 },
                baseLat: 34.0522, baseLng: -118.2437
            },
            'main': { 
                lat: { min: 34.0, max: 34.1 }, 
                lng: { min: -118.3, max: -118.2 },
                baseLat: 34.0522, baseLng: -118.2437
            },
            'normandie': { 
                lat: { min: 34.0, max: 34.1 }, 
                lng: { min: -118.3, max: -118.2 },
                baseLat: 34.0522, baseLng: -118.2437
            },
            'sunset': { 
                lat: { min: 34.08, max: 34.12 }, 
                lng: { min: -118.35, max: -118.28 },
                baseLat: 34.0928, baseLng: -118.3287
            },
            'wilshire': { 
                lat: { min: 34.04, max: 34.08 }, 
                lng: { min: -118.25, max: -118.18 },
                baseLat: 34.0522, baseLng: -118.2437
            },
            'olympic': { 
                lat: { min: 34.04, max: 34.08 }, 
                lng: { min: -118.25, max: -118.18 },
                baseLat: 34.0522, baseLng: -118.2437
            },
            'pico': { 
                lat: { min: 34.04, max: 34.08 }, 
                lng: { min: -118.25, max: -118.18 },
                baseLat: 34.0522, baseLng: -118.2437
            },
            'venice': { 
                lat: { min: 34.04, max: 34.08 }, 
                lng: { min: -118.25, max: -118.18 },
                baseLat: 34.0522, baseLng: -118.2437
            },
            'melrose': { 
                lat: { min: 34.08, max: 34.12 }, 
                lng: { min: -118.35, max: -118.28 },
                baseLat: 34.0928, baseLng: -118.3287
            },
            'fairfax': { 
                lat: { min: 34.08, max: 34.12 }, 
                lng: { min: -118.35, max: -118.28 },
                baseLat: 34.0928, baseLng: -118.3287
            },
            'la brea': { 
                lat: { min: 34.08, max: 34.12 }, 
                lng: { min: -118.35, max: -118.28 },
                baseLat: 34.0928, baseLng: -118.3287
            },
            'la cienega': { 
                lat: { min: 34.08, max: 34.12 }, 
                lng: { min: -118.35, max: -118.28 },
                baseLat: 34.0928, baseLng: -118.3287
            },
            'robertson': { 
                lat: { min: 34.06, max: 34.09 }, 
                lng: { min: -118.42, max: -118.38 },
                baseLat: 34.0736, baseLng: -118.4004
            },
            'rodeo': { 
                lat: { min: 34.06, max: 34.09 }, 
                lng: { min: -118.42, max: -118.38 },
                baseLat: 34.0736, baseLng: -118.4004
            }
        };
    }

    // Smart geocoding that works like Google Maps
    async geocodeAddress(address) {
        console.log('Smart geocoding address:', address);
        
        // Check cache first
        const cached = this.getFromCache(address);
        if (cached) {
            return cached;
        }
        
        // Clean and normalize the address
        const cleanAddress = this.cleanAddress(address);
        
        // Hybrid strategy: try external APIs first, then local fallbacks
        const strategies = [
            // Try external APIs first (real geocoding like Google Maps)
            () => this.tryExternalAPIs(cleanAddress),
            () => this.tryExternalAPIs(address),
            // Local fallbacks if APIs fail
            () => this.tryExactMatch(cleanAddress),
            () => this.tryExactMatch(address),
            () => this.tryStreetPatternGeocoding(cleanAddress),
            () => this.tryStreetPatternGeocoding(address),
            () => this.tryNumberStreetGeocoding(cleanAddress),
            () => this.tryNumberStreetGeocoding(address),
            () => this.generateSmartCoordinates(cleanAddress),
            () => this.generateSmartCoordinates(address)
        ];

        for (const strategy of strategies) {
            try {
                const result = await strategy();
                if (result) {
                    this.addToCache(address, result);
                    return result;
                }
            } catch (error) {
                console.warn('Geocoding strategy failed:', error);
            }
        }

        // Final fallback
        const fallback = {
            lat: 34.0522,
            lng: -118.2437,
            name: address,
            confidence: 'low',
            source: 'fallback',
            note: 'Using Downtown LA as fallback'
        };
        
        this.addToCache(address, fallback);
        return fallback;
    }

    // Try external APIs with proper error handling and timeouts
    async tryExternalAPIs(address) {
        const apis = [
            // Try Google Maps first (most reliable)
            () => this.tryGoogleMapsAPI(address),
            // Fallback to free APIs
            () => this.tryNominatimAPI(address),
            () => this.tryPhotonAPI(address)
        ];

        for (const api of apis) {
            try {
                const result = await this.withTimeout(api(), 2000); // 2 second timeout
                if (result && result.lat && result.lng) {
                    console.log('External API success:', result.source);
                    return result;
                }
            } catch (error) {
                console.warn('External API failed:', error.message);
                // Continue to next API
            }
        }
        return null;
    }

    // Try Google Maps API (most reliable)
    async tryGoogleMapsAPI(address) {
        // Skip if no API key configured
        if (!this.googleApiKey || this.googleApiKey === 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
            console.log('Google Maps API key not configured, skipping...');
            return null;
        }

        try {
            const response = await fetch(
                `${this.apis.google}?address=${encodeURIComponent(address + ', Los Angeles, CA')}&key=${this.googleApiKey}`
            );
            
            if (response.ok) {
                const data = await response.json();
                if (data.status === 'OK' && data.results && data.results.length > 0) {
                    const result = data.results[0];
                    return {
                        lat: result.geometry.location.lat,
                        lng: result.geometry.location.lng,
                        name: result.formatted_address,
                        confidence: 'high',
                        source: 'google_maps'
                    };
                }
            }
        } catch (error) {
            console.warn('Google Maps API failed:', error);
        }
        return null;
    }

    // Try Nominatim API with multiple query formats
    async tryNominatimAPI(address) {
        const queries = [
            `${address}, Los Angeles, CA, USA`,
            `${address}, Los Angeles, California`,
            `${address}, LA, CA`,
            address
        ];

        for (const query of queries) {
            try {
                const response = await fetch(
                    `${this.apis.nominatim}/search?format=json&q=${encodeURIComponent(query)}&limit=1&addressdetails=1&countrycodes=us`
                );
                
                if (response.ok) {
                    const data = await response.json();
                    if (data && data.length > 0) {
                        const result = data[0];
                        return {
                            lat: parseFloat(result.lat),
                            lng: parseFloat(result.lon),
                            name: result.display_name,
                            confidence: 'high',
                            source: 'nominatim'
                        };
                    }
                }
            } catch (error) {
                console.warn('Nominatim query failed:', query, error);
                // Continue to next query
            }
        }
        return null;
    }

    // Try Photon API
    async tryPhotonAPI(address) {
        try {
            const response = await fetch(
                `${this.apis.photon}/api/?q=${encodeURIComponent(address + ', Los Angeles, CA')}&limit=1`
            );
            
            if (response.ok) {
                const data = await response.json();
                if (data.features && data.features.length > 0) {
                    const feature = data.features[0];
                    return {
                        lat: feature.geometry.coordinates[1],
                        lng: feature.geometry.coordinates[0],
                        name: feature.properties.name || feature.properties.label || address,
                        confidence: 'high',
                        source: 'photon'
                    };
                }
            }
        } catch (error) {
            console.warn('Photon API failed:', error);
        }
        return null;
    }

    // Try exact match from our database
    tryExactMatch(address) {
        const lowerAddress = address.toLowerCase();
        
        // Direct matches
        for (const [key, location] of Object.entries(this.localGeocodingDB)) {
            if (lowerAddress.includes(key) || key.includes(lowerAddress)) {
                return {
                    ...location,
                    confidence: 'high',
                    source: 'exact_match'
                };
            }
        }
        
        return null;
    }

    // Smart street pattern geocoding
    tryStreetPatternGeocoding(address) {
        const lowerAddress = address.toLowerCase();
        
        // Check for street patterns
        for (const [streetName, range] of Object.entries(this.streetRanges)) {
            if (lowerAddress.includes(streetName)) {
                // Generate coordinates based on street and any numbers
                const numbers = address.match(/\d+/g);
                let lat = range.baseLat;
                let lng = range.baseLng;
                
                if (numbers && numbers.length > 0) {
                    const number = parseInt(numbers[0]);
                    const offset = (number % 1000) / 10000;
                    lat += offset;
                    lng += offset;
                }
                
                return {
                    lat: lat,
                    lng: lng,
                    name: address,
                    confidence: 'medium',
                    source: 'street_pattern',
                    note: `Generated coordinates for ${streetName}`
                };
            }
        }
        
        return null;
    }

    // Smart number + street geocoding
    tryNumberStreetGeocoding(address) {
        // Match patterns like "3105 Normandie Avenue"
        const patterns = [
            /(\d+)\s+([A-Za-z\s]+)\s+(Street|St|Avenue|Ave|Boulevard|Blvd|Road|Rd|Drive|Dr|Lane|Ln|Place|Pl|Court|Ct)/i,
            /(\d+)\s+([A-Za-z\s]+)/i
        ];

        for (const pattern of patterns) {
            const match = address.match(pattern);
            if (match) {
                const number = parseInt(match[1]);
                const street = match[2].trim().toLowerCase();
                
                // Find the street in our ranges
                for (const [streetName, range] of Object.entries(this.streetRanges)) {
                    if (street.includes(streetName) || streetName.includes(street)) {
                        const offset = (number % 1000) / 10000;
                        const lat = range.baseLat + offset;
                        const lng = range.baseLng + offset;
                        
                        return {
                            lat: lat,
                            lng: lng,
                            name: address,
                            confidence: 'medium',
                            source: 'number_street',
                            note: `Generated coordinates for ${number} ${streetName}`
                        };
                    }
                }
                
                // If street not found, generate based on number
                const offset = (number % 1000) / 10000;
                return {
                    lat: 34.0522 + offset,
                    lng: -118.2437 + offset,
                    name: address,
                    confidence: 'medium',
                    source: 'number_generated',
                    note: `Generated coordinates based on number ${number}`
                };
            }
        }
        
        return null;
    }

    // Generate smart coordinates for any address
    generateSmartCoordinates(address) {
        const numbers = address.match(/\d+/g);
        const lowerAddress = address.toLowerCase();
        
        if (numbers && numbers.length > 0) {
            const number = parseInt(numbers[0]);
            const offset = (number % 1000) / 10000;
            
            // Try to determine area based on address content
            let baseLat = 34.0522; // Downtown LA
            let baseLng = -118.2437;
            
            if (lowerAddress.includes('hollywood') || lowerAddress.includes('sunset') || 
                lowerAddress.includes('melrose') || lowerAddress.includes('fairfax')) {
                baseLat = 34.0928;
                baseLng = -118.3287;
            } else if (lowerAddress.includes('beverly hills') || lowerAddress.includes('rodeo') || 
                       lowerAddress.includes('robertson')) {
                baseLat = 34.0736;
                baseLng = -118.4004;
            } else if (lowerAddress.includes('santa monica') || lowerAddress.includes('venice')) {
                baseLat = 34.0195;
                baseLng = -118.4912;
            }
            
            return {
                lat: baseLat + offset,
                lng: baseLng + offset,
                name: address,
                confidence: 'low',
                source: 'smart_generation',
                note: `Generated coordinates based on address content`
            };
        }
        
        // If no numbers, return Downtown LA
        return {
            lat: 34.0522,
            lng: -118.2437,
            name: address,
            confidence: 'low',
            source: 'default_location',
            note: 'Using Downtown LA as default'
        };
    }

    // Clean and normalize address
    cleanAddress(address) {
        return address
            .replace(/,\s*Los Angeles County,\s*California,\s*\d{5},\s*United States/gi, '')
            .replace(/,\s*Los Angeles,\s*Los Angeles County,\s*California/gi, ', Los Angeles, CA')
            .replace(/,\s*California,\s*\d{5}/gi, ', CA')
            .replace(/,\s*United States/gi, '')
            .replace(/,\s*CA\s*\d{5}/gi, ', CA')
            .trim();
    }

    // Cache management
    getFromCache(address) {
        const cached = this.cache.get(address);
        if (cached && Date.now() - cached.timestamp < this.cacheTimeout) {
            return cached.data;
        }
        return null;
    }

    addToCache(address, data) {
        this.cache.set(address, {
            data: data,
            timestamp: Date.now()
        });
    }

    // Hybrid address suggestions: try Photon first, then local fallback
    async getAddressSuggestions(query) {
        if (query.length < 2) return [];

        const cacheKey = `suggestions_${query}`;
        const cached = this.getFromCache(cacheKey);
        if (cached) {
            return cached;
        }

        const cleanQuery = this.cleanAddress(query);
        let suggestions = [];
        
        // Try Photon API first (fast and reliable)
        if (this.apiConfig.photon.enabled) {
            try {
                const photonSuggestions = await this.getPhotonSuggestions(cleanQuery);
                if (photonSuggestions.length > 0) {
                    suggestions = photonSuggestions;
                    console.log('Using Photon suggestions');
                }
            } catch (error) {
                console.warn('Photon suggestions failed, using local fallback:', error);
            }
        }
        
        // Fallback to local suggestions if Photon fails or returns no results
        if (suggestions.length === 0) {
            suggestions = this.getLocalSuggestions(cleanQuery);
            console.log('Using local suggestions');
        }

        const sortedSuggestions = suggestions
            .sort((a, b) => b.relevance - a.relevance)
            .slice(0, 5);

        this.addToCache(cacheKey, sortedSuggestions);
        return sortedSuggestions;
    }

    // Get suggestions from external APIs
    async getExternalSuggestions(query) {
        // Try Google Places API first (if enabled)
        if (this.apiConfig.googleMaps.enabled && this.apiConfig.googleMaps.apiKey) {
            try {
                const googleSuggestions = await this.getGooglePlacesSuggestions(query);
                if (googleSuggestions.length > 0) {
                    return googleSuggestions;
                }
            } catch (error) {
                console.warn('Google Places suggestions failed:', error);
            }
        }
        
        // Try Photon API
        if (this.apiConfig.photon.enabled) {
            try {
                const photonSuggestions = await this.getPhotonSuggestions(query);
                if (photonSuggestions.length > 0) {
                    return photonSuggestions;
                }
            } catch (error) {
                console.warn('Photon suggestions failed:', error);
            }
        }
        
        // Fallback to Nominatim
        try {
            const response = await fetch(
                `${this.apis.nominatim}/search?format=json&q=${encodeURIComponent(query + ', Los Angeles, CA')}&limit=5&addressdetails=1&countrycodes=us`,
                { 
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                        'User-Agent': 'LA-Transit-App/1.0'
                    }
                }
            );
            
            if (response.ok) {
                const data = await response.json();
                if (data && Array.isArray(data)) {
                    return data.map(item => ({
                        address: item.display_name,
                        lat: parseFloat(item.lat),
                        lng: parseFloat(item.lon),
                        relevance: this.calculateRelevance(item.display_name, query) + 200
                    }));
                }
            }
        } catch (error) {
            console.warn('Nominatim suggestions failed:', error);
        }
        return [];
    }

    // Get Google Places suggestions with rich POI data
    async getGooglePlacesSuggestions(query) {
        const apiKey = this.apiConfig.googleMaps.apiKey;
        const url = `${this.apis.googlePlaces}/autocomplete/json?input=${encodeURIComponent(query)}&types=establishment|geocode&location=34.0522,-118.2437&radius=50000&key=${apiKey}`;
        
        const response = await fetch(url);
        const data = await response.json();
        
        if (data.predictions) {
            const suggestions = [];
            for (const prediction of data.predictions.slice(0, 5)) {
                // Get place details for rich POI data
                const placeDetails = await this.getGooglePlaceDetails(prediction.place_id);
                
                suggestions.push({
                    address: prediction.description,
                    lat: placeDetails.geometry?.location?.lat || 0,
                    lng: placeDetails.geometry?.location?.lng || 0,
                    relevance: this.calculateRelevance(prediction.description, query) + 300,
                    poi: placeDetails
                });
            }
            return suggestions;
        }
        return [];
    }

    // Get Google Place details with rich POI data
    async getGooglePlaceDetails(placeId) {
        const apiKey = this.apiConfig.googleMaps.apiKey;
        const url = `${this.apis.googlePlaces}/details/json?place_id=${placeId}&fields=name,geometry,rating,photos,reviews,formatted_address,types&key=${apiKey}`;
        
        const response = await fetch(url);
        const data = await response.json();
        
        return data.result || {};
    }

    // Get Photon suggestions
    async getPhotonSuggestions(query) {
        const url = `${this.apis.photon}/api?q=${encodeURIComponent(query + ', Los Angeles, CA')}&limit=5`;
        
        const response = await fetch(url);
        const data = await response.json();
        
        if (data.features) {
            return data.features.map(feature => ({
                address: feature.properties.name || feature.properties.display_name,
                lat: feature.geometry.coordinates[1],
                lng: feature.geometry.coordinates[0],
                relevance: this.calculateRelevance(feature.properties.name || feature.properties.display_name, query) + 250
            }));
        }
        return [];
    }

    // Get Street View data
    async getStreetViewData(lat, lng) {
        if (!this.apiConfig.googleMaps.enabled || !this.apiConfig.googleMaps.apiKey) {
            return null;
        }

        try {
            const apiKey = this.apiConfig.googleMaps.apiKey;
            const url = `${this.apis.googleMaps}/streetview?size=400x300&location=${lat},${lng}&key=${apiKey}`;
            
            // Check if Street View is available
            const metadataUrl = `${this.apis.googleMaps}/streetview/metadata?location=${lat},${lng}&key=${apiKey}`;
            const metadataResponse = await fetch(metadataUrl);
            const metadata = await metadataResponse.json();
            
            if (metadata.status === 'OK') {
                return {
                    imageUrl: url,
                    heading: metadata.location?.heading || 0,
                    pitch: metadata.location?.pitch || 0,
                    available: true
                };
            }
        } catch (error) {
            console.warn('Street View data failed:', error);
        }
        
        return { available: false };
    }

    // Get rich POI information
    async getRichPOIData(lat, lng, query) {
        const poiData = {
            nearby: [],
            photos: [],
            reviews: [],
            streetview: null
        };

        // Get Street View
        poiData.streetview = await this.getStreetViewData(lat, lng);

        // Get nearby places (if Google Maps enabled)
        if (this.apiConfig.googleMaps.enabled && this.apiConfig.googleMaps.apiKey) {
            try {
                const apiKey = this.apiConfig.googleMaps.apiKey;
                const radius = this.apiConfig.googleMaps.nearbySearchRadius;
                const maxResults = this.apiConfig.googleMaps.maxNearbyResults;
                const url = `${this.apis.googlePlaces}/nearbysearch/json?location=${lat},${lng}&radius=${radius}&key=${apiKey}`;
                
                const response = await fetch(url);
                const data = await response.json();
                
                if (data.results) {
                    poiData.nearby = data.results.slice(0, maxResults).map(place => ({
                        name: place.name,
                        rating: place.rating,
                        types: place.types,
                        photos: place.photos?.length || 0,
                        reviews: place.user_ratings_total || 0,
                        distance: this.calculateDistance(lat, lng, place.geometry.location.lat, place.geometry.location.lng)
                    }));
                }
            } catch (error) {
                console.warn('Nearby places failed:', error);
            }
        }

        return poiData;
    }

    // Enable Google Maps integration
    enableGoogleMaps(apiKey) {
        if (!apiKey || apiKey.trim() === '') {
            console.warn('Google Maps API key is required');
            return false;
        }
        
        this.apiConfig.googleMaps.enabled = true;
        this.apiConfig.googleMaps.apiKey = apiKey;
        console.log('✅ Google Maps integration enabled');
        return true;
    }

    // Disable Google Maps integration
    disableGoogleMaps() {
        this.apiConfig.googleMaps.enabled = false;
        this.apiConfig.googleMaps.apiKey = '';
        console.log('❌ Google Maps integration disabled');
    }

    // Check if Google Maps is enabled
    isGoogleMapsEnabled() {
        return this.apiConfig.googleMaps.enabled && this.apiConfig.googleMaps.apiKey;
    }

    // Get local suggestions as fallback
    getLocalSuggestions(query) {
        const suggestions = [];
        const lowerQuery = query.toLowerCase();
        
        // Enhanced local database with popular landmarks and businesses
        const enhancedLocalDB = {
            // Universities and Colleges
            'university of southern california': { lat: 34.0224, lng: -118.2851, name: 'University of Southern California (USC), Los Angeles, CA' },
            'usc': { lat: 34.0224, lng: -118.2851, name: 'University of Southern California (USC), Los Angeles, CA' },
            'ucla': { lat: 34.0689, lng: -118.4452, name: 'University of California, Los Angeles (UCLA), Los Angeles, CA' },
            'california state university': { lat: 34.0669, lng: -118.1689, name: 'California State University, Los Angeles, CA' },
            'cal state la': { lat: 34.0669, lng: -118.1689, name: 'California State University, Los Angeles, CA' },
            'loyola marymount': { lat: 33.9701, lng: -118.4170, name: 'Loyola Marymount University, Los Angeles, CA' },
            'pepperdine': { lat: 34.0371, lng: -118.7064, name: 'Pepperdine University, Malibu, CA' },
            
            // Major Landmarks and Attractions
            'hollywood sign': { lat: 34.1341, lng: -118.3216, name: 'Hollywood Sign, Los Angeles, CA' },
            'griffith observatory': { lat: 34.1185, lng: -118.3004, name: 'Griffith Observatory, Los Angeles, CA' },
            'santa monica pier': { lat: 34.0089, lng: -118.5001, name: 'Santa Monica Pier, Santa Monica, CA' },
            'venice beach': { lat: 33.9850, lng: -118.4695, name: 'Venice Beach, Los Angeles, CA' },
            'disneyland': { lat: 33.8121, lng: -117.9190, name: 'Disneyland Resort, Anaheim, CA' },
            'universal studios': { lat: 34.1381, lng: -118.3534, name: 'Universal Studios Hollywood, Los Angeles, CA' },
            'getty center': { lat: 34.0780, lng: -118.4743, name: 'The Getty Center, Los Angeles, CA' },
            'lacma': { lat: 34.0637, lng: -118.3595, name: 'Los Angeles County Museum of Art (LACMA), Los Angeles, CA' },
            'natural history museum': { lat: 34.0169, lng: -118.2884, name: 'Natural History Museum of Los Angeles County, Los Angeles, CA' },
            
            // Major Airports
            'lax': { lat: 33.9416, lng: -118.4085, name: 'Los Angeles International Airport (LAX), Los Angeles, CA' },
            'los angeles international airport': { lat: 33.9416, lng: -118.4085, name: 'Los Angeles International Airport (LAX), Los Angeles, CA' },
            'burbank airport': { lat: 34.2006, lng: -118.3587, name: 'Hollywood Burbank Airport, Burbank, CA' },
            'john wayne airport': { lat: 33.6762, lng: -117.8677, name: 'John Wayne Airport, Santa Ana, CA' },
            
            // Major Shopping Centers
            'the grove': { lat: 34.0762, lng: -118.3587, name: 'The Grove, Los Angeles, CA' },
            'beverly center': { lat: 34.0762, lng: -118.3770, name: 'Beverly Center, Los Angeles, CA' },
            'century city': { lat: 34.0556, lng: -118.4170, name: 'Century City, Los Angeles, CA' },
            'south coast plaza': { lat: 33.6889, lng: -117.8847, name: 'South Coast Plaza, Costa Mesa, CA' },
            
            // Major Hospitals
            'cedars sinai': { lat: 34.0762, lng: -118.3770, name: 'Cedars-Sinai Medical Center, Los Angeles, CA' },
            'ucla medical center': { lat: 34.0669, lng: -118.4452, name: 'UCLA Medical Center, Los Angeles, CA' },
            'usc medical center': { lat: 34.0224, lng: -118.2851, name: 'USC Medical Center, Los Angeles, CA' },
            
            // Major Business Districts
            'downtown la': { lat: 34.0522, lng: -118.2437, name: 'Downtown Los Angeles, CA' },
            'downtown los angeles': { lat: 34.0522, lng: -118.2437, name: 'Downtown Los Angeles, CA' },
            'century city': { lat: 34.0556, lng: -118.4170, name: 'Century City, Los Angeles, CA' },
            'beverly hills': { lat: 34.0736, lng: -118.4004, name: 'Beverly Hills, CA' },
            'santa monica': { lat: 34.0195, lng: -118.4912, name: 'Santa Monica, CA' },
            'pasadena': { lat: 34.1478, lng: -118.1445, name: 'Pasadena, CA' },
            'glendale': { lat: 34.1425, lng: -118.2551, name: 'Glendale, CA' },
            'culver city': { lat: 34.0211, lng: -118.3965, name: 'Culver City, CA' },
            
            // Major Transit Hubs
            'union station': { lat: 34.0560, lng: -118.2340, name: 'Union Station, Los Angeles, CA' },
            'grand central market': { lat: 34.0505, lng: -118.2487, name: 'Grand Central Market, Los Angeles, CA' },
            
            // Popular Restaurants and Chains
            'in-n-out': { lat: 34.0522, lng: -118.2437, name: 'In-N-Out Burger, Los Angeles, CA' },
            'shake shack': { lat: 34.0522, lng: -118.2437, name: 'Shake Shack, Los Angeles, CA' },
            'chipotle': { lat: 34.0522, lng: -118.2437, name: 'Chipotle Mexican Grill, Los Angeles, CA' },
            
            // Sports Venues
            'dodger stadium': { lat: 34.0736, lng: -118.2400, name: 'Dodger Stadium, Los Angeles, CA' },
            'staple center': { lat: 34.0430, lng: -118.2673, name: 'Crypto.com Arena (formerly Staples Center), Los Angeles, CA' },
            'crypto.com arena': { lat: 34.0430, lng: -118.2673, name: 'Crypto.com Arena, Los Angeles, CA' },
            'sofi stadium': { lat: 33.9533, lng: -118.3387, name: 'SoFi Stadium, Inglewood, CA' },
            
            // Original database entries
            ...this.localGeocodingDB
        };
        
        // Direct matches from enhanced database
        for (const [key, location] of Object.entries(enhancedLocalDB)) {
            if (key.includes(lowerQuery) || lowerQuery.includes(key)) {
                suggestions.push({
                    address: location.name,
                    lat: location.lat,
                    lng: location.lng,
                    relevance: this.calculateRelevance(location.name, query) + 100
                });
            }
        }
        
        // Generate suggestions for number patterns
        const numberMatch = query.match(/(\d+)/);
        if (numberMatch) {
            const number = numberMatch[1];
            const commonStreets = [
                'Main St', 'Figueroa St', 'Sunset Blvd', 'Wilshire Blvd', 
                'Normandie Ave', 'Broadway', 'Olympic Blvd', 'Pico Blvd',
                'Venice Blvd', 'Santa Monica Blvd', 'Melrose Ave', 'Fairfax Ave',
                'La Brea Ave', 'La Cienega Blvd', 'Robertson Blvd', 'Rodeo Drive',
                '24th St', '23rd St', '22nd St', '21st St', '20th St', '19th St', '18th St',
                '17th St', '16th St', '15th St', '14th St', '13th St', '12th St', '11th St',
                '10th St', '9th St', '8th St', '7th St', '6th St', '5th St', '4th St', '3rd St',
                '2nd St', '1st St', 'Adams Blvd', 'Washington Blvd', 'Jefferson Blvd',
                'Slauson Ave', 'Florence Ave', 'Manchester Ave', 'Century Blvd',
                'Imperial Hwy', 'Sepulveda Blvd', 'Crenshaw Blvd', 'Western Ave',
                'Vermont Ave', 'Hoover St', 'Alameda St', 'Central Ave', 'Atlantic Blvd'
            ];
            
            // Extract street name from query (remove number and common words)
            const queryWithoutNumber = lowerQuery.replace(number, '').trim();
            const streetWords = queryWithoutNumber.split(/\s+/).filter(word => 
                word.length > 1 && !['w', 'e', 'n', 's', 'west', 'east', 'north', 'south', 'st', 'street', 'ave', 'avenue', 'blvd', 'boulevard', 'dr', 'drive', 'rd', 'road', 'ln', 'lane', 'pl', 'place', 'ct', 'court'].includes(word)
            );
            
            commonStreets.forEach(street => {
                const streetLower = street.toLowerCase();
                const streetWordsLower = streetWords.join(' ');
                
                // Check if query matches this street
                const isMatch = streetLower.includes(streetWordsLower) || 
                               streetWordsLower.includes(streetLower.split(' ')[0]) ||
                               streetWords.some(word => streetLower.includes(word)) ||
                               (queryWithoutNumber.length > 0 && streetLower.includes(queryWithoutNumber));
                
                if (isMatch) {
                    const numberOffset = (parseInt(number) % 1000) / 10000;
                    let baseLat = 34.0522, baseLng = -118.2437;
                    
                    // Set appropriate base coordinates for different areas
                    if (streetLower.includes('sunset') || streetLower.includes('melrose') || 
                        streetLower.includes('fairfax') || streetLower.includes('la brea')) {
                        baseLat = 34.0928;
                        baseLng = -118.3287;
                    } else if (streetLower.includes('rodeo') || streetLower.includes('robertson')) {
                        baseLat = 34.0736;
                        baseLng = -118.4004;
                    } else if (streetLower.includes('24th') || streetLower.includes('23rd') || 
                               streetLower.includes('22nd') || streetLower.includes('21st')) {
                        baseLat = 34.0322;
                        baseLng = -118.2837;
                    } else if (streetLower.includes('figueroa')) {
                        baseLat = 34.0522;
                        baseLng = -118.2437;
                    } else if (streetLower.includes('main')) {
                        baseLat = 34.0522;
                        baseLng = -118.2437;
                    }
                    
                    suggestions.push({
                        address: `${number} ${street}, Los Angeles, CA`,
                        lat: baseLat + numberOffset,
                        lng: baseLng + numberOffset,
                        relevance: this.calculateRelevance(`${number} ${street}`, query) + 80
                    });
                }
            });
            
            // If no specific street match, generate generic suggestions
            if (suggestions.length === 0) {
                const numberOffset = (parseInt(number) % 1000) / 10000;
                suggestions.push({
                    address: `${number} Street, Los Angeles, CA`,
                    lat: 34.0522 + numberOffset,
                    lng: -118.2437 + numberOffset,
                    relevance: this.calculateRelevance(`${number} Street`, query) + 60
                });
            }
        }
        
        // Generate suggestions for partial street names
        const streetKeywords = [
            'main', 'figueroa', 'sunset', 'wilshire', 'normandie', 'broadway',
            'olympic', 'pico', 'venice', 'santa monica', 'melrose', 'fairfax',
            'la brea', 'la cienega', 'robertson', 'rodeo', 'hollywood', 'beverly hills',
            '24th', '23rd', '22nd', '21st', '20th', '19th', '18th', '17th', '16th', '15th',
            '14th', '13th', '12th', '11th', '10th', '9th', '8th', '7th', '6th', '5th', '4th', '3rd', '2nd', '1st',
            'adams', 'washington', 'jefferson', 'slauson', 'florence', 'manchester', 'century',
            'imperial', 'sepulveda', 'crenshaw', 'western', 'vermont', 'hoover', 'alameda', 'central', 'atlantic'
        ];
        
        streetKeywords.forEach(keyword => {
            if (lowerQuery.includes(keyword)) {
                const streetData = this.localGeocodingDB[keyword] || { 
                    lat: 34.0522, 
                    lng: -118.2437, 
                    name: `${keyword.charAt(0).toUpperCase() + keyword.slice(1)} Street, Los Angeles` 
                };
                
                suggestions.push({
                    address: streetData.name,
                    lat: streetData.lat,
                    lng: streetData.lng,
                    relevance: this.calculateRelevance(streetData.name, query) + 60
                });
            }
        });
        
        // Generate suggestions for partial landmark names
        const landmarkKeywords = [
            'university', 'college', 'airport', 'stadium', 'museum', 'pier', 'beach',
            'center', 'hospital', 'shopping', 'mall', 'restaurant', 'hotel'
        ];
        
        landmarkKeywords.forEach(keyword => {
            if (lowerQuery.includes(keyword)) {
                // Find matching landmarks in enhanced database
                for (const [key, location] of Object.entries(enhancedLocalDB)) {
                    if (key.includes(keyword) && !suggestions.some(s => s.address === location.name)) {
                        suggestions.push({
                            address: location.name,
                            lat: location.lat,
                            lng: location.lng,
                            relevance: this.calculateRelevance(location.name, query) + 40
                        });
                    }
                }
            }
        });
        
        // Generate suggestions for partial business names
        const businessKeywords = [
            'in-n-out', 'shake shack', 'chipotle', 'starbucks', 'mcdonalds', 'burger king',
            'target', 'walmart', 'costco', 'home depot', 'lowes'
        ];
        
        businessKeywords.forEach(keyword => {
            if (lowerQuery.includes(keyword)) {
                const businessData = enhancedLocalDB[keyword] || {
                    lat: 34.0522,
                    lng: -118.2437,
                    name: `${keyword.charAt(0).toUpperCase() + keyword.slice(1)}, Los Angeles, CA`
                };
                
                suggestions.push({
                    address: businessData.name,
                    lat: businessData.lat,
                    lng: businessData.lng,
                    relevance: this.calculateRelevance(businessData.name, query) + 30
                });
            }
        });
        
        // Sort by relevance and return top 5
        const sortedSuggestions = suggestions
            .sort((a, b) => b.relevance - a.relevance)
            .slice(0, 5);

        return sortedSuggestions;
    }

    // Calculate relevance score
    calculateRelevance(displayName, query) {
        let score = 0;
        const displayLower = displayName.toLowerCase();
        const queryLower = query.toLowerCase();
        
        // Exact match gets highest score
        if (displayLower.includes(queryLower)) {
            score += 200;
        }
        
        // Partial matches with word boundaries
        const queryWords = queryLower.split(/\s+/).filter(word => word.length > 1);
        queryWords.forEach(word => {
            if (displayLower.includes(word)) {
                score += 50;
            }
            // Check for word boundaries (start of words)
            const wordBoundaryRegex = new RegExp(`\\b${word}`, 'i');
            if (wordBoundaryRegex.test(displayName)) {
                score += 30;
            }
        });
        
        // Boost for universities and colleges
        if (displayLower.includes('university') || displayLower.includes('college') || displayLower.includes('usc') || displayLower.includes('ucla')) {
            score += 25;
        }
        
        // Boost for major landmarks
        if (displayLower.includes('airport') || displayLower.includes('stadium') || displayLower.includes('museum') || 
            displayLower.includes('pier') || displayLower.includes('beach') || displayLower.includes('center')) {
            score += 20;
        }
        
        // Prefer addresses in Los Angeles
        if (displayLower.includes('los angeles') || displayLower.includes('california')) {
            score += 15;
        }
        
        // Prefer street addresses over POIs
        if (/\d+/.test(displayName)) {
            score += 10;
        }
        
        // Boost for shorter, more specific matches
        if (queryLower.length >= 3 && displayLower.startsWith(queryLower)) {
            score += 40;
        }
        
        return score;
    }

    // Rest of the methods remain the same...
    async reverseGeocode(lat, lng) {
        return {
            address: `${lat.toFixed(4)}, ${lng.toFixed(4)}`,
            confidence: 'low'
        };
    }

    async getRoute(origin, destination, mode = 'driving') {
        console.log('Getting route:', { origin, destination, mode });

        const [originCoords, destCoords] = await Promise.all([
            this.geocodeAddress(origin),
            this.geocodeAddress(destination)
        ]);

        const route = await this.getOSRMRoute(originCoords, destCoords, mode);
        
        return {
            origin: originCoords,
            destination: destCoords,
            route: route,
            mode: mode
        };
    }

    async getOSRMRoute(origin, destination, mode) {
        const profile = mode === 'walking' ? 'foot' : 
                       mode === 'cycling' ? 'bike' : 'driving';
        
        const url = `${this.osrmBaseUrl}/route/v1/${profile}/${origin.lng},${origin.lat};${destination.lng},${destination.lat}?overview=full&steps=true&annotations=true`;
        
        try {
            const response = await this.withTimeout(fetch(url), 5000);
            if (response.ok) {
                const data = await response.json();
                return this.formatOSRMRoute(data, origin, destination);
            }
        } catch (error) {
            console.warn('OSRM routing failed:', error);
        }

        return this.createSimpleRoute(origin, destination, mode);
    }

    formatOSRMRoute(data, origin, destination) {
        if (!data.routes || data.routes.length === 0) {
            throw new Error('No route found');
        }

        const route = data.routes[0];
        const steps = [];

        if (route.legs && route.legs[0] && route.legs[0].steps) {
            route.legs[0].steps.forEach((step, index) => {
                const stepData = {
                    instruction: step.maneuver?.instruction || 'Continue',
                    distance: step.distance || 0,
                    duration: step.duration || 0,
                    coordinates: [],
                    mode: 'walking'
                };
                
                if (step.geometry && step.geometry.coordinates) {
                    stepData.coordinates = step.geometry.coordinates.map(coord => ({
                        lat: coord[1],
                        lng: coord[0]
                    }));
                } else {
                    // Fallback coordinates
                    const prevStep = route.legs[0].steps[index - 1];
                    stepData.coordinates = [
                        { 
                            lat: prevStep?.geometry?.coordinates?.[1] || origin?.lat || 34.0522, 
                            lng: prevStep?.geometry?.coordinates?.[0] || origin?.lng || -118.2437 
                        },
                        { 
                            lat: step.geometry?.coordinates?.[1] || destination?.lat || 34.0522, 
                            lng: step.geometry?.coordinates?.[0] || destination?.lng || -118.2437 
                        }
                    ];
                }
                
                steps.push(stepData);
            });
        }

        let routeCoordinates = [];
        if (route.geometry && route.geometry.coordinates) {
            routeCoordinates = route.geometry.coordinates.map(coord => ({
                lat: coord[1],
                lng: coord[0]
            }));
        } else {
            // Fallback coordinates
            routeCoordinates = [
                { lat: origin?.lat || 34.0522, lng: origin?.lng || -118.2437 },
                { lat: destination?.lat || 34.0522, lng: destination?.lng || -118.2437 }
            ];
        }

        return {
            distance: route.distance || 0,
            duration: route.duration || 0,
            steps: steps,
            coordinates: routeCoordinates
        };
    }

    createSimpleRoute(origin, destination, mode) {
        const distance = this.calculateDistance(origin, destination);
        const duration = this.estimateDuration(distance, mode);
        
        return {
            distance: distance,
            duration: duration,
            steps: [{
                instruction: `Go from ${origin.name} to ${destination.name}`,
                distance: distance,
                duration: duration,
                coordinates: [origin, destination],
                mode: mode
            }],
            coordinates: [origin, destination]
        };
    }

    calculateDistance(point1, point2) {
        const R = 6371;
        const dLat = (point2.lat - point1.lat) * Math.PI / 180;
        const dLng = (point2.lng - point1.lng) * Math.PI / 180;
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                  Math.cos(point1.lat * Math.PI / 180) * Math.cos(point2.lat * Math.PI / 180) *
                  Math.sin(dLng/2) * Math.sin(dLng/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c * 1000;
    }

    estimateDuration(distance, mode) {
        const speeds = {
            walking: 1.4,
            cycling: 4.2,
            driving: 13.9,
            transit: 8.3
        };
        
        return Math.round(distance / speeds[mode] || speeds.driving);
    }

    async withTimeout(promise, timeout) {
        return Promise.race([
            promise,
            new Promise((_, reject) => 
                setTimeout(() => reject(new Error('Timeout')), timeout)
            )
        ]);
    }

    // Multi-modal routing methods
    async getMultiModalRoute(origin, destination, preferences = {}) {
        const routes = [];
        
        if (preferences.walking !== false) {
            try {
                const walkingRoute = await this.getRoute(origin, destination, 'walking');
                routes.push({
                    ...walkingRoute,
                    mode: 'walking',
                    cost: 0,
                    eco_friendly: true
                });
            } catch (error) {
                console.warn('Walking route failed:', error);
            }
        }

        if (preferences.driving !== false) {
            try {
                const drivingRoute = await this.getRoute(origin, destination, 'driving');
                routes.push({
                    ...drivingRoute,
                    mode: 'driving',
                    cost: this.estimateDrivingCost(drivingRoute.route.distance),
                    eco_friendly: false
                });
            } catch (error) {
                console.warn('Driving route failed:', error);
            }
        }

        return routes.sort((a, b) => a.route.duration - b.route.duration);
    }

    estimateDrivingCost(distance) {
        const gasPrice = 4.5;
        const mpg = 25;
        const miles = distance * 0.000621371;
        return (miles / mpg) * gasPrice;
    }
}

// Export for use in main app
window.EnhancedRoutingSystem = EnhancedRoutingSystem;
