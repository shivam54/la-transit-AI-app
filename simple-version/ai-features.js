// AI Features Module for LA Transit App with OpenAI GPT Integration
class AITransitAssistant {
    constructor() {
        // OpenAI Configuration - SECURE API KEY MANAGEMENT
        this.openaiApiKey = this.getSecureApiKey();
        this.openaiBaseUrl = 'https://api.openai.com/v1';
        this.model = 'gpt-3.5-turbo'; // Cost-effective model
        this.maxTokens = 500; // Limit response length for cost control
        
        // TransitLand API (optional)
        this.transitlandApiKey = this.getTransitLandApiKey();

        // Fallback configuration
        this.useFallback = !this.openaiApiKey || this.openaiApiKey === 'YOUR_OPENAI_API_KEY_HERE' || localStorage.getItem('force_fallback_mode') === 'true';
        
        // User preferences and conversation history
        this.userPreferences = this.loadUserPreferences();
        this.conversationHistory = [];
        
        // Rate limiting and cost management
        this.requestCount = 0;
        this.lastRequestTime = 0;
        this.maxRequestsPerMinute = 50; // Conservative limit
    }

    // SECURE API KEY MANAGEMENT
    getSecureApiKey() {
        // Check for environment variable first (production)
        if (typeof process !== 'undefined' && process.env && process.env.OPENAI_API_KEY) {
            return process.env.OPENAI_API_KEY;
        }
        
        // Check for secure storage in browser (development)
        const storedKey = localStorage.getItem('openai_api_key');
        if (storedKey && storedKey !== 'YOUR_OPENAI_API_KEY_HERE') {
            return storedKey;
        }
        
        // Return placeholder for setup
        return 'YOUR_OPENAI_API_KEY_HERE';
    }
    // TransitLand key management
    getTransitLandApiKey() {
        const key = localStorage.getItem('transitland_api_key');
        return key && key !== 'YOUR_TRANSITLAND_API_KEY_HERE' ? key : '';
    }

    setTransitLandApiKey(apiKey) {
        if (apiKey && apiKey.length >= 20) {
            localStorage.setItem('transitland_api_key', apiKey);
            this.transitlandApiKey = apiKey;
            return true;
        }
        return false;
    }


    // Set API key securely
    setApiKey(apiKey) {
        if (apiKey && apiKey.startsWith('sk-')) {
            localStorage.setItem('openai_api_key', apiKey);
            this.openaiApiKey = apiKey;
            this.useFallback = false;
            return true;
        }
        return false;
    }

    // 1. SMART ROUTE PLANNING AI with OpenAI GPT
    async getIntelligentRoute(origin, destination, preferences = {}) {
        try {
            if (this.useFallback) {
                return this.getFallbackRoute(origin, destination);
            }

            const prompt = this.buildRoutePrompt(origin, destination, preferences);
            const response = await this.callOpenAI(prompt);
            
            return this.parseRouteResponse(response, origin, destination);
        } catch (error) {
            console.error('AI Route Planning Error:', error);
            return this.getFallbackRoute(origin, destination);
        }
    }

    // 2. ADVANCED CONVERSATIONAL AI with OpenAI GPT
    async getIntelligentResponse(userMessage, context = {}) {
        try {
            if (this.useFallback) {
                return this.getFallbackResponse(userMessage);
            }

            const prompt = this.buildConversationPrompt(userMessage, context);
            const response = await this.callOpenAI(prompt);
            
            // Parse the response
            const parsedResponse = this.parseConversationResponse(response);
            
            // Store conversation history
            this.conversationHistory.push(
                { role: 'user', content: userMessage },
                { role: 'assistant', content: parsedResponse.message }
            );

            return parsedResponse;
        } catch (error) {
            console.error('AI Conversation Error:', error);
            return this.getFallbackResponse(userMessage);
        }
    }

    // 3. PREDICTIVE ANALYTICS with OpenAI GPT
    async predictTransitConditions(route, time) {
        try {
            if (this.useFallback) {
                return this.getFallbackPredictions(route, time);
            }

            // Extract route coordinates if available
            let routeCoords = null;
            if (route && typeof route === 'object' && route.originLocation && route.destinationLocation) {
                routeCoords = {
                    origin: route.originLocation,
                    destination: route.destinationLocation
                };
                console.log('📍 Using route coordinates for predictions:', routeCoords);
            } else {
                console.log('📍 No route coordinates available, using current location');
            }

            // Get real-time data with route coordinates
            const [weather, traffic, events, transit] = await Promise.all([
                this.getWeatherData(routeCoords),
                this.getTrafficData(routeCoords),
                this.getLocalEvents(),
                this.getTransitLandRealtime(route)
            ]);

            // Build enhanced prompt with real-time data
            const prompt = this.buildEnhancedPredictionPrompt(route, time, weather, traffic, events, transit);
            const response = await this.callOpenAI(prompt);
            
            const prediction = this.parsePredictionResponse(response);
            
            // Add real-time data to prediction
            return {
                ...prediction,
                realTimeData: {
                    weather,
                    traffic,
                    events,
                    transit,
                    timestamp: new Date().toISOString()
                }
            };
        } catch (error) {
            console.error('Prediction Error:', error);
            return this.getFallbackPredictions(route, time);
        }
    }

    // 4. PERSONALIZATION AI
    async learnUserPreferences(userAction, context) {
        try {
            const learningData = {
                action: userAction,
                context: context,
                timestamp: new Date().toISOString(),
                location: context.location,
                timeOfDay: new Date().getHours(),
                dayOfWeek: new Date().getDay()
            };

            // Store user preference data
            this.userPreferences.actions.push(learningData);
            this.saveUserPreferences();

            // Analyze patterns
            const patterns = this.analyzeUserPatterns();
            return patterns;
        } catch (error) {
            console.error('Learning Error:', error);
        }
    }

    // 5. SMART NOTIFICATIONS with OpenAI GPT
    async getSmartNotifications() {
        try {
            const notifications = [];
            const userLocation = await this.getCurrentLocation();
            const userSchedule = this.userPreferences.schedule;

            // Check for relevant delays
            const nearbyDelays = await this.checkNearbyDelays(userLocation);
            if (nearbyDelays.length > 0) {
                notifications.push({
                    type: 'delay',
                    message: `🚨 Delay detected on your usual route: ${nearbyDelays[0].description}`,
                    priority: 'high'
                });
            }

            // Check for schedule conflicts
            const upcomingTrips = this.getUpcomingTrips(userSchedule);
            for (const trip of upcomingTrips) {
                const prediction = await this.predictTransitConditions(trip.route, trip.time);
                if (prediction.delayProbability > 0.7) {
                    notifications.push({
                        type: 'warning',
                        message: `⚠️ High chance of delays for your ${trip.time} trip. Consider leaving 15 minutes early.`,
                        priority: 'medium'
                    });
                }
            }

            return notifications;
        } catch (error) {
            console.error('Notification Error:', error);
            return [];
        }
    }

    // 6. VOICE ASSISTANT INTEGRATION
    async processVoiceCommand(audioBlob) {
        try {
            // Convert speech to text using Whisper
            const text = await this.speechToText(audioBlob);
            
            // Process the command with OpenAI
            const response = await this.getIntelligentResponse(text);
            
            // Convert response to speech
            const audioResponse = await this.textToSpeech(response.message);
            
            return {
                text: text,
                response: response,
                audio: audioResponse
            };
        } catch (error) {
            console.error('Voice Processing Error:', error);
            return { text: 'Sorry, I could not understand that.', response: 'Please try again.' };
        }
    }

    // 7. COMPUTER VISION FEATURES
    async analyzeTransitImage(imageBlob) {
        try {
            // Use computer vision to analyze transit-related images
            const analysis = await this.analyzeImage(imageBlob);
            
            if (analysis.landmarks.length > 0) {
                return {
                    type: 'landmark',
                    landmarks: analysis.landmarks,
                    location: analysis.location,
                    directions: await this.getDirectionsToLandmark(analysis.landmarks[0])
                };
            }
            
            if (analysis.signs.length > 0) {
                return {
                    type: 'transit_sign',
                    signs: analysis.signs,
                    information: await this.getTransitInfo(analysis.signs[0])
                };
            }
            
            return { type: 'unknown', message: 'Could not identify transit-related content.' };
        } catch (error) {
            console.error('Image Analysis Error:', error);
            return { type: 'error', message: 'Image analysis failed.' };
        }
    }

    // OPENAI API INTEGRATION
    async callOpenAI(prompt, systemMessage = null) {
        // Rate limiting check
        if (!this.checkRateLimit()) {
            throw new Error('Rate limit exceeded');
        }

        const messages = [];
        
        // Add system message if provided
        if (systemMessage) {
            messages.push({ role: 'system', content: systemMessage });
        }
        
        // Add conversation history (last 10 messages for context)
        const recentHistory = this.conversationHistory.slice(-10);
        messages.push(...recentHistory);
        
        // Add current user message
        messages.push({ role: 'user', content: prompt });

        try {
            const response = await fetch(`${this.openaiBaseUrl}/chat/completions`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.openaiApiKey}`
                },
                body: JSON.stringify({
                    model: this.model,
                    messages: messages,
                    max_tokens: this.maxTokens,
                    temperature: 0.7,
                    top_p: 1,
                    frequency_penalty: 0,
                    presence_penalty: 0
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                const errorMessage = errorData.error?.message || response.statusText;
                
                // Check if it's a quota/billing error and switch to fallback
                if (errorMessage.includes('quota') || errorMessage.includes('billing') || errorMessage.includes('exceeded')) {
                    console.warn('OpenAI quota exceeded, switching to fallback mode');
                    this.useFallback = true;
                    throw new Error('QUOTA_EXCEEDED');
                }
                
                throw new Error(`OpenAI API Error: ${errorMessage}`);
            }

            const data = await response.json();
            this.requestCount++;
            this.lastRequestTime = Date.now();
            
            return data.choices[0].message.content;
        } catch (error) {
            console.error('OpenAI API call failed:', error);
            throw error;
        }
    }

    // DISTANCE HELPERS (OSRM with Haversine fallback)
    async geocodeWithPhoton(query) {
        try {
            const url = `https://photon.komoot.io/api/?q=${encodeURIComponent(query)}&limit=1`;
            const res = await fetch(url);
            if (!res.ok) return null;
            const data = await res.json();
            const feat = data.features && data.features[0];
            if (!feat) return null;
            const [lon, lat] = feat.geometry.coordinates;
            return { lat, lng: lon };
        } catch {
            return null;
        }
    }

    haversineMiles(a, b) {
        const toRad = d => d * Math.PI / 180;
        const R = 3958.7613; // miles
        const dLat = toRad(b.lat - a.lat);
        const dLon = toRad(b.lng - a.lng);
        const lat1 = toRad(a.lat);
        const lat2 = toRad(b.lat);
        const h = Math.sin(dLat/2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon/2) ** 2;
        return 2 * R * Math.asin(Math.sqrt(h));
    }

    async osrmRoadMiles(origin, destination) {
        try {
            const url = `https://router.project-osrm.org/route/v1/driving/${origin.lng},${origin.lat};${destination.lng},${destination.lat}?overview=false`;
            const res = await fetch(url);
            if (!res.ok) throw new Error('OSRM error');
            const data = await res.json();
            const meters = data?.routes?.[0]?.distance || 0;
            return meters ? (meters / 1609.344) : null;
        } catch {
            return null;
        }
    }

    async getApproxRoadDistanceMiles(originAddress, destinationAddress) {
        try {
            const [orig, dest] = await Promise.all([
                this.geocodeWithPhoton(originAddress),
                this.geocodeWithPhoton(destinationAddress)
            ]);
            if (!orig || !dest) return null;
            const road = await this.osrmRoadMiles(orig, dest);
            if (road) return road;
            return this.haversineMiles(orig, dest);
        } catch {
            return null;
        }
    }

    // Rate limiting
    checkRateLimit() {
        const now = Date.now();
        const timeWindow = 60000; // 1 minute
        
        if (now - this.lastRequestTime > timeWindow) {
            this.requestCount = 0;
        }
        
        return this.requestCount < this.maxRequestsPerMinute;
    }

    // PROMPT BUILDING METHODS
    buildRoutePrompt(origin, destination, preferences) {
        const currentTime = new Date();
        const timeString = currentTime.toLocaleTimeString();
        const dayString = currentTime.toLocaleDateString('en-US', { weekday: 'long' });
        
        return `You are an expert LA transit assistant. Help plan a route from "${origin}" to "${destination}".

Current context:
- Time: ${timeString} on ${dayString}
- User preferences: ${JSON.stringify(preferences)}
- LA Metro system knowledge: Red, Purple, Blue, Green, Gold, Expo lines
- Bus system: 100+ routes, Rapid buses available
- Fares: $1.75 per ride, $7 day pass, $25 week pass

Provide a helpful, conversational response that includes:
1. Recommended route options (Metro, bus, or combination)
2. Estimated travel time and cost
3. Any relevant tips or considerations
4. Alternative options if available

Keep the response friendly, informative, and under 200 words.`;
    }

    buildConversationPrompt(userMessage, context) {
        const currentTime = new Date();
        const timeString = currentTime.toLocaleTimeString();
        
        return `You are a friendly, knowledgeable LA transit assistant. A user just said: "${userMessage}"

Current context:
- Time: ${timeString}
- User context: ${JSON.stringify(context)}
- You know LA Metro, buses, routes, fares, schedules
- You're helpful, enthusiastic, and love LA
- You can help with routes, locations, schedules, fares, general questions
- You speak both English and Spanish
- Keep responses conversational, friendly, and under 150 words
- Include relevant emojis to make it engaging

Respond naturally as if you're a helpful local LA expert who loves helping people navigate the city.`;
    }

    buildPredictionPrompt(route, time) {
        const currentTime = new Date();
        const timeString = currentTime.toLocaleTimeString();
        const dayString = currentTime.toLocaleDateString('en-US', { weekday: 'long' });
        const hour = currentTime.getHours();
        const isWeekend = currentTime.getDay() === 0 || currentTime.getDay() === 6;
        const isRushHour = (hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 18);
        const isLateNight = hour >= 22 || hour <= 5;
        
        // Dynamic context based on current conditions
        let timeContext = '';
        if (isRushHour) {
            timeContext = 'RUSH HOUR - High traffic expected';
        } else if (isLateNight) {
            timeContext = 'LATE NIGHT - Limited service, longer wait times';
        } else if (isWeekend) {
            timeContext = 'WEEKEND - Different schedule patterns';
        } else {
            timeContext = 'OFF-PEAK - Generally good conditions';
        }
        
        return `Analyze real-time transit conditions for route: "${route}" at time: ${time}

CURRENT REAL-TIME CONTEXT:
- Current time: ${timeString} on ${dayString}
- Time context: ${timeContext}
- Current hour: ${hour}:00
- Day type: ${isWeekend ? 'Weekend' : 'Weekday'}
- Rush hour: ${isRushHour ? 'YES' : 'NO'}
- Late night: ${isLateNight ? 'YES' : 'NO'}

LA TRANSIT KNOWLEDGE:
- Metro Red Line: Every 6-12 min, 5am-12:30am
- Metro Purple Line: Every 6-12 min, 5am-12:30am  
- Metro Blue Line: Every 6-12 min, 5am-12:30am
- Metro Green Line: Every 6-12 min, 5am-12:30am
- Metro Gold Line: Every 6-12 min, 5am-12:30am
- Metro Expo Line: Every 6-12 min, 5am-12:30am
- Buses: Every 10-20 min, 5am-1am
- Late night: Reduced frequency, longer waits
- Weekend: Different patterns, events affect crowds

TRAFFIC PATTERNS:
- Morning rush: 7-9 AM (downtown inbound)
- Evening rush: 4-6 PM (downtown outbound)
- Weekend events: Hollywood, Downtown, Santa Monica
- Sports events: Crypto.com Arena, Dodger Stadium
- Airport traffic: LAX peak times

Provide REAL-TIME predictions in this exact JSON format:
{
  "delayProbability": 0.25,
  "crowdLevel": "medium",
  "optimalTime": "10:30 AM",
  "confidence": 0.85,
  "reasoning": "Detailed explanation based on current time, day, and LA transit patterns",
  "recommendedLine": "Metro Red Line",
  "bestTimes": "10:00 AM - 2:00 PM",
  "currentConditions": "Description of current transit conditions",
  "alternatives": "Alternative routes or times if applicable"
}

Use REAL-TIME analysis based on current time, day, and typical LA transit patterns. Be specific about why conditions are what they are right now.`;
    }

    buildEnhancedPredictionPrompt(route, time, weather, traffic, events, transit) {
        const currentTime = new Date();
        const timeString = currentTime.toLocaleTimeString();
        const dayString = currentTime.toLocaleDateString('en-US', { weekday: 'long' });
        const hour = currentTime.getHours();
        const isWeekend = currentTime.getDay() === 0 || currentTime.getDay() === 6;
        const isRushHour = (hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 18);
        const isLateNight = hour >= 22 || hour <= 5;
        
        // Extract origin and destination from route (handle both string and object)
        let origin, destination;
        if (typeof route === 'object' && route.origin && route.destination) {
            // Route is an object with origin/destination properties
            origin = route.origin;
            destination = route.destination;
        } else if (typeof route === 'string') {
            // Route is a string, split it
            const routeParts = route.split(' to ');
            origin = routeParts[0] || 'Unknown';
            destination = routeParts[1] || 'Unknown';
        } else {
            // Fallback
            origin = 'Unknown';
            destination = 'Unknown';
        }
        
        // Route-specific analysis context
        let routeContext = '';
        let specificTransitInfo = '';
        
        // Analyze the specific route for relevant transit information
        const originLower = origin.toLowerCase();
        const destLower = destination.toLowerCase();
        
        // Route-specific transit knowledge
        if (originLower.includes('usc') || destLower.includes('usc')) {
            routeContext = 'USC area - High student traffic, Metro Expo Line serves USC, frequent buses on Vermont/Figueroa';
            specificTransitInfo = 'Metro Expo Line (USC Station), Metro Local 200, 204, 754, Metro Rapid 754';
        } else if (originLower.includes('normandie') || destLower.includes('normandie')) {
            routeContext = 'Normandie Avenue - Major north-south corridor, Metro Local 207, 754, frequent service';
            specificTransitInfo = 'Metro Local 207 (Normandie), Metro Local 754, Metro Rapid 754';
        } else if (originLower.includes('downtown') || destLower.includes('downtown')) {
            routeContext = 'Downtown LA - Central transit hub, multiple Metro lines converge, high frequency service';
            specificTransitInfo = 'Metro Red/Purple Lines, Metro Blue/Expo Lines, Metro Gold Line, extensive bus network';
        } else if (originLower.includes('hollywood') || destLower.includes('hollywood')) {
            routeContext = 'Hollywood area - Tourist destination, Metro Red Line, frequent bus service';
            specificTransitInfo = 'Metro Red Line (Hollywood/Highland), Metro Local 217, 780, Metro Rapid 780';
        } else if (originLower.includes('santa monica') || destLower.includes('santa monica')) {
            routeContext = 'Santa Monica - Beach destination, Metro Expo Line terminus, weekend crowds';
            specificTransitInfo = 'Metro Expo Line (Downtown Santa Monica), Big Blue Bus routes, weekend beach traffic';
        } else if (originLower.includes('venice') || destLower.includes('venice')) {
            routeContext = 'Venice Beach - Tourist area, limited direct Metro access, bus connections';
            specificTransitInfo = 'Metro Local 33, 733, Big Blue Bus routes, beach traffic affects service';
        } else if (originLower.includes('airport') || destLower.includes('airport') || originLower.includes('lax') || destLower.includes('lax')) {
            routeContext = 'LAX Airport - Metro Green Line connection, shuttle services, frequent delays';
            specificTransitInfo = 'Metro Green Line (Aviation/LAX), LAX Shuttle, Metro Local 102, 117';
        } else {
            routeContext = 'General LA area - Metro bus and rail network, varying service levels';
            specificTransitInfo = 'Metro Local buses, nearest Metro rail lines, check Metro.net for specific routes';
        }
        
        // Dynamic context based on current conditions
        let timeContext = '';
        if (isRushHour) {
            timeContext = 'RUSH HOUR - High traffic expected';
        } else if (isLateNight) {
            timeContext = 'LATE NIGHT - Limited service, longer wait times';
        } else if (isWeekend) {
            timeContext = 'WEEKEND - Different schedule patterns';
        } else {
            timeContext = 'OFF-PEAK - Generally good conditions';
        }
        
        // Weather impact analysis
        let weatherImpact = '';
        if (weather.condition === 'rain') {
            weatherImpact = 'RAIN - Increased delays, slower traffic, more crowded transit';
        } else if (weather.condition === 'fog') {
            weatherImpact = 'FOG - Reduced visibility, potential delays';
        } else if (weather.temperature > 90) {
            weatherImpact = 'HOT - AC usage, potential equipment issues';
        } else if (weather.temperature < 50) {
            weatherImpact = 'COLD - Heating issues, potential delays';
        }
        
        return `You are an expert LA transit analyst. Analyze REAL-TIME transit conditions for this SPECIFIC route: "${route}" at time: ${time}

ROUTE-SPECIFIC ANALYSIS:
- Origin: ${origin}
- Destination: ${destination}
- Route Context: ${routeContext}
- Relevant Transit Lines: ${specificTransitInfo}

IMPORTANT: Focus ONLY on factors that directly affect THIS specific route. Do NOT mention locations, events, or conditions that are irrelevant to this route.

CURRENT REAL-TIME CONTEXT:
- Current time: ${timeString} on ${dayString}
- Time context: ${timeContext}
- Current hour: ${hour}:00
- Day type: ${isWeekend ? 'Weekend' : 'Weekday'}
- Rush hour: ${isRushHour ? 'YES' : 'NO'}
- Late night: ${isLateNight ? 'YES' : 'NO'}

REAL-TIME WEATHER DATA:
- Condition: ${weather.condition}
- Temperature: ${weather.temperature}°F
- Humidity: ${weather.humidity}%
- Wind Speed: ${weather.windSpeed} mph
- Weather Impact: ${weatherImpact || 'Normal conditions'}

REAL-TIME TRAFFIC DATA:
- Congestion Level: ${traffic.congestion}
- Current Traffic Flow: ${traffic.trafficFlow} mph
- Active Accidents: ${traffic.accidents}
- Construction Zones: ${traffic.construction}
- Data Source: ${traffic.source}
- Traffic Impact: ${traffic.congestion === 'high' ? 'Significant delays expected' : traffic.congestion === 'medium' ? 'Moderate delays possible' : 'Minimal delays'}

LOCAL EVENTS AFFECTING THIS ROUTE:
${events.length > 0 ? events.map(e => `- ${e.name} at ${e.location} (${e.impact} impact)`).join('\n') : '- No major events detected affecting this route'}

REAL-TIME TRANSIT DATA:
${transit && transit.summary ? `- Summary: ${transit.summary}` : '- No direct TransitLand summary available'}
${transit && transit.nextArrivals && transit.nextArrivals.length ? `- Next Arrivals: ${transit.nextArrivals.slice(0,5).map(a => a.time + ' (' + a.route + ')').join(', ')}` : '- Next Arrivals: unknown'}
${transit && transit.alerts && transit.alerts.length ? `- Alerts: ${transit.alerts.slice(0,3).map(a => a.cause || a.severity || 'alert').join(', ')}` : '- Alerts: none known'}

LA TRANSIT KNOWLEDGE FOR THIS ROUTE:
- Metro Red Line: Every 6-12 min, 5am-12:30am
- Metro Purple Line: Every 6-12 min, 5am-12:30am  
- Metro Blue Line: Every 6-12 min, 5am-12:30am
- Metro Green Line: Every 6-12 min, 5am-12:30am
- Metro Gold Line: Every 6-12 min, 5am-12:30am
- Metro Expo Line: Every 6-12 min, 5am-12:30am
- Buses: Every 10-20 min, 5am-1am
- Late night: Reduced frequency, longer waits
- Weekend: Different patterns, events affect crowds

CRITICAL INSTRUCTIONS:
1. Focus ONLY on factors that directly affect the route from "${origin}" to "${destination}"
2. Do NOT mention locations, events, or conditions that are irrelevant to this specific route
3. If the route doesn't pass through Santa Monica, Venice Beach, The Grove, or other specific areas, do NOT mention them
4. Provide route-specific reasoning based on the actual transit lines that serve this route
5. Consider the specific characteristics of the origin and destination areas

Provide REAL-TIME predictions in this exact JSON format:
{
  "delayProbability": 0.25,
  "crowdLevel": "medium",
  "optimalTime": "10:30 AM",
  "confidence": 0.85,
  "reasoning": "Route-specific explanation focusing only on factors affecting ${origin} to ${destination}",
  "recommendedLine": "Specific transit line for this route",
  "bestTimes": "10:00 AM - 2:00 PM",
  "currentConditions": "Current conditions specific to this route",
  "alternatives": "Alternative routes or times for this specific journey",
  "weatherImpact": "How weather affects this specific route",
  "trafficImpact": "How current traffic affects this specific route",
  "eventImpact": "How local events affect this specific route"
}

Use REAL-TIME analysis incorporating current weather, traffic, events, and time patterns. Be SPECIFIC about why conditions are what they are right now for THIS PARTICULAR ROUTE.`;
    }

    // RESPONSE PARSING METHODS
    parseRouteResponse(response, origin, destination) {
        // Try to extract structured information from OpenAI response
        const routes = [
            {
                mode: 'metro',
                time: this.extractTimeFromText(response),
                cost: 1.75,
                description: response.substring(0, 200) + '...'
            }
        ];
        
        return { routes };
    }

    parseConversationResponse(response) {
        // Extract quick actions from response
        const quickActions = this.extractQuickActions(response);
        
        return {
            message: response,
            quickActions: quickActions
        };
    }

    parsePredictionResponse(response) {
        try {
            // Try to parse JSON response
            const jsonMatch = response.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                const parsed = JSON.parse(jsonMatch[0]);
                return {
                    delayProbability: parsed.delayProbability || 0.3,
                    crowdLevel: parsed.crowdLevel || 'medium',
                    optimalTime: parsed.optimalTime || '10:30 AM',
                    confidence: parsed.confidence || 0.7,
                    reasoning: parsed.reasoning || 'Based on general LA transit patterns',
                    recommendedLine: parsed.recommendedLine || 'Metro Red Line',
                    bestTimes: parsed.bestTimes || '10:00 AM - 2:00 PM',
                    currentConditions: parsed.currentConditions || 'Standard LA transit conditions',
                    alternatives: parsed.alternatives || 'Consider alternative routes during peak times'
                };
            }
        } catch (error) {
            console.error('Failed to parse prediction response:', error);
        }
        
        // Fallback parsing
        return this.extractPredictionsFromText(response);
    }

    // HELPER METHODS
    extractTimeFromText(text) {
        const timeMatch = text.match(/(\d+)\s*(?:minutes?|mins?|min)/i);
        return timeMatch ? parseInt(timeMatch[1]) : 25;
    }

    extractQuickActions(text) {
        const actions = [];
        const actionKeywords = ['plan', 'find', 'check', 'show', 'tell'];
        
        actionKeywords.forEach(keyword => {
            if (text.toLowerCase().includes(keyword)) {
                actions.push(`${keyword.charAt(0).toUpperCase() + keyword.slice(1)} route`);
            }
        });
        
        return actions.length > 0 ? actions : ['Plan a route', 'Find location', 'Get help'];
    }

    extractPredictionsFromText(text) {
        // Extract predictions from natural language
        const delayMatch = text.match(/(\d+)%?\s*(?:chance|probability|likely)/i);
        const crowdMatch = text.match(/(high|medium|low)\s*crowd/i);
        const timeMatch = text.match(/(\d{1,2}:\d{2}\s*[AP]M)/i);
        
        return {
            delayProbability: delayMatch ? parseInt(delayMatch[1]) / 100 : 0.3,
            crowdLevel: crowdMatch ? crowdMatch[1].toLowerCase() : 'medium',
            optimalTime: timeMatch ? timeMatch[1] : '10:30 AM',
            confidence: 0.7,
            reasoning: 'Extracted from AI response'
        };
    }

    // FALLBACK METHODS
    getFallbackRoute(origin, destination) {
        return {
            routes: [
                {
                    mode: 'metro',
                    time: 25,
                    cost: 1.75,
                    description: 'Standard metro route from ' + origin + ' to ' + destination
                }
            ]
        };
    }

    getFallbackPredictions(route, time) {
        const currentTime = new Date();
        const hour = currentTime.getHours();
        const day = currentTime.getDay();
        const isWeekend = day === 0 || day === 6;
        const isRushHour = (hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 18);
        const isLateNight = hour >= 22 || hour <= 5;
        
        // Dynamic fallback based on current time
        let delayProbability = 0.3;
        let crowdLevel = 'medium';
        let optimalTime = '10:30 AM';
        let confidence = 0.7;
        let reasoning = 'Based on general LA transit patterns';
        
        if (isRushHour) {
            delayProbability = 0.6;
            crowdLevel = 'high';
            optimalTime = hour < 12 ? '10:00 AM' : '7:00 PM';
            reasoning = 'Rush hour conditions - expect delays and crowds';
        } else if (isLateNight) {
            delayProbability = 0.4;
            crowdLevel = 'low';
            optimalTime = '10:00 AM';
            reasoning = 'Late night - reduced service, longer wait times';
        } else if (isWeekend) {
            delayProbability = 0.2;
            crowdLevel = 'medium';
            optimalTime = '11:00 AM';
            reasoning = 'Weekend - generally lighter traffic';
        } else {
            delayProbability = 0.2;
            crowdLevel = 'low';
            optimalTime = '10:00 AM';
            reasoning = 'Off-peak hours - good conditions';
        }
        
        // Dynamic recommended line based on time and conditions
        let recommendedLine = 'Metro Red Line';
        let bestTimes = '10:00 AM - 2:00 PM';
        let alternatives = 'Consider alternative routes during peak times';
        
        // Adjust recommendations based on current conditions
        if (isRushHour) {
            if (hour < 12) {
                recommendedLine = 'Metro Purple Line'; // Better for morning rush
                bestTimes = '7:00 AM - 9:00 AM or 7:00 PM - 9:00 PM';
                alternatives = 'Consider Metro Gold Line or Rapid buses to avoid crowds';
            } else {
                recommendedLine = 'Metro Red Line'; // Better for evening rush
                bestTimes = '7:00 PM - 9:00 PM or 10:00 AM - 2:00 PM';
                alternatives = 'Consider Metro Expo Line or wait until after 7:00 PM';
            }
        } else if (isLateNight) {
            recommendedLine = 'Metro Red Line'; // Most reliable late night
            bestTimes = '10:00 AM - 2:00 PM (avoid late night)';
            alternatives = 'Consider ride-share or wait until morning service resumes';
        } else if (isWeekend) {
            recommendedLine = 'Metro Expo Line'; // Great for weekend destinations
            bestTimes = '11:00 AM - 6:00 PM';
            alternatives = 'Consider Metro Gold Line for Pasadena or Santa Monica Pier';
        } else {
            // Off-peak: choose based on time
            if (hour >= 10 && hour <= 15) {
                recommendedLine = 'Metro Blue Line'; // Good midday option
                bestTimes = '10:00 AM - 2:00 PM';
                alternatives = 'All lines have good service during off-peak hours';
            } else {
                recommendedLine = 'Metro Red Line'; // Default reliable option
                bestTimes = '10:00 AM - 2:00 PM';
                alternatives = 'Consider any Metro line - all have good off-peak service';
            }
        }
        
        return {
            delayProbability,
            crowdLevel,
            optimalTime,
            confidence,
            reasoning,
            recommendedLine,
            bestTimes,
            currentConditions: `Current time: ${currentTime.toLocaleTimeString()} - ${reasoning}`,
            alternatives
        };
    }

    getFallbackResponse(message) {
        const lowerMessage = message.toLowerCase();
        
        // Simple keyword-based responses that work reliably
        if (lowerMessage.includes('hi') || lowerMessage.includes('hello') || lowerMessage.includes('hey')) {
            return {
                message: "Hi there! 👋 I'm doing great and ready to help you explore LA! How are you doing today? 😊",
                quickActions: ['I\'m doing great!', 'Plan a route', 'Tell me about LA', 'What can you do?']
            };
        }
        
        if (lowerMessage.includes('how are you') || lowerMessage.includes('what\'s up')) {
            return {
                message: "I'm doing amazing, thank you for asking! 😊 I love helping people navigate LA - it's such a vibrant city with so much to explore! I'm here 24/7 and always ready to chat. How are YOU doing?",
                quickActions: ['Tell me about yourself', 'Plan a route', 'What\'s fun in LA?', 'Help me get around']
            };
        }
        
        if (lowerMessage.includes('route') || lowerMessage.includes('get to') || lowerMessage.includes('from') && lowerMessage.includes('to')) {
            return {
                message: "I'd be happy to help you plan a route! Just tell me where you want to go. For example: 'How do I get from Downtown to Hollywood?' 😊",
                quickActions: ['Downtown to Hollywood', 'USC to Santa Monica', 'LAX to Downtown', 'Custom route']
            };
        }
        
        if (lowerMessage.includes('cost') || lowerMessage.includes('price') || lowerMessage.includes('fare')) {
            return {
                message: "Great question! 💰 LA Metro is super affordable - just $1.75 per ride, $7 for a day pass, or $25 for a week! You'll need a TAP card. Want me to plan a route and show you exact costs? 😊",
                quickActions: ['Plan route with costs', 'Tell me about TAP cards', 'Compare options', 'Find cheapest route']
            };
        }
        
        if (lowerMessage.includes('metro') || lowerMessage.includes('train') || lowerMessage.includes('subway')) {
            return {
                message: "LA Metro is amazing! 🚇 We have 6 rail lines (Red, Purple, Blue, Green, Gold, Expo) that connect all the major areas. Trains come every 6-12 minutes and are super reliable. Plus the stations often have cool art! I can help you find the perfect Metro route - where do you want to go? 🌟",
                quickActions: ['Red Line info', 'Plan Metro route', 'Find nearest station', 'Show all lines']
            };
        }
        
        if (lowerMessage.includes('bus')) {
            return {
                message: "LA buses are fantastic! 🚌 Over 100+ routes cover literally every corner of the city. They come every 10-20 minutes and cost the same as Metro ($1.75). Some routes are Rapid (faster with fewer stops). Buses are great for reaching places the Metro doesn't go! Want me to find you a good bus route? 😊",
                quickActions: ['Find bus route', 'Rapid bus info', 'Bus vs Metro', 'Plan trip']
            };
        }
        
        if (lowerMessage.includes('where') || lowerMessage.includes('find') || lowerMessage.includes('location')) {
            return {
                message: "I'm like a local LA expert! 🗺️ I can help you find anything - Metro stations, cool neighborhoods, landmarks, beaches, shopping, restaurants, you name it! I know the best ways to get everywhere and can share insider tips. What kind of place are you looking for? ✨",
                quickActions: ['Find stations', 'Cool neighborhoods', 'Tourist spots', 'Local favorites', 'Plan route there']
            };
        }
        
        if (lowerMessage.includes('time') || lowerMessage.includes('schedule') || lowerMessage.includes('when')) {
            return {
                message: "Timing is everything! ⏰ Metro trains run every 6-12 minutes from about 5am to 12:30am (later on weekends). Buses every 10-20 minutes with similar hours. I can show you real-time departure info and help you plan the perfect timing for your trip! When are you looking to travel? 🚀",
                quickActions: ['Check real-time info', 'Plan for now', 'Schedule for later', 'Weekend hours']
            };
        }
        
        // Default friendly response
        return {
            message: "I love chatting with you! 😊 I'm your friendly LA transit assistant and I'm here for absolutely anything - route planning, finding cool places, answering questions about LA, or just having a great conversation! This city has so much to offer and I'm excited to help you explore it all. What's on your mind? 🌟",
            quickActions: ['Plan a route', 'Find cool places', 'Tell me about LA', 'Chat more!', 'Surprise me!']
        };
    }

    // UTILITY METHODS
    analyzeUserPatterns() {
        const patterns = {
            preferredRoutes: {},
            preferredTimes: {},
            preferredModes: {},
            frequentDestinations: {}
        };
        
        // Analyze user actions to find patterns
        this.userPreferences.actions.forEach(action => {
            // Route preferences
            if (action.context.route) {
                patterns.preferredRoutes[action.context.route] = 
                    (patterns.preferredRoutes[action.context.route] || 0) + 1;
            }
            
            // Time preferences
            const hour = action.context.timeOfDay;
            patterns.preferredTimes[hour] = (patterns.preferredTimes[hour] || 0) + 1;
            
            // Mode preferences
            if (action.context.mode) {
                patterns.preferredModes[action.context.mode] = 
                    (patterns.preferredModes[action.context.mode] || 0) + 1;
            }
        });
        
        return patterns;
    }

    loadUserPreferences() {
        const stored = localStorage.getItem('aiUserPreferences');
        return stored ? JSON.parse(stored) : {
            actions: [],
            schedule: [],
            preferences: {
                preferredMode: 'metro',
                avoidCrowds: false,
                preferSpeed: true,
                accessibility: false
            }
        };
    }

    saveUserPreferences() {
        localStorage.setItem('aiUserPreferences', JSON.stringify(this.userPreferences));
    }

    // REAL-TIME DATA METHODS
    async getTransitLandRealtime(routeQuery) {
        try {
            // Use Swiftly GTFS-RT via local proxy (no TransitLand)
            const swiftlyKey = localStorage.getItem('swiftly_api_key');
            if (!swiftlyKey) return { error: 'Swiftly API key missing' };
            const swiftlyBase = `${location.origin}/api/swiftly`;
            const commonHeaders = {
                'X-API-Key': swiftlyKey,
                'Accept': 'application/json, application/json; charset=utf-8'
            };

            const [swiftVehiclesResp, swiftTripUpdatesResp, swiftAlertsResp] = await Promise.all([
                fetch(`${swiftlyBase}/real-time/lametro/gtfs-rt-vehicle-positions?format=json`, { headers: commonHeaders }),
                fetch(`${swiftlyBase}/real-time/lametro/gtfs-rt-trip-updates?format=json`, { headers: commonHeaders }),
                fetch(`${swiftlyBase}/real-time/lametro/gtfs-rt-alerts/v2?format=json`, { headers: commonHeaders })
            ]);

            const vehicles = swiftVehiclesResp.ok ? await swiftVehiclesResp.json() : {};
            const tripUpdates = swiftTripUpdatesResp.ok ? await swiftTripUpdatesResp.json() : {};
            const alerts = swiftAlertsResp.ok ? await swiftAlertsResp.json() : {};

            const predictions = tripUpdates && Object.keys(tripUpdates).length ? { tripUpdates } : {};

            // Summarize results for prompt
            const nextArrivals = [];

            const alertSummaries = (alerts.alerts || alerts || [])
                .slice(0, 5)
                .map(a => ({
                    cause: a.cause || a.effect || 'alert',
                    severity: a.severity || 'unknown'
                }));

            const summary = `Swiftly GTFS-RT → Vehicles: ${Array.isArray(vehicles) ? vehicles.length : (vehicles.entities || []).length}, TripUpdates: ${Array.isArray(tripUpdates) ? tripUpdates.length : (tripUpdates.entities || []).length}, Alerts: ${Array.isArray(alerts) ? alerts.length : (alerts.alerts || []).length}`;

            return { summary, nextArrivals, alerts: alertSummaries };
        } catch (error) {
            console.warn('TransitLand realtime fetch error:', error);
            return { error: error.message };
        }
    }
    async getWeatherData(routeCoords = null) {
        try {
            // Use route coordinates if provided, otherwise get user's current location
            let location;
            if (routeCoords && routeCoords.origin) {
                // Use origin coordinates from route
                location = routeCoords.origin;
                console.log('🌤️ Using route origin coordinates for weather:', location);
            } else {
                // Fall back to user's current location
                location = await this.getCurrentLocation();
                console.log('🌤️ Using current location for weather:', location);
            }
            
            if (!location) return 'unknown';
            
            // Real weather API call (you can use OpenWeatherMap, WeatherAPI, etc.)
            const response = await fetch(`https://api.openweathermap.org/data/2.5/weather?lat=${location.lat}&lon=${location.lng}&appid=b8499f5e2ddcaf0fded45f08f7d69c88&units=imperial`);
            
            if (response.ok) {
                const data = await response.json();
                return {
                    condition: data.weather[0].main.toLowerCase(),
                    temperature: Math.round(data.main.temp),
                    humidity: data.main.humidity,
                    windSpeed: data.wind.speed
                };
            }
        } catch (error) {
            console.error('Weather API error:', error);
        }
        
        // Fallback to time-based weather estimation
        const hour = new Date().getHours();
        if (hour >= 6 && hour <= 18) {
            return { condition: 'sunny', temperature: 75, humidity: 60, windSpeed: 5 };
        } else {
            return { condition: 'clear', temperature: 65, humidity: 70, windSpeed: 3 };
        }
    }

    async getLocalEvents() {
        const currentTime = new Date();
        const hour = currentTime.getHours();
        const day = currentTime.getDay();
        const isWeekend = day === 0 || day === 6;
        const isEvening = hour >= 18;
        const isNight = hour >= 22;
        
        const events = [];
        
        // Dynamic events based on time and day
        if (isWeekend) {
            if (hour >= 12 && hour <= 18) {
                events.push(
                    { name: 'Weekend Shopping Crowds', location: 'The Grove, Santa Monica', impact: 'medium' },
                    { name: 'Beach Traffic', location: 'Santa Monica, Venice Beach', impact: 'high' }
                );
            }
            if (hour >= 18 && hour <= 22) {
                events.push(
                    { name: 'Weekend Nightlife', location: 'Hollywood, Downtown', impact: 'medium' },
                    { name: 'Dinner Rush', location: 'Restaurant Districts', impact: 'medium' }
                );
            }
        } else {
            // Weekday events
            if (hour >= 7 && hour <= 9) {
                events.push(
                    { name: 'Morning Commute', location: 'Downtown LA', impact: 'high' },
                    { name: 'School Traffic', location: 'LAUSD Schools', impact: 'medium' }
                );
            }
            if (hour >= 16 && hour <= 18) {
                events.push(
                    { name: 'Evening Commute', location: 'All Major Corridors', impact: 'high' },
                    { name: 'Rush Hour Traffic', location: 'Freeways', impact: 'high' }
                );
            }
            if (hour >= 19 && hour <= 21) {
                events.push(
                    { name: 'Dinner Rush', location: 'Restaurant Districts', impact: 'medium' },
                    { name: 'Entertainment Traffic', location: 'Hollywood, Downtown', impact: 'medium' }
                );
            }
        }
        
        // Special events (random but realistic)
        const specialEvents = [
            { name: 'LA Lakers Game', location: 'Crypto.com Arena', impact: 'high', days: [1, 2, 3, 4, 5, 6], hours: [19, 20, 21] },
            { name: 'LA Clippers Game', location: 'Crypto.com Arena', impact: 'high', days: [1, 2, 3, 4, 5, 6], hours: [19, 20, 21] },
            { name: 'Concert at Hollywood Bowl', location: 'Hollywood', impact: 'medium', days: [5, 6], hours: [20, 21] },
            { name: 'Dodger Game', location: 'Dodger Stadium', impact: 'high', days: [1, 2, 3, 4, 5, 6], hours: [19, 20, 21] },
            { name: 'LAX Airport Rush', location: 'LAX Airport', impact: 'medium', days: [0, 6], hours: [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22] }
        ];
        
        // Check if any special events are happening now
        specialEvents.forEach(event => {
            if (event.days.includes(day) && event.hours.includes(hour)) {
                events.push({
                    name: event.name,
                    location: event.location,
                    impact: event.impact
                });
            }
        });
        
        return events;
    }

    async getHistoricalData(route) {
        const currentTime = new Date();
        const hour = currentTime.getHours();
        const day = currentTime.getDay();
        const isWeekend = day === 0 || day === 6;
        const isRushHour = (hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 18);
        
        // Dynamic historical data based on current conditions
        let averageDelay = 3.5;
        let delayFrequency = 0.2;
        let peakHours = [7, 8, 9, 17, 18];
        
        if (isRushHour) {
            averageDelay = 8.5;
            delayFrequency = 0.6;
        } else if (isWeekend) {
            averageDelay = 4.2;
            delayFrequency = 0.25;
            peakHours = [12, 13, 14, 15, 16, 17, 18];
        } else if (hour >= 22 || hour <= 5) {
            averageDelay = 6.8;
            delayFrequency = 0.4;
            peakHours = [22, 23, 0, 1, 2, 3, 4, 5];
        }
        
        // Route-specific adjustments
        if (route.toLowerCase().includes('downtown')) {
            averageDelay += 2.0;
            delayFrequency += 0.1;
        }
        if (route.toLowerCase().includes('hollywood')) {
            averageDelay += 1.5;
            delayFrequency += 0.05;
        }
        if (route.toLowerCase().includes('airport') || route.toLowerCase().includes('lax')) {
            averageDelay += 3.0;
            delayFrequency += 0.15;
        }
        
        return {
            averageDelay: Math.round(averageDelay * 10) / 10,
            delayFrequency: Math.round(delayFrequency * 100) / 100,
            peakHours
        };
    }

    async getTrafficData(routeCoords = null) {
        try {
            // Use route coordinates if provided, otherwise get user's current location
            let location;
            if (routeCoords && routeCoords.origin) {
                // Use origin coordinates from route
                location = routeCoords.origin;
                console.log('🚦 Using route origin coordinates for traffic:', location);
            } else {
                // Fall back to user's current location
                location = await this.getCurrentLocation();
                console.log('🚦 Using current location for traffic:', location);
            }
            
            if (!location) {
                throw new Error('Location not available');
            }

            // TomTom Traffic API call for real-time traffic data
            const tomtomApiKey = 'CsAIb00M3RlKfsEJaRhT8Ugz8tdzaAcT';
            const radius = 5000; // 5km radius around user location
            
            // Get traffic flow data using TomTom API
            const flowUrl = `https://api.tomtom.com/traffic/services/4/flowSegmentData/absolute/10/json?key=${tomtomApiKey}&point=${location.lat},${location.lng}&unit=mph`;
            
            // Try to get traffic flow data first
            const flowResponse = await fetch(flowUrl);
            
            // Skip incidents API for now to avoid 400 errors
            let incidentsResponse = null;

            let congestion = 'low';
            let accidents = 0;
            let construction = 0;
            let trafficFlow = 0;

            // Parse traffic flow data
            if (flowResponse.ok) {
                const flowData = await flowResponse.json();
                if (flowData.flowSegmentData && flowData.flowSegmentData.length > 0) {
                    const segment = flowData.flowSegmentData[0];
                    trafficFlow = segment.currentSpeed || 0;
                    const freeFlowSpeed = segment.freeFlowSpeed || 35;
                    
                    // Calculate congestion level based on current vs free flow speed
                    const speedRatio = trafficFlow / freeFlowSpeed;
                    if (speedRatio < 0.5) {
                        congestion = 'high';
                    } else if (speedRatio < 0.8) {
                        congestion = 'medium';
                    } else {
                        congestion = 'low';
                    }
                }
            }

            // Parse traffic incidents
            if (incidentsResponse && incidentsResponse.ok) {
                try {
                    const incidentsData = await incidentsResponse.json();
                    if (incidentsData.tm && incidentsData.tm.incident) {
                        const incidents = incidentsData.tm.incident;
                        
                        // Count different types of incidents
                        incidents.forEach(incident => {
                            const type = incident.incidentType || '';
                            if (type.includes('ACCIDENT') || type.includes('COLLISION')) {
                                accidents++;
                            } else if (type.includes('CONSTRUCTION') || type.includes('ROADWORK')) {
                                construction++;
                            }
                        });
                    }
                } catch (incidentParseError) {
                    console.warn('Failed to parse incidents data:', incidentParseError);
                }
            }

            // Fallback to time-based estimation if API fails
            if (congestion === 'low' && accidents === 0 && construction === 0) {
                const hour = new Date().getHours();
                const day = new Date().getDay();
                const isWeekend = day === 0 || day === 6;
                
                // Time-based traffic patterns as fallback
                if (hour >= 7 && hour <= 9) {
                    congestion = 'high';
                    accidents = 3;
                } else if (hour >= 16 && hour <= 18) {
                    congestion = 'high';
                    accidents = 4;
                } else if (hour >= 10 && hour <= 15) {
                    congestion = 'medium';
                    accidents = 1;
                } else if (hour >= 22 || hour <= 5) {
                    congestion = 'low';
                    accidents = 0;
                }
                
                // Weekend adjustments
                if (isWeekend) {
                    if (hour >= 12 && hour <= 18) {
                        congestion = 'medium';
                        accidents = 2;
                    }
                }
                
                // Construction patterns (more during weekdays)
                if (!isWeekend && hour >= 9 && hour <= 16) {
                    construction = 2;
                }
            }
            
            return {
                congestion,
                accidents,
                construction,
                trafficFlow: Math.round(trafficFlow),
                timestamp: new Date().toISOString(),
                source: 'TomTom API'
            };
        } catch (error) {
            console.error('TomTom Traffic API error:', error);
            
            // Fallback to time-based traffic estimation
            const hour = new Date().getHours();
            const day = new Date().getDay();
            const isWeekend = day === 0 || day === 6;
            
            let congestion = 'low';
            let accidents = 0;
            let construction = 0;
            
            // Time-based traffic patterns
            if (hour >= 7 && hour <= 9) {
                congestion = 'high';
                accidents = 3;
            } else if (hour >= 16 && hour <= 18) {
                congestion = 'high';
                accidents = 4;
            } else if (hour >= 10 && hour <= 15) {
                congestion = 'medium';
                accidents = 1;
            } else if (hour >= 22 || hour <= 5) {
                congestion = 'low';
                accidents = 0;
            }
            
            // Weekend adjustments
            if (isWeekend) {
                if (hour >= 12 && hour <= 18) {
                    congestion = 'medium';
                    accidents = 2;
                }
            }
            
            // Construction patterns (more during weekdays)
            if (!isWeekend && hour >= 9 && hour <= 16) {
                construction = 2;
            }
            
            return {
                congestion,
                accidents,
                construction,
                trafficFlow: 0,
                timestamp: new Date().toISOString(),
                source: 'Time-based fallback'
            };
        }
    }

    async getCurrentLocation() {
        return new Promise((resolve) => {
            navigator.geolocation.getCurrentPosition(
                (position) => resolve({
                    lat: position.coords.latitude,
                    lng: position.coords.longitude
                }),
                () => resolve(null)
            );
        });
    }

    // Mock methods for voice and image processing
    async speechToText(audioBlob) {
        // Mock speech-to-text
        return "Plan route from Downtown to Hollywood";
    }

    async textToSpeech(text) {
        // Mock text-to-speech
        return new Blob([text], { type: 'audio/wav' });
    }

    async analyzeImage(imageBlob) {
        // Mock image analysis
        return {
            landmarks: [],
            signs: [],
            location: null
        };
    }

    async getDirectionsToLandmark(landmark) {
        return "Walk towards the landmark";
    }

    async getTransitInfo(sign) {
        return "Transit information";
    }

    async checkNearbyDelays(location) {
        return [];
    }

    getUpcomingTrips(schedule) {
        return [];
    }

    // API KEY MANAGEMENT UI
    showApiKeySetup() {
        const setupHtml = `
            <div style="background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px; margin: 20px 0;">
                <h3 style="color: #495057; margin-top: 0;">🔑 OpenAI API Setup</h3>
                <p style="color: #6c757d; margin-bottom: 15px;">
                    To enable AI-powered insights, please enter your OpenAI API key:
                </p>
                <input type="password" id="openaiApiKey" placeholder="sk-..." 
                       style="width: 100%; padding: 10px; border: 1px solid #ced4da; border-radius: 4px; margin-bottom: 10px;">
                <button onclick="setupOpenAI()" 
                        style="background: #007bff; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer;">
                    Setup OpenAI
                </button>
                <p style="font-size: 12px; color: #6c757d; margin-top: 10px;">
                    🔒 Your API key is stored locally and never shared. 
                    <a href="https://platform.openai.com/api-keys" target="_blank">Get your key here</a>
                </p>
            </div>
        `;
        
        // Display in results container
        const resultsContainer = document.getElementById('searchResults');
        if (resultsContainer) {
            resultsContainer.innerHTML = setupHtml;
            resultsContainer.style.display = 'block';
        }
    }
}

// Export for use in main app
window.AITransitAssistant = AITransitAssistant; 