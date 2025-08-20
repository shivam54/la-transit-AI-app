# LA Transit App API Documentation

## Overview

The LA Transit App includes multiple API service layers for fetching real-time transit data. The app is designed to work with both static data (fallback) and real APIs when available.

## API Files Structure

```
src/
├── services/
│   └── api.ts              # Main API service classes
├── hooks/
│   └── useTransitData.ts   # React hook for data management
└── data/
    └── metroRoutes.ts      # Static fallback data
```

## API Services

### 1. MetroApiService (Primary API)

**Location:** `src/services/api.ts`

**Base URL:** `https://api.metro.net` (configurable via `REACT_APP_API_BASE_URL`)

#### Available Endpoints:

```typescript
// Get all metro routes
GET /routes
Response: MetroRoute[]

// Get specific route
GET /routes/{routeId}
Response: MetroRoute

// Get all stations
GET /stations
Response: Station[]

// Get specific station
GET /stations/{stationId}
Response: Station

// Get real-time transit info
GET /transit-info?routeId={routeId}&stationId={stationId}
Response: TransitInfo[]

// Get route schedule
GET /routes/{routeId}/schedule?date={date}
Response: ScheduleData

// Search routes between stations
GET /routes/search?origin={origin}&destination={destination}&time={time}
Response: RouteSearchResult[]
```

#### Usage Example:
```typescript
import MetroApiService from '../services/api';

// Get all routes
const routes = await MetroApiService.getRoutes();

// Get specific route
const redLine = await MetroApiService.getRouteById('red-line');

// Get real-time info
const transitInfo = await MetroApiService.getTransitInfo('red-line', 'union-station');
```

### 2. GTFSApiService (GTFS Standard)

**Location:** `src/services/api.ts`

**Base URL:** `https://api.transit.land/v2`

#### Available Endpoints:

```typescript
// Get all transit agencies
GET /agencies
Response: Agency[]

// Get routes for an agency
GET /agencies/{agencyId}/routes
Response: Route[]

// Get stops for a route
GET /routes/{routeId}/stops
Response: Stop[]
```

#### Usage Example:
```typescript
import { GTFSApiService } from '../services/api';

// Get LA Metro agency data
const agencies = await GTFSApiService.getAgencies();
const lametroRoutes = await GTFSApiService.getAgencyRoutes('lametro');
```

### 3. LAMetroApiService (LA Metro Specific)

**Location:** `src/services/api.ts`

**Base URL:** `https://api.metro.net/agencies/lametro`

#### Available Endpoints:

```typescript
// Get LA Metro routes
GET /routes
Response: LAMetroRoute[]

// Get LA Metro stops
GET /stops
Response: LAMetroStop[]

// Get real-time arrivals
GET /stops/{stopId}/arrivals
Response: Arrival[]
```

#### Usage Example:
```typescript
import { LAMetroApiService } from '../services/api';

// Get real-time arrivals
const arrivals = await LAMetroApiService.getRealTimeArrivals('union-station');
```

## React Hook: useTransitData

**Location:** `src/hooks/useTransitData.ts`

A custom React hook that manages transit data with automatic fallback to static data.

### Usage:

```typescript
import { useTransitData } from '../hooks/useTransitData';

function MyComponent() {
  const {
    routes,
    stations,
    loading,
    error,
    refreshData,
    getRouteById,
    getStationById,
    getTransitInfo
  } = useTransitData();

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {routes.map(route => (
        <div key={route.id}>{route.name}</div>
      ))}
    </div>
  );
}
```

## Data Types

### MetroRoute
```typescript
interface MetroRoute {
  id: string;
  name: string;
  color: string;
  stations: Station[];
  coordinates: [number, number][];
  frequency: string;
  operatingHours: string;
  description: string;
}
```

### Station
```typescript
interface Station {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  lines: string[];
  address?: string;
  facilities?: string[];
}
```

### TransitInfo
```typescript
interface TransitInfo {
  routeId: string;
  stationId: string;
  direction: 'northbound' | 'southbound' | 'eastbound' | 'westbound';
  nextArrival: string;
  status: 'on_time' | 'delayed' | 'cancelled';
}
```

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
# API Configuration
REACT_APP_API_BASE_URL=https://api.metro.net
REACT_APP_GTFS_API_KEY=your_gtfs_api_key
REACT_APP_METRO_API_KEY=your_metro_api_key

# Feature Flags
REACT_APP_ENABLE_REAL_TIME=true
REACT_APP_ENABLE_GTFS=true
```

## Error Handling

All API services include comprehensive error handling:

1. **Network Errors**: Automatic retry with exponential backoff
2. **API Errors**: Graceful fallback to static data
3. **Timeout Errors**: Configurable timeout (default: 10 seconds)
4. **CORS Errors**: Handled through proper proxy configuration

## Fallback Strategy

The app implements a robust fallback strategy:

1. **Primary**: Try to fetch from real APIs
2. **Fallback**: Use static data from `metroRoutes.ts`
3. **Mock Data**: Generate realistic mock data for testing

## Real-Time Data Sources

### Available APIs:

1. **LA Metro API**: Official LA Metro transit data
2. **TransitLand API**: GTFS-compliant transit data
3. **OpenStreetMap**: Map tiles and geospatial data
4. **Custom Backend**: Your own transit API server

### Integration Steps:

1. **Set up API keys** in environment variables
2. **Configure endpoints** in `src/services/api.ts`
3. **Update data types** if needed in `src/types.ts`
4. **Test with mock data** before connecting to real APIs

## Testing APIs

### Local Development:

```bash
# Start with mock data
npm start

# Test API endpoints
curl http://localhost:3000/api/routes
curl http://localhost:3000/api/stations
```

### Production:

```bash
# Build for production
npm run build

# Deploy with real API endpoints
REACT_APP_API_BASE_URL=https://your-api-server.com npm run build
```

## Security Considerations

1. **API Keys**: Store in environment variables, never in code
2. **CORS**: Configure proper CORS headers on your API server
3. **Rate Limiting**: Implement rate limiting for API calls
4. **HTTPS**: Always use HTTPS in production
5. **Input Validation**: Validate all API inputs and outputs

## Performance Optimization

1. **Caching**: Implement response caching for static data
2. **Pagination**: Use pagination for large datasets
3. **Debouncing**: Debounce frequent API calls
4. **Lazy Loading**: Load data only when needed
5. **Error Boundaries**: Implement React error boundaries 