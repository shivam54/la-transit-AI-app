import React, { useState, useEffect, useRef } from 'react';
import styled from 'styled-components';
import { Search, MapPin, Clock, Navigation, X, Loader } from 'lucide-react';
import { Station, MetroRoute } from '../types';

const SearchContainer = styled.div`
  position: absolute;
  top: 20px;
  left: 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  min-width: 400px;
  max-width: 500px;
`;

const SearchHeader = styled.div`
  padding: 1rem;
  border-bottom: 1px solid #e0e0e0;
  display: flex;
  justify-content: space-between;
  align-items: center;
`;

const SearchForm = styled.form`
  padding: 1rem;
`;

const InputGroup = styled.div`
  margin-bottom: 1rem;
  position: relative;
`;

const Input = styled.input`
  width: 100%;
  padding: 0.75rem 1rem 0.75rem 2.5rem;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  font-size: 0.9rem;
  transition: border-color 0.2s ease;

  &:focus {
    outline: none;
    border-color: #0066cc;
    box-shadow: 0 0 0 3px rgba(0, 102, 204, 0.1);
  }
`;

const InputIcon = styled.div`
  position: absolute;
  left: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  color: #666;
`;

const SuggestionsDropdown = styled.div`
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 1px solid #e0e0e0;
  border-top: none;
  border-radius: 0 0 8px 8px;
  max-height: 200px;
  overflow-y: auto;
  z-index: 1001;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
`;

const SuggestionItem = styled.div`
  padding: 0.75rem 1rem;
  cursor: pointer;
  border-bottom: 1px solid #f0f0f0;
  transition: background-color 0.2s ease;

  &:hover {
    background-color: #f8f9fa;
  }

  &:last-child {
    border-bottom: none;
  }
`;

const SuggestionText = styled.div`
  font-size: 0.9rem;
  color: #333;
`;

const SuggestionSubtext = styled.div`
  font-size: 0.8rem;
  color: #666;
  margin-top: 0.25rem;
`;

const SearchButton = styled.button`
  width: 100%;
  padding: 0.75rem;
  background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s ease;

  &:hover {
    transform: translateY(-1px);
  }

  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
    transform: none;
  }
`;

const ResultsContainer = styled.div`
  max-height: 400px;
  overflow-y: auto;
`;

const RouteResult = styled.div`
  padding: 1rem;
  border-bottom: 1px solid #f0f0f0;
  cursor: pointer;
  transition: background-color 0.2s ease;

  &:hover {
    background-color: #f8f9fa;
  }

  &:last-child {
    border-bottom: none;
  }
`;

const RouteHeader = styled.div`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
`;

const RouteColor = styled.div<{ color: string }>`
  width: 16px;
  height: 16px;
  background-color: ${props => props.color};
  border-radius: 50%;
`;

const RouteName = styled.h4`
  margin: 0;
  color: #333;
  font-size: 0.9rem;
`;

const RouteDetails = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  font-size: 0.8rem;
  color: #666;
`;

const RouteInfo = styled.div`
  display: flex;
  align-items: center;
  gap: 0.5rem;
`;

const TransferInfo = styled.div`
  background: #f0f8ff;
  padding: 0.5rem;
  border-radius: 6px;
  margin-top: 0.5rem;
  font-size: 0.8rem;
  color: #0066cc;
`;

const NoResults = styled.div`
  padding: 2rem;
  text-align: center;
  color: #666;
`;

const LoadingSpinner = styled.div`
  padding: 2rem;
  text-align: center;
  color: #666;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
`;

const CloseButton = styled.button`
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 0.5rem;
  transition: background-color 0.2s ease;

  &:hover {
    background-color: #f5f5f5;
  }
`;

const LocationInfo = styled.div`
  background: #f8f9fa;
  padding: 0.5rem;
  border-radius: 6px;
  margin-top: 0.5rem;
  font-size: 0.8rem;
  color: #666;
`;

interface RouteSearchProps {
  stations: Station[];
  routes: MetroRoute[];
  onRouteSelect: (route: MetroRoute) => void;
  onClose: () => void;
}

interface SearchResult {
  route: MetroRoute;
  originStation: Station;
  destinationStation: Station;
  transferStations: Station[];
  totalStations: number;
  estimatedTime: string;
  originLocation?: { lat: number; lng: number; name: string };
  destinationLocation?: { lat: number; lng: number; name: string };
}

interface AddressSuggestion {
  address: string;
  lat: number;
  lng: number;
  relevance: number;
}

const EnhancedRouteSearch: React.FC<RouteSearchProps> = ({
  stations,
  routes,
  onRouteSelect,
  onClose
}) => {
  const [origin, setOrigin] = useState('');
  const [destination, setDestination] = useState('');
  const [originSuggestions, setOriginSuggestions] = useState<AddressSuggestion[]>([]);
  const [destinationSuggestions, setDestinationSuggestions] = useState<AddressSuggestion[]>([]);
  const [showOriginSuggestions, setShowOriginSuggestions] = useState(false);
  const [showDestinationSuggestions, setShowDestinationSuggestions] = useState(false);
  const [searchResults, setSearchResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const [originLocation, setOriginLocation] = useState<{ lat: number; lng: number; name: string } | null>(null);
  const [destinationLocation, setDestinationLocation] = useState<{ lat: number; lng: number; name: string } | null>(null);

  const originTimeoutRef = useRef<NodeJS.Timeout>();
  const destinationTimeoutRef = useRef<NodeJS.Timeout>();

  // Enhanced address suggestions using Photon API
  const getAddressSuggestions = async (query: string): Promise<AddressSuggestion[]> => {
    if (query.length < 2) return [];

    try {
      // Try Photon API first
      const photonUrl = `https://photon.komoot.io/api?q=${encodeURIComponent(query + ', Los Angeles, CA')}&limit=5`;
      const response = await fetch(photonUrl);
      const data = await response.json();

      if (data.features && data.features.length > 0) {
        return data.features.map((feature: any) => ({
          address: feature.properties.name || feature.properties.display_name,
          lat: feature.geometry.coordinates[1],
          lng: feature.geometry.coordinates[0],
          relevance: 250
        }));
      }
    } catch (error) {
      console.warn('Photon API failed, using local suggestions:', error);
    }

    // Fallback to local suggestions
    const localSuggestions = getLocalSuggestions(query);
    return localSuggestions;
  };

  // Local suggestions database
  const getLocalSuggestions = (query: string): AddressSuggestion[] => {
    const lowerQuery = query.toLowerCase();
    const suggestions: AddressSuggestion[] = [];

    // Enhanced local database
    const localDB = {
      'usc': { lat: 34.0224, lng: -118.2851, name: 'University of Southern California (USC), Los Angeles, CA' },
      'ucla': { lat: 34.0689, lng: -118.4452, name: 'University of California, Los Angeles (UCLA), Los Angeles, CA' },
      'hollywood sign': { lat: 34.1341, lng: -118.3216, name: 'Hollywood Sign, Los Angeles, CA' },
      'griffith observatory': { lat: 34.1185, lng: -118.3004, name: 'Griffith Observatory, Los Angeles, CA' },
      'santa monica pier': { lat: 34.0089, lng: -118.5001, name: 'Santa Monica Pier, Santa Monica, CA' },
      'venice beach': { lat: 33.9850, lng: -118.4695, name: 'Venice Beach, Los Angeles, CA' },
      'disneyland': { lat: 33.8121, lng: -117.9190, name: 'Disneyland Resort, Anaheim, CA' },
      'universal studios': { lat: 34.1381, lng: -118.3534, name: 'Universal Studios Hollywood, Los Angeles, CA' },
      'getty center': { lat: 34.0780, lng: -118.4743, name: 'The Getty Center, Los Angeles, CA' },
      'lacma': { lat: 34.0637, lng: -118.3595, name: 'Los Angeles County Museum of Art (LACMA), Los Angeles, CA' },
      'lax': { lat: 33.9416, lng: -118.4085, name: 'Los Angeles International Airport (LAX), Los Angeles, CA' },
      'downtown la': { lat: 34.0522, lng: -118.2437, name: 'Downtown Los Angeles, CA' },
      'beverly hills': { lat: 34.0736, lng: -118.4004, name: 'Beverly Hills, CA' },
      'santa monica': { lat: 34.0195, lng: -118.4912, name: 'Santa Monica, CA' },
      'pasadena': { lat: 34.1478, lng: -118.1445, name: 'Pasadena, CA' },
      'union station': { lat: 34.0560, lng: -118.2340, name: 'Union Station, Los Angeles, CA' },
      'dodger stadium': { lat: 34.0736, lng: -118.2400, name: 'Dodger Stadium, Los Angeles, CA' },
      'staple center': { lat: 34.0430, lng: -118.2673, name: 'Crypto.com Arena (formerly Staples Center), Los Angeles, CA' },
      'the grove': { lat: 34.0762, lng: -118.3587, name: 'The Grove, Los Angeles, CA' },
      'beverly center': { lat: 34.0762, lng: -118.3770, name: 'Beverly Center, Los Angeles, CA' }
    };

    // Direct matches
    for (const [key, location] of Object.entries(localDB)) {
      if (key.includes(lowerQuery) || lowerQuery.includes(key)) {
        suggestions.push({
          address: location.name,
          lat: location.lat,
          lng: location.lng,
          relevance: 100
        });
      }
    }

    // Add station matches
    stations.forEach(station => {
      if (station.name.toLowerCase().includes(lowerQuery)) {
        suggestions.push({
          address: `${station.name} Station, Los Angeles, CA`,
          lat: station.latitude,
          lng: station.longitude,
          relevance: 150
        });
      }
    });

    return suggestions.sort((a, b) => b.relevance - a.relevance).slice(0, 5);
  };

  // Debounced address suggestions
  useEffect(() => {
    if (originTimeoutRef.current) {
      clearTimeout(originTimeoutRef.current);
    }

    if (origin.length >= 2) {
      originTimeoutRef.current = setTimeout(async () => {
        const suggestions = await getAddressSuggestions(origin);
        setOriginSuggestions(suggestions);
        setShowOriginSuggestions(true);
      }, 300);
    } else {
      setOriginSuggestions([]);
      setShowOriginSuggestions(false);
    }

    return () => {
      if (originTimeoutRef.current) {
        clearTimeout(originTimeoutRef.current);
      }
    };
  }, [origin]);

  useEffect(() => {
    if (destinationTimeoutRef.current) {
      clearTimeout(destinationTimeoutRef.current);
    }

    if (destination.length >= 2) {
      destinationTimeoutRef.current = setTimeout(async () => {
        const suggestions = await getAddressSuggestions(destination);
        setDestinationSuggestions(suggestions);
        setShowDestinationSuggestions(true);
      }, 300);
    } else {
      setDestinationSuggestions([]);
      setShowDestinationSuggestions(false);
    }

    return () => {
      if (destinationTimeoutRef.current) {
        clearTimeout(destinationTimeoutRef.current);
      }
    };
  }, [destination]);

  const handleOriginSuggestionSelect = (suggestion: AddressSuggestion) => {
    setOrigin(suggestion.address);
    setOriginLocation({ lat: suggestion.lat, lng: suggestion.lng, name: suggestion.address });
    setShowOriginSuggestions(false);
  };

  const handleDestinationSuggestionSelect = (suggestion: AddressSuggestion) => {
    setDestination(suggestion.address);
    setDestinationLocation({ lat: suggestion.lat, lng: suggestion.lng, name: suggestion.address });
    setShowDestinationSuggestions(false);
  };

  // Find nearest stations to coordinates
  const findNearestStations = (lat: number, lng: number, count: number = 3): Station[] => {
    const stationsWithDistance = stations.map(station => ({
      ...station,
      distance: Math.sqrt(
        Math.pow(station.latitude - lat, 2) + Math.pow(station.longitude - lng, 2)
      )
    }));

    return stationsWithDistance
      .sort((a, b) => a.distance - b.distance)
      .slice(0, count);
  };

  // Enhanced route finding with location-based search
  const findRoutes = (originLoc: { lat: number; lng: number; name: string }, 
                     destLoc: { lat: number; lng: number; name: string }): SearchResult[] => {
    const originStations = findNearestStations(originLoc.lat, originLoc.lng);
    const destStations = findNearestStations(destLoc.lat, destLoc.lng);

    const results: SearchResult[] = [];

    // Find routes between nearest stations
    originStations.forEach(originStation => {
      destStations.forEach(destStation => {
        // Find direct routes
        routes.forEach(route => {
          const originIndex = route.stations.findIndex(s => s.id === originStation.id);
          const destIndex = route.stations.findIndex(s => s.id === destStation.id);

          if (originIndex !== -1 && destIndex !== -1) {
            const stationsInBetween = route.stations.slice(
              Math.min(originIndex, destIndex),
              Math.max(originIndex, destIndex) + 1
            );

            results.push({
              route,
              originStation,
              destinationStation: destStation,
              transferStations: [],
              totalStations: Math.abs(destIndex - originIndex) + 1,
              estimatedTime: `${Math.abs(destIndex - originIndex) * 3} min`,
              originLocation: originLoc,
              destinationLocation: destLoc
            });
          }
        });

        // Find routes with transfers
        routes.forEach(route1 => {
          routes.forEach(route2 => {
            if (route1.id === route2.id) return;

            const originInRoute1 = route1.stations.find(s => s.id === originStation.id);
            const destInRoute2 = route2.stations.find(s => s.id === destStation.id);

            if (originInRoute1 && destInRoute2) {
              const transferStations = route1.stations.filter(station1 =>
                route2.stations.some(station2 => station2.id === station1.id)
              );

              if (transferStations.length > 0) {
                const transferStation = transferStations[0];
                results.push({
                  route: route1,
                  originStation,
                  destinationStation: destStation,
                  transferStations: [transferStation],
                  totalStations: route1.stations.length + route2.stations.length,
                  estimatedTime: `${(route1.stations.length + route2.stations.length) * 2} min`,
                  originLocation: originLoc,
                  destinationLocation: destLoc
                });
              }
            }
          });
        });
      });
    });

    return results.sort((a, b) => a.totalStations - b.totalStations);
  };

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!originLocation || !destinationLocation) return;

    setLoading(true);
    setShowResults(true);

    // Simulate API delay
    setTimeout(() => {
      const results = findRoutes(originLocation, destinationLocation);
      setSearchResults(results);
      setLoading(false);
    }, 1000);
  };

  const handleRouteSelect = (result: SearchResult) => {
    onRouteSelect(result.route);
    setShowResults(false);
  };

  return (
    <SearchContainer>
      <SearchHeader>
        <h3 style={{ margin: 0, fontSize: '1rem' }}>Enhanced Route Search</h3>
        <CloseButton onClick={onClose}>
          <X size={20} />
        </CloseButton>
      </SearchHeader>

      <SearchForm onSubmit={handleSearch}>
        <InputGroup>
          <InputIcon>
            <MapPin size={16} />
          </InputIcon>
          <Input
            type="text"
            placeholder="Enter origin (e.g., USC, Hollywood Sign, 123 Main St)..."
            value={origin}
            onChange={(e) => setOrigin(e.target.value)}
          />
          {showOriginSuggestions && originSuggestions.length > 0 && (
            <SuggestionsDropdown>
              {originSuggestions.map((suggestion, index) => (
                <SuggestionItem
                  key={index}
                  onClick={() => handleOriginSuggestionSelect(suggestion)}
                >
                  <SuggestionText>{suggestion.address}</SuggestionText>
                  <SuggestionSubtext>
                    {suggestion.lat.toFixed(4)}, {suggestion.lng.toFixed(4)}
                  </SuggestionSubtext>
                </SuggestionItem>
              ))}
            </SuggestionsDropdown>
          )}
        </InputGroup>

        <InputGroup>
          <InputIcon>
            <Navigation size={16} />
          </InputIcon>
          <Input
            type="text"
            placeholder="Enter destination (e.g., UCLA, Santa Monica Pier)..."
            value={destination}
            onChange={(e) => setDestination(e.target.value)}
          />
          {showDestinationSuggestions && destinationSuggestions.length > 0 && (
            <SuggestionsDropdown>
              {destinationSuggestions.map((suggestion, index) => (
                <SuggestionItem
                  key={index}
                  onClick={() => handleDestinationSuggestionSelect(suggestion)}
                >
                  <SuggestionText>{suggestion.address}</SuggestionText>
                  <SuggestionSubtext>
                    {suggestion.lat.toFixed(4)}, {suggestion.lng.toFixed(4)}
                  </SuggestionSubtext>
                </SuggestionItem>
              ))}
            </SuggestionsDropdown>
          )}
        </InputGroup>

        <SearchButton type="submit" disabled={!originLocation || !destinationLocation}>
          <Search size={16} style={{ marginRight: '0.5rem' }} />
          Find Routes
        </SearchButton>
      </SearchForm>

      {showResults && (
        <ResultsContainer>
          {loading ? (
            <LoadingSpinner>
              <Loader size={16} className="animate-spin" />
              Searching for routes...
            </LoadingSpinner>
          ) : searchResults.length > 0 ? (
            searchResults.map((result, index) => (
              <RouteResult key={index} onClick={() => handleRouteSelect(result)}>
                <RouteHeader>
                  <RouteColor color={result.route.color} />
                  <RouteName>{result.route.name}</RouteName>
                </RouteHeader>
                
                <RouteDetails>
                  <RouteInfo>
                    <MapPin size={12} />
                    <span>{result.originStation.name} → {result.destinationStation.name}</span>
                  </RouteInfo>
                  
                  <RouteInfo>
                    <Clock size={12} />
                    <span>~{result.estimatedTime}</span>
                  </RouteInfo>
                  
                  <RouteInfo>
                    <span>• {result.totalStations} stations</span>
                  </RouteInfo>
                </RouteDetails>

                {result.originLocation && (
                  <LocationInfo>
                    From: {result.originLocation.name}
                  </LocationInfo>
                )}

                {result.destinationLocation && (
                  <LocationInfo>
                    To: {result.destinationLocation.name}
                  </LocationInfo>
                )}

                {result.transferStations.length > 0 && (
                  <TransferInfo>
                    Transfer at: {result.transferStations.map(s => s.name).join(', ')}
                  </TransferInfo>
                )}
              </RouteResult>
            ))
          ) : (
            <NoResults>
              <h4>No routes found</h4>
              <p>Try different locations or check your spelling.</p>
            </NoResults>
          )}
        </ResultsContainer>
      )}
    </SearchContainer>
  );
};

export default EnhancedRouteSearch;
