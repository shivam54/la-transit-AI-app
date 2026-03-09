class EnhancedTransitPlanner {
    constructor() {
        this.routingSystem = new EnhancedRoutingSystem();
        this.transitData = {
            metroLines: {
                'Red Line': {
                    stations: [
                        { name: 'Union Station', lat: 34.0560, lng: -118.2340, lines: ['Red', 'Purple', 'Gold'] },
                        { name: 'Civic Center', lat: 34.0550, lng: -118.2430, lines: ['Red', 'Purple'] },
                        { name: 'Pershing Square', lat: 34.0490, lng: -118.2500, lines: ['Red', 'Purple'] },
                        { name: '7th St/Metro Center', lat: 34.0480, lng: -118.2580, lines: ['Red', 'Purple', 'Blue', 'Expo'] },
                        { name: 'Westlake/MacArthur Park', lat: 34.0570, lng: -118.2750, lines: ['Red', 'Purple'] },
                        { name: 'Wilshire/Vermont', lat: 34.0620, lng: -118.2910, lines: ['Red', 'Purple'] },
                        { name: 'Vermont/Santa Monica', lat: 34.0920, lng: -118.2910, lines: ['Red'] },
                        { name: 'Vermont/Sunset', lat: 34.0980, lng: -118.2910, lines: ['Red'] },
                        { name: 'Hollywood/Western', lat: 34.1020, lng: -118.3070, lines: ['Red'] },
                        { name: 'Hollywood/Vine', lat: 34.1020, lng: -118.3250, lines: ['Red'] },
                        { name: 'Hollywood/Highland', lat: 34.1020, lng: -118.3390, lines: ['Red'] },
                        { name: 'Universal City', lat: 34.1380, lng: -118.3600, lines: ['Red'] },
                        { name: 'North Hollywood', lat: 34.1550, lng: -118.3760, lines: ['Red', 'Orange'] }
                    ],
                    frequency: 'Every 6-10 minutes',
                    operatingHours: '4:00 AM - 1:00 AM',
                    fare: 1.75
                },
                'Purple Line': {
                    stations: [
                        { name: 'Union Station', lat: 34.0560, lng: -118.2340, lines: ['Red', 'Purple', 'Gold'] },
                        { name: 'Civic Center', lat: 34.0550, lng: -118.2430, lines: ['Red', 'Purple'] },
                        { name: 'Pershing Square', lat: 34.0490, lng: -118.2500, lines: ['Red', 'Purple'] },
                        { name: '7th St/Metro Center', lat: 34.0480, lng: -118.2580, lines: ['Red', 'Purple', 'Blue', 'Expo'] },
                        { name: 'Westlake/MacArthur Park', lat: 34.0570, lng: -118.2750, lines: ['Red', 'Purple'] },
                        { name: 'Wilshire/Vermont', lat: 34.0620, lng: -118.2910, lines: ['Red', 'Purple'] },
                        { name: 'Wilshire/Normandie', lat: 34.0620, lng: -118.3050, lines: ['Purple'] },
                        { name: 'Wilshire/Western', lat: 34.0620, lng: -118.3090, lines: ['Purple'] }
                    ],
                    frequency: 'Every 6-10 minutes',
                    operatingHours: '4:00 AM - 1:00 AM',
                    fare: 1.75
                },
                'Blue Line': {
                    stations: [
                        { name: '7th St/Metro Center', lat: 34.0480, lng: -118.2580, lines: ['Red', 'Purple', 'Blue', 'Expo'] },
                        { name: 'Pico', lat: 34.0450, lng: -118.2580, lines: ['Blue'] },
                        { name: 'Grand/LATTC', lat: 34.0400, lng: -118.2580, lines: ['Blue'] },
                        { name: 'San Pedro', lat: 34.0350, lng: -118.2580, lines: ['Blue'] },
                        { name: 'Washington', lat: 34.0300, lng: -118.2580, lines: ['Blue'] },
                        { name: 'Vernon', lat: 34.0250, lng: -118.2580, lines: ['Blue'] },
                        { name: 'Slauson', lat: 34.0200, lng: -118.2580, lines: ['Blue'] },
                        { name: 'Florence', lat: 34.0150, lng: -118.2580, lines: ['Blue'] },
                        { name: 'Firestone', lat: 34.0100, lng: -118.2580, lines: ['Blue'] },
                        { name: '103rd St', lat: 34.0050, lng: -118.2580, lines: ['Blue'] },
                        { name: 'Willowbrook', lat: 34.0000, lng: -118.2580, lines: ['Blue'] },
                        { name: 'Compton', lat: 33.8950, lng: -118.2200, lines: ['Blue'] },
                        { name: 'Artesia', lat: 33.8900, lng: -118.2200, lines: ['Blue'] },
                        { name: 'Del Amo', lat: 33.8850, lng: -118.2200, lines: ['Blue'] },
                        { name: 'Wardlow', lat: 33.8800, lng: -118.2200, lines: ['Blue'] },
                        { name: 'Willow', lat: 33.8750, lng: -118.2200, lines: ['Blue'] },
                        { name: 'Pacific Coast Hwy', lat: 33.8700, lng: -118.2200, lines: ['Blue'] },
                        { name: 'Anaheim', lat: 33.8650, lng: -118.2200, lines: ['Blue'] },
                        { name: '5th St', lat: 33.8600, lng: -118.2200, lines: ['Blue'] },
                        { name: '1st St', lat: 33.8550, lng: -118.2200, lines: ['Blue'] },
                        { name: 'Downtown Long Beach', lat: 33.8500, lng: -118.2200, lines: ['Blue'] }
                    ],
                    frequency: 'Every 6-10 minutes',
                    operatingHours: '4:00 AM - 1:00 AM',
                    fare: 1.75
                },
                'Expo Line': {
                    stations: [
                        { name: '7th St/Metro Center', lat: 34.0480, lng: -118.2580, lines: ['Red', 'Purple', 'Blue', 'Expo'] },
                        { name: 'Pico', lat: 34.0450, lng: -118.2580, lines: ['Blue', 'Expo'] },
                        { name: 'LATTC/Ortho Institute', lat: 34.0400, lng: -118.2580, lines: ['Expo'] },
                        { name: 'Jefferson/USC', lat: 34.0350, lng: -118.2580, lines: ['Expo'] },
                        { name: 'Expo Park/USC', lat: 34.0300, lng: -118.2580, lines: ['Expo'] },
                        { name: 'Expo/Vermont', lat: 34.0250, lng: -118.2910, lines: ['Expo'] },
                        { name: 'Expo/Western', lat: 34.0200, lng: -118.3090, lines: ['Expo'] },
                        { name: 'Expo/Crenshaw', lat: 34.0150, lng: -118.3270, lines: ['Expo'] },
                        { name: 'Farmdale', lat: 34.0100, lng: -118.3450, lines: ['Expo'] },
                        { name: 'Expo/La Brea', lat: 34.0050, lng: -118.3630, lines: ['Expo'] },
                        { name: 'La Cienega/Jefferson', lat: 34.0000, lng: -118.3810, lines: ['Expo'] },
                        { name: 'Culver City', lat: 33.9950, lng: -118.3990, lines: ['Expo'] },
                        { name: 'Palms', lat: 33.9900, lng: -118.4170, lines: ['Expo'] },
                        { name: 'Westwood/Rancho Park', lat: 33.9850, lng: -118.4350, lines: ['Expo'] },
                        { name: 'Expo/Sepulveda', lat: 33.9800, lng: -118.4530, lines: ['Expo'] },
                        { name: 'Expo/Bundy', lat: 33.9750, lng: -118.4710, lines: ['Expo'] },
                        { name: '26th St/Bergamot', lat: 33.9700, lng: -118.4890, lines: ['Expo'] },
                        { name: '17th St/SMC', lat: 33.9650, lng: -118.5070, lines: ['Expo'] },
                        { name: 'Downtown Santa Monica', lat: 33.9600, lng: -118.5250, lines: ['Expo'] }
                    ],
                    frequency: 'Every 6-10 minutes',
                    operatingHours: '4:00 AM - 1:00 AM',
                    fare: 1.75
                },
                'Gold Line': {
                    stations: [
                        { name: 'Union Station', lat: 34.0560, lng: -118.2340, lines: ['Red', 'Purple', 'Gold'] },
                        { name: 'Chinatown', lat: 34.0620, lng: -118.2380, lines: ['Gold'] },
                        { name: 'Lincoln Heights/Cypress Park', lat: 34.0680, lng: -118.2420, lines: ['Gold'] },
                        { name: 'Heritage Square', lat: 34.0740, lng: -118.2460, lines: ['Gold'] },
                        { name: 'Southwest Museum', lat: 34.0800, lng: -118.2500, lines: ['Gold'] },
                        { name: 'Highland Park', lat: 34.0860, lng: -118.2540, lines: ['Gold'] },
                        { name: 'South Pasadena', lat: 34.0920, lng: -118.2580, lines: ['Gold'] },
                        { name: 'Fillmore', lat: 34.0980, lng: -118.2620, lines: ['Gold'] },
                        { name: 'Del Mar', lat: 34.1040, lng: -118.2660, lines: ['Gold'] },
                        { name: 'Memorial Park', lat: 34.1100, lng: -118.2700, lines: ['Gold'] },
                        { name: 'Lake', lat: 34.1160, lng: -118.2740, lines: ['Gold'] },
                        { name: 'Allen', lat: 34.1220, lng: -118.2780, lines: ['Gold'] },
                        { name: 'Sierra Madre Villa', lat: 34.1280, lng: -118.2820, lines: ['Gold'] },
                        { name: 'Arcadia', lat: 34.1340, lng: -118.2860, lines: ['Gold'] },
                        { name: 'Monrovia', lat: 34.1400, lng: -118.2900, lines: ['Gold'] },
                        { name: 'Duarte/City of Hope', lat: 34.1460, lng: -118.2940, lines: ['Gold'] },
                        { name: 'Irwindale', lat: 34.1520, lng: -118.2980, lines: ['Gold'] },
                        { name: 'Azusa Downtown', lat: 34.1580, lng: -118.3020, lines: ['Gold'] },
                        { name: 'APU/Citrus College', lat: 34.1640, lng: -118.3060, lines: ['Gold'] },
                        { name: 'Glendora', lat: 34.1700, lng: -118.3100, lines: ['Gold'] },
                        { name: 'San Dimas', lat: 34.1760, lng: -118.3140, lines: ['Gold'] },
                        { name: 'La Verne', lat: 34.1820, lng: -118.3180, lines: ['Gold'] },
                        { name: 'Pomona Downtown', lat: 34.1880, lng: -118.3220, lines: ['Gold'] },
                        { name: 'Claremont', lat: 34.1940, lng: -118.3260, lines: ['Gold'] },
                        { name: 'Montclair', lat: 34.2000, lng: -118.3300, lines: ['Gold'] }
                    ],
                    frequency: 'Every 6-10 minutes',
                    operatingHours: '4:00 AM - 1:00 AM',
                    fare: 1.75
                }
            },
            // Enhanced Metrolink Lines
            metrolinkLines: {
                'Antelope Valley Line': {
                    stations: [
                        { name: 'Lancaster', lat: 34.6868, lng: -118.1542, lines: ['Metrolink'] },
                        { name: 'Palmdale', lat: 34.5794, lng: -118.1165, lines: ['Metrolink'] },
                        { name: 'Santa Clarita', lat: 34.3917, lng: -118.5426, lines: ['Metrolink'] },
                        { name: 'Sylmar', lat: 34.3071, lng: -118.4481, lines: ['Metrolink'] },
                        { name: 'Sun Valley', lat: 34.2175, lng: -118.3704, lines: ['Metrolink'] },
                        { name: 'Burbank Airport', lat: 34.1808, lng: -118.3089, lines: ['Metrolink'] },
                        { name: 'Glendale', lat: 34.1425, lng: -118.2551, lines: ['Metrolink'] },
                        { name: 'Union Station', lat: 34.0560, lng: -118.2340, lines: ['Metrolink'] }
                    ],
                    frequency: 'Every 1-2 hours',
                    operatingHours: '4:00 AM - 11:00 PM',
                    fare: 8.50
                },
                'Ventura County Line': {
                    stations: [
                        { name: 'Ventura', lat: 34.2746, lng: -119.2290, lines: ['Metrolink'] },
                        { name: 'Oxnard', lat: 34.1975, lng: -119.1771, lines: ['Metrolink'] },
                        { name: 'Camarillo', lat: 34.2164, lng: -119.0376, lines: ['Metrolink'] },
                        { name: 'Moorpark', lat: 34.2856, lng: -118.8770, lines: ['Metrolink'] },
                        { name: 'Simi Valley', lat: 34.2694, lng: -118.7815, lines: ['Metrolink'] },
                        { name: 'Chatsworth', lat: 34.2572, lng: -118.6012, lines: ['Metrolink'] },
                        { name: 'Northridge', lat: 34.2283, lng: -118.5368, lines: ['Metrolink'] },
                        { name: 'Van Nuys', lat: 34.2000, lng: -118.4900, lines: ['Metrolink'] },
                        { name: 'Burbank Airport', lat: 34.1808, lng: -118.3089, lines: ['Metrolink'] },
                        { name: 'Glendale', lat: 34.1425, lng: -118.2551, lines: ['Metrolink'] },
                        { name: 'Union Station', lat: 34.0560, lng: -118.2340, lines: ['Metrolink'] }
                    ],
                    frequency: 'Every 1-2 hours',
                    operatingHours: '4:00 AM - 11:00 PM',
                    fare: 8.50
                }
            },
            // Amtrak Services
            amtrakLines: {
                'Pacific Surfliner': {
                    stations: [
                        { name: 'San Diego', lat: 32.7157, lng: -117.1611, lines: ['Amtrak'] },
                        { name: 'Oceanside', lat: 33.1959, lng: -117.3795, lines: ['Amtrak'] },
                        { name: 'San Juan Capistrano', lat: 33.5017, lng: -117.6625, lines: ['Amtrak'] },
                        { name: 'Irvine', lat: 33.6846, lng: -117.8265, lines: ['Amtrak'] },
                        { name: 'Santa Ana', lat: 33.7455, lng: -117.8677, lines: ['Amtrak'] },
                        { name: 'Anaheim', lat: 33.8038, lng: -117.8849, lines: ['Amtrak'] },
                        { name: 'Fullerton', lat: 33.8703, lng: -117.9244, lines: ['Amtrak'] },
                        { name: 'Union Station', lat: 34.0560, lng: -118.2340, lines: ['Amtrak'] },
                        { name: 'Burbank Airport', lat: 34.1808, lng: -118.3089, lines: ['Amtrak'] },
                        { name: 'Ventura', lat: 34.2746, lng: -119.2290, lines: ['Amtrak'] },
                        { name: 'Santa Barbara', lat: 34.4208, lng: -119.6982, lines: ['Amtrak'] },
                        { name: 'San Luis Obispo', lat: 35.2828, lng: -120.6596, lines: ['Amtrak'] }
                    ],
                    frequency: 'Every 2-4 hours',
                    operatingHours: '5:00 AM - 10:00 PM',
                    fare: 25.00
                }
            },
            busRoutes: {
                'Metro Local': {
                    frequency: 'Every 10-15 minutes',
                    operatingHours: '4:00 AM - 2:00 AM',
                    fare: 1.75
                },
                'Metro Rapid': {
                    frequency: 'Every 5-10 minutes',
                    operatingHours: '4:00 AM - 2:00 AM',
                    fare: 1.75
                },
                'Metro Express': {
                    frequency: 'Every 15-30 minutes',
                    operatingHours: '5:00 AM - 9:00 PM',
                    fare: 2.50
                }
            }
        };
    }

    // Calculate distance between two points
    calculateDistance(lat1, lng1, lat2, lng2) {
        const R = 6371; // Earth's radius in km
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLng = (lng2 - lng1) * Math.PI / 180;
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                  Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                  Math.sin(dLng/2) * Math.sin(dLng/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }

    // Find nearest stations to a location (enhanced to include all transit types)
    findNearestStations(lat, lng, radius = 2) { // 2km radius
        const stations = [];
        
        // Search Metro lines
        Object.keys(this.transitData.metroLines).forEach(lineName => {
            const line = this.transitData.metroLines[lineName];
            line.stations.forEach(station => {
                const distance = this.calculateDistance(lat, lng, station.lat, station.lng);
                if (distance <= radius) {
                    stations.push({
                        ...station,
                        line: lineName,
                        type: 'metro',
                        distance: distance,
                        walkingTime: Math.round(distance * 12), // 12 min/km walking
                        lineInfo: line
                    });
                }
            });
        });

        // Search Metrolink lines
        Object.keys(this.transitData.metrolinkLines).forEach(lineName => {
            const line = this.transitData.metrolinkLines[lineName];
            line.stations.forEach(station => {
                const distance = this.calculateDistance(lat, lng, station.lat, station.lng);
                if (distance <= radius) {
                    stations.push({
                        ...station,
                        line: lineName,
                        type: 'metrolink',
                        distance: distance,
                        walkingTime: Math.round(distance * 12),
                        lineInfo: line
                    });
                }
            });
        });

        // Search Amtrak lines
        Object.keys(this.transitData.amtrakLines).forEach(lineName => {
            const line = this.transitData.amtrakLines[lineName];
            line.stations.forEach(station => {
                const distance = this.calculateDistance(lat, lng, station.lat, station.lng);
                if (distance <= radius) {
                    stations.push({
                        ...station,
                        line: lineName,
                        type: 'amtrak',
                        distance: distance,
                        walkingTime: Math.round(distance * 12),
                        lineInfo: line
                    });
                }
            });
        });
        
        return stations.sort((a, b) => a.distance - b.distance);
    }

    // Generate departure times based on current time and transit type
    generateDepartureTimes(station, lineName, currentTime = new Date()) {
        let line;
        let departures = [];
        
        // Find the line data based on type
        if (this.transitData.metroLines[lineName]) {
            line = this.transitData.metroLines[lineName];
        } else if (this.transitData.metrolinkLines[lineName]) {
            line = this.transitData.metrolinkLines[lineName];
        } else if (this.transitData.amtrakLines[lineName]) {
            line = this.transitData.amtrakLines[lineName];
        } else {
            return [];
        }
        
        // Generate times based on transit type
        let interval, maxDepartures;
        if (lineName.includes('Metrolink')) {
            interval = 60; // 1 hour for Metrolink
            maxDepartures = 6;
        } else if (lineName.includes('Amtrak')) {
            interval = 120; // 2 hours for Amtrak
            maxDepartures = 4;
        } else {
            interval = 10; // 10 minutes for Metro
            maxDepartures = 6;
        }
        
        // Generate times for the next departures
        for (let i = 0; i < maxDepartures; i++) {
            const departureTime = new Date(currentTime);
            departureTime.setMinutes(departureTime.getMinutes() + (i * interval) + Math.floor(Math.random() * 10));
            
            if (departureTime.getHours() >= 4 && departureTime.getHours() < 25) { // Operating hours
                departures.push({
                    time: departureTime,
                    formatted: departureTime.toLocaleTimeString('en-US', { 
                        hour: 'numeric', 
                        minute: '2-digit',
                        hour12: true 
                    }),
                    minutesFromNow: Math.round((departureTime - currentTime) / (1000 * 60))
                });
            }
        }
        
        return departures;
    }

    // Plan comprehensive transit routes (enhanced for all transit types)
    async planTransitRoutes(origin, destination, currentTime = new Date()) {
        try {
            // Geocode addresses
            const [originCoords, destCoords] = await Promise.all([
                this.routingSystem.geocodeAddress(origin),
                this.routingSystem.geocodeAddress(destination)
            ]);

            // Find nearest stations (all types)
            const originStations = this.findNearestStations(originCoords.lat, originCoords.lng);
            const destStations = this.findNearestStations(destCoords.lat, destCoords.lng);

            const routes = [];

            // Generate different route options
            for (let i = 0; i < Math.min(3, originStations.length); i++) {
                for (let j = 0; j < Math.min(3, destStations.length); j++) {
                    const originStation = originStations[i];
                    const destStation = destStations[j];

                    // Calculate transit time between stations
                    const transitDistance = this.calculateDistance(
                        originStation.lat, originStation.lng,
                        destStation.lat, destStation.lng
                    );
                    
                    // Calculate transit time based on type
                    let transitTime;
                    if (originStation.type === 'metrolink') {
                        transitTime = Math.round(transitDistance * 2); // 2 min/km for Metrolink
                    } else if (originStation.type === 'amtrak') {
                        transitTime = Math.round(transitDistance * 1.5); // 1.5 min/km for Amtrak
                    } else {
                        transitTime = Math.round(transitDistance * 3); // 3 min/km for metro
                    }

                    // Generate departure times
                    const departures = this.generateDepartureTimes(originStation, originStation.line, currentTime);

                    // Calculate total journey time
                    const totalTime = originStation.walkingTime + transitTime + 
                                    this.calculateDistance(destStation.lat, destStation.lng, destCoords.lat, destCoords.lng) * 12;

                    // Calculate total cost
                    const totalCost = originStation.lineInfo.fare + 
                                    (originStation.line !== destStation.line ? 0.50 : 0); // Transfer fee

                    routes.push({
                        id: `route_${i}_${j}`,
                        origin: {
                            address: origin,
                            coordinates: originCoords,
                            station: originStation,
                            walkingDistance: Math.round(originStation.distance * 1000), // meters
                            walkingTime: originStation.walkingTime
                        },
                        destination: {
                            address: destination,
                            coordinates: destCoords,
                            station: destStation,
                            walkingDistance: Math.round(this.calculateDistance(destStation.lat, destStation.lng, destCoords.lat, destCoords.lng) * 1000),
                            walkingTime: Math.round(this.calculateDistance(destStation.lat, destStation.lng, destCoords.lat, destCoords.lng) * 12)
                        },
                        transit: {
                            line: originStation.line,
                            type: originStation.type,
                            originStation: originStation.name,
                            destStation: destStation.name,
                            distance: Math.round(transitDistance * 10) / 10,
                            time: transitTime,
                            departures: departures,
                            frequency: originStation.lineInfo.frequency,
                            operatingHours: originStation.lineInfo.operatingHours
                        },
                        summary: {
                            totalTime: totalTime,
                            totalCost: totalCost,
                            transfers: originStation.line !== destStation.line ? 1 : 0,
                            reliability: 'High'
                        }
                    });
                }
            }

            // Sort routes by total time
            routes.sort((a, b) => a.summary.totalTime - b.summary.totalTime);

            return {
                origin: originCoords,
                destination: destCoords,
                routes: routes.slice(0, 8), // Return top 8 routes
                generatedAt: currentTime
            };

        } catch (error) {
            console.error('Transit planning failed:', error);
            throw error;
        }
    }

    // Get real-time updates (simulated)
    getRealTimeUpdates(station, line) {
        const updates = {
            delays: Math.random() > 0.8 ? Math.floor(Math.random() * 10) + 1 : 0,
            crowding: Math.random() > 0.7 ? ['Low', 'Medium', 'High'][Math.floor(Math.random() * 3)] : 'Low',
            alerts: Math.random() > 0.9 ? ['Minor delays', 'Service change', 'Maintenance'][Math.floor(Math.random() * 3)] : null
        };
        return updates;
    }

    // Format route for display
    formatRouteForDisplay(route) {
        const nextDeparture = route.transit.departures[0];
        const realTimeUpdates = this.getRealTimeUpdates(route.origin.station, route.transit.line);
        
        return {
            ...route,
            display: {
                nextDeparture: nextDeparture.formatted,
                minutesUntilDeparture: nextDeparture.minutesFromNow,
                walkingToStation: `${route.origin.walkingDistance}m (${route.origin.walkingTime} min)`,
                transitJourney: `${route.transit.line} (${route.transit.type}): ${route.origin.station.name} → ${route.destination.station.name}`,
                walkingFromStation: `${route.destination.walkingDistance}m (${route.destination.walkingTime} min)`,
                totalJourney: `${route.summary.totalTime} min`,
                cost: `$${route.summary.totalCost.toFixed(2)}`,
                reliability: route.summary.reliability,
                realTimeUpdates: realTimeUpdates
            }
        };
    }
}
