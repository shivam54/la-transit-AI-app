// AI Features Module for LA Transit App
class AITransitAssistant {
    constructor() {
        this.huggingFaceToken = 'YOUR_HUGGING_FACE_TOKEN_HERE';
        this.userPreferences = this.loadUserPreferences();
        this.conversationHistory = [];
    }

    // 1. SMART ROUTE PLANNING AI
    async getIntelligentRoute(origin, destination, preferences = {}) {
        try {
            // Use Hugging Face for route analysis
            const routeAnalysis = await this.analyzeRouteWithAI(origin, destination, preferences);
            return this.parseRouteResponse(routeAnalysis);
        } catch (error) {
            console.error('AI Route Planning Error:', error);
            return this.getFallbackRoute(origin, destination);
        }
    }

    // 2. ADVANCED CONVERSATIONAL AI - FIXED to use Hugging Face
    async getIntelligentResponse(userMessage, context = {}) {
        try {
            // Use Hugging Face for intent classification
            const intent = await this.classifyIntent(userMessage);
            
            // Generate response based on intent
            const response = this.generateResponseFromIntent(intent, userMessage, context);
            
            // Store conversation history
            this.conversationHistory.push(
                { role: 'user', content: userMessage },
                { role: 'assistant', content: response.message }
            );

            return response;
        } catch (error) {
            console.error('AI Conversation Error:', error);
            return this.getFallbackResponse(userMessage);
        }
    }

    // 3. PREDICTIVE ANALYTICS
    async predictTransitConditions(route, time) {
        try {
            const features = {
                timeOfDay: time.getHours(),
                dayOfWeek: time.getDay(),
                weather: await this.getWeatherData(),
                events: await this.getLocalEvents(),
                historicalDelays: await this.getHistoricalData(route),
                currentTraffic: await this.getTrafficData()
            };

            // Simple ML prediction (in real app, use trained model)
            const delayProbability = this.calculateDelayProbability(features);
            const crowdLevel = this.predictCrowdLevel(features);
            const optimalTime = this.findOptimalTime(features);

            return {
                delayProbability: delayProbability,
                crowdLevel: crowdLevel,
                optimalTime: optimalTime,
                confidence: 0.85
            };
        } catch (error) {
            console.error('Prediction Error:', error);
            return { delayProbability: 0.3, crowdLevel: 'medium', optimalTime: time };
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

    // 5. SMART NOTIFICATIONS
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
            
            // Process the command
            const response = await this.getIntelligentResponse(text);
            
            // Convert response to speech
            const audioResponse = await this.textToSpeech(response);
            
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

    // HELPER METHODS - UPDATED to use Hugging Face
    async classifyIntent(message) {
        try {
            const response = await fetch('https://api-inference.huggingface.co/models/facebook/bart-large-mnli', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.huggingFaceToken}`
                },
                body: JSON.stringify({
                    inputs: message,
                    parameters: {
                        candidate_labels: [
                            "route planning",
                            "location search", 
                            "schedule inquiry",
                            "fare information",
                            "general question",
                            "navigation help",
                            "greeting",
                            "personal question"
                        ]
                    }
                })
            });

            if (response.ok) {
                const data = await response.json();
                return {
                    intent: data.labels[0],
                    confidence: data.scores[0]
                };
            } else {
                throw new Error('Hugging Face API failed');
            }
        } catch (error) {
            console.error('Intent classification error:', error);
            // Fallback to simple keyword matching
            return this.fallbackIntentClassification(message);
        }
    }

    fallbackIntentClassification(message) {
        const lowerMessage = message.toLowerCase();
        
        if (lowerMessage.includes('route') || lowerMessage.includes('get to') || lowerMessage.includes('from') && lowerMessage.includes('to')) {
            return { intent: 'route planning', confidence: 0.8 };
        }
        if (lowerMessage.includes('where') || lowerMessage.includes('find') || lowerMessage.includes('station')) {
            return { intent: 'location search', confidence: 0.7 };
        }
        if (lowerMessage.includes('schedule') || lowerMessage.includes('time') || lowerMessage.includes('when')) {
            return { intent: 'schedule inquiry', confidence: 0.8 };
        }
        if (lowerMessage.includes('cost') || lowerMessage.includes('price') || lowerMessage.includes('fare')) {
            return { intent: 'fare information', confidence: 0.9 };
        }
        if (lowerMessage.includes('hi') || lowerMessage.includes('hello') || lowerMessage.includes('hey')) {
            return { intent: 'greeting', confidence: 0.9 };
        }
        if (lowerMessage.includes('how are you') || lowerMessage.includes('what\'s up')) {
            return { intent: 'personal question', confidence: 0.8 };
        }
        
        return { intent: 'general question', confidence: 0.5 };
    }

    generateResponseFromIntent(intent, message, context) {
        const responses = {
            'route planning': {
                message: "I'd be happy to help you plan a route! Just tell me where you want to go. For example: 'How do I get from Downtown to Hollywood?' 😊",
                quickActions: ['Downtown to Hollywood', 'USC to Santa Monica', 'LAX to Downtown', 'Custom route']
            },
            'location search': {
                message: "I can help you find places! What are you looking for? I can help find Metro stations, landmarks, or any place in LA. 😊",
                quickActions: ['Nearest station', 'Popular destinations', 'LA landmarks', 'Custom search']
            },
            'schedule inquiry': {
                message: "I can help with schedules! Metro trains come every 6-12 minutes, and buses every 10-20 minutes. Want specific schedule info for a particular route?",
                quickActions: ['Red Line schedule', 'Bus schedules', 'Real-time updates', 'Service alerts']
            },
            'fare information': {
                message: "Great question! 💰 LA Metro is super affordable - just $1.75 per ride, $7 for a day pass, or $25 for a week! You'll need a TAP card. Want me to plan a route and show you exact costs? 😊",
                quickActions: ['Plan route with costs', 'Tell me about TAP cards', 'Compare options', 'Find cheapest route']
            },
            'greeting': {
                message: "Hi there! 👋 I'm doing great and ready to help you explore LA! How are you doing today? 😊",
                quickActions: ['I\'m doing great!', 'Plan a route', 'Tell me about LA', 'What can you do?']
            },
            'personal question': {
                message: "I'm doing amazing, thank you for asking! 😊 I love helping people navigate LA - it's such a vibrant city with so much to explore! I'm here 24/7 and always ready to chat. How are YOU doing?",
                quickActions: ['Tell me about yourself', 'Plan a route', 'What\'s fun in LA?', 'Help me get around']
            },
            'navigation help': {
                message: "I'm here to help you navigate! I can give you step-by-step directions, real-time updates, and help you find the best routes. What specific help do you need? 😊",
                quickActions: ['Step-by-step guide', 'Real-time navigation', 'Alternative routes', 'Emergency help']
            },
            'general question': {
                message: "I'm your friendly LA transit assistant! I can help you plan routes, find places, check schedules, and answer questions about getting around LA. What would you like to know? 😊",
                quickActions: ['Plan a route', 'Find location', 'Get help', 'Ask another question']
            }
        };

        return responses[intent.intent] || responses['general question'];
    }

    async analyzeRouteWithAI(origin, destination, preferences) {
        // Simulate AI route analysis
        const analysis = {
            route: `${origin} to ${destination}`,
            recommendations: [
                {
                    type: 'fastest',
                    description: 'Fastest route with minimal transfers',
                    confidence: 0.9
                },
                {
                    type: 'scenic',
                    description: 'Route with interesting landmarks',
                    confidence: 0.7
                },
                {
                    type: 'cost-effective',
                    description: 'Most affordable option',
                    confidence: 0.8
                }
            ],
            factors: {
                traffic: 'moderate',
                weather: 'clear',
                events: 'none',
                accessibility: preferences.accessibility || false
            }
        };
        
        return analysis;
    }

    parseRouteResponse(analysis) {
        return {
            routes: [
                {
                    mode: 'metro',
                    time: 25,
                    cost: 1.75,
                    description: analysis.recommendations[0].description
                }
            ]
        };
    }

    async callHuggingFace(model, inputs) {
        const response = await fetch(`https://api-inference.huggingface.co/models/${model}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.huggingFaceToken}`
            },
            body: JSON.stringify(inputs)
        });

        return await response.json();
    }

    calculateDelayProbability(features) {
        // Simple heuristic-based prediction
        let probability = 0.3; // Base probability
        
        // Time of day factors
        if (features.timeOfDay >= 7 && features.timeOfDay <= 9) probability += 0.2; // Rush hour
        if (features.timeOfDay >= 16 && features.timeOfDay <= 18) probability += 0.2; // Evening rush
        
        // Day of week factors
        if (features.dayOfWeek === 0 || features.dayOfWeek === 6) probability -= 0.1; // Weekend
        
        // Weather factors
        if (features.weather === 'rain') probability += 0.15;
        if (features.weather === 'sunny') probability -= 0.05;
        
        return Math.min(probability, 0.95); // Cap at 95%
    }

    predictCrowdLevel(features) {
        const crowdFactors = {
            timeOfDay: features.timeOfDay >= 7 && features.timeOfDay <= 9 ? 0.8 : 0.3,
            dayOfWeek: features.dayOfWeek >= 1 && features.dayOfWeek <= 5 ? 0.7 : 0.4,
            events: features.events.length > 0 ? 0.6 : 0.3
        };
        
        const averageCrowd = Object.values(crowdFactors).reduce((a, b) => a + b, 0) / Object.keys(crowdFactors).length;
        
        if (averageCrowd > 0.7) return 'high';
        if (averageCrowd > 0.4) return 'medium';
        return 'low';
    }

    findOptimalTime(features) {
        // Find the best time to travel based on historical data
        const optimalHours = [10, 11, 14, 15]; // Less crowded times
        const currentHour = features.timeOfDay;
        
        // Find the closest optimal hour
        let bestHour = optimalHours[0];
        let minDifference = Math.abs(currentHour - optimalHours[0]);
        
        for (const hour of optimalHours) {
            const difference = Math.abs(currentHour - hour);
            if (difference < minDifference) {
                minDifference = difference;
                bestHour = hour;
            }
        }
        
        return new Date().setHours(bestHour, 0, 0, 0);
    }

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

    // Mock data methods (replace with real API calls)
    async getWeatherData() {
        // Mock weather data
        const conditions = ['sunny', 'rain', 'cloudy', 'foggy'];
        return conditions[Math.floor(Math.random() * conditions.length)];
    }

    async getLocalEvents() {
        // Mock events data
        return [
            { name: 'LA Lakers Game', location: 'Crypto.com Arena', impact: 'high' },
            { name: 'Concert at Hollywood Bowl', location: 'Hollywood', impact: 'medium' }
        ];
    }

    async getHistoricalData(route) {
        // Mock historical delay data
        return {
            averageDelay: 5.2,
            delayFrequency: 0.3,
            peakHours: [7, 8, 9, 17, 18]
        };
    }

    async getTrafficData() {
        // Mock traffic data
        return {
            congestion: 'medium',
            accidents: 2,
            construction: 1
        };
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

    getFallbackRoute(origin, destination) {
        return {
            routes: [
                {
                    mode: 'metro',
                    time: 25,
                    cost: 1.75,
                    description: 'Standard metro route'
                }
            ]
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
}

// Export for use in main app
window.AITransitAssistant = AITransitAssistant; 