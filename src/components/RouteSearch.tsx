import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { Search, MapPin, Clock, Navigation, X } from 'lucide-react';
import { Station, MetroRoute } from '../types';

const SearchContainer = styled.div`
  position: absolute;
  top: 20px;
  left: 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  min-width: 350px;
  max-width: 450px;
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
}

const RouteSearch: React.FC<RouteSearchProps> = ({
  stations,
  routes,
  onRouteSelect,
  onClose
}) => {
  const [origin, setOrigin] = useState('');
  const [destination, setDestination] = useState('');
  const [searchResults, setSearchResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [showResults, setShowResults] = useState(false);

  // Filter stations based on input
  const filteredStations = stations.filter(station =>
    station.name.toLowerCase().includes(origin.toLowerCase()) ||
    station.name.toLowerCase().includes(destination.toLowerCase())
  );

  // Find routes between two stations
  const findRoutes = (originName: string, destName: string): SearchResult[] => {
    const originStation = stations.find(s => 
      s.name.toLowerCase().includes(originName.toLowerCase())
    );
    const destStation = stations.find(s => 
      s.name.toLowerCase().includes(destName.toLowerCase())
    );

    if (!originStation || !destStation) return [];

    const results: SearchResult[] = [];

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
          estimatedTime: `${Math.abs(destIndex - originIndex) * 3} min`
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
          // Find transfer stations (stations that exist in both routes)
          const transferStations = route1.stations.filter(station1 =>
            route2.stations.some(station2 => station2.id === station1.id)
          );

          if (transferStations.length > 0) {
            const transferStation = transferStations[0]; // Use first transfer station
            results.push({
              route: route1, // We'll show this as the primary route
              originStation,
              destinationStation: destStation,
              transferStations: [transferStation],
              totalStations: route1.stations.length + route2.stations.length,
              estimatedTime: `${(route1.stations.length + route2.stations.length) * 2} min`
            });
          }
        }
      });
    });

    return results.sort((a, b) => a.totalStations - b.totalStations);
  };

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (!origin.trim() || !destination.trim()) return;

    setLoading(true);
    setShowResults(true);

    // Simulate API delay
    setTimeout(() => {
      const results = findRoutes(origin, destination);
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
        <h3 style={{ margin: 0, fontSize: '1rem' }}>Route Search</h3>
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
            placeholder="Enter origin station..."
            value={origin}
            onChange={(e) => setOrigin(e.target.value)}
            list="stations"
          />
        </InputGroup>

        <InputGroup>
          <InputIcon>
            <Navigation size={16} />
          </InputIcon>
          <Input
            type="text"
            placeholder="Enter destination station..."
            value={destination}
            onChange={(e) => setDestination(e.target.value)}
            list="stations"
          />
        </InputGroup>

        <datalist id="stations">
          {filteredStations.map(station => (
            <option key={station.id} value={station.name} />
          ))}
        </datalist>

        <SearchButton type="submit" disabled={!origin.trim() || !destination.trim()}>
          <Search size={16} style={{ marginRight: '0.5rem' }} />
          Find Routes
        </SearchButton>
      </SearchForm>

      {showResults && (
        <ResultsContainer>
          {loading ? (
            <LoadingSpinner>Searching for routes...</LoadingSpinner>
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
              <p>Try different stations or check your spelling.</p>
            </NoResults>
          )}
        </ResultsContainer>
      )}
    </SearchContainer>
  );
};

export default RouteSearch; 