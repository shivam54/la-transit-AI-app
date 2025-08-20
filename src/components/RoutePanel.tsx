import React from 'react';
import styled from 'styled-components';
import { X, Clock, MapPin, Train, Info } from 'lucide-react';
import { MetroRoute, Station } from '../types';

const PanelContainer = styled.div`
  height: 100%;
  display: flex;
  flex-direction: column;
  background: white;
`;

const PanelHeader = styled.div`
  padding: 1.5rem;
  border-bottom: 1px solid #e0e0e0;
  display: flex;
  justify-content: space-between;
  align-items: center;
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

const PanelContent = styled.div`
  flex: 1;
  overflow-y: auto;
  padding: 1.5rem;
`;

const RouteInfo = styled.div`
  margin-bottom: 2rem;
`;

const RouteHeader = styled.div<{ color: string }>`
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
  padding: 1rem;
  background: ${props => props.color}15;
  border-left: 4px solid ${props => props.color};
  border-radius: 8px;
`;

const RouteColor = styled.div<{ color: string }>`
  width: 40px;
  height: 40px;
  background-color: ${props => props.color};
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
`;

const RouteDetails = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
`;

const InfoItem = styled.div`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #666;
  font-size: 0.9rem;
`;

const StationList = styled.div`
  margin-top: 1rem;
`;

const StationItem = styled.div<{ isSelected: boolean }>`
  padding: 1rem;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  margin-bottom: 0.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
  background-color: ${props => props.isSelected ? '#f0f8ff' : 'white'};
  border-color: ${props => props.isSelected ? '#0066cc' : '#e0e0e0'};

  &:hover {
    background-color: #f5f5f5;
    border-color: #ccc;
  }
`;

const StationName = styled.h4`
  margin: 0 0 0.5rem 0;
  color: #333;
`;

const StationDetails = styled.div`
  font-size: 0.9rem;
  color: #666;
`;

const NoSelection = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #666;
  text-align: center;
  gap: 1rem;
`;

interface RoutePanelProps {
  selectedRoute: MetroRoute | null;
  selectedStation: Station | null;
  onClose: () => void;
}

const RoutePanel: React.FC<RoutePanelProps> = ({
  selectedRoute,
  selectedStation,
  onClose
}) => {
  if (!selectedRoute) {
    return (
      <PanelContainer>
        <PanelHeader>
          <h2>Route Information</h2>
          <CloseButton onClick={onClose}>
            <X size={20} />
          </CloseButton>
        </PanelHeader>
        <PanelContent>
          <NoSelection>
            <Train size={48} />
            <h3>Select a Route</h3>
            <p>Click on a metro line on the map or legend to view detailed information.</p>
          </NoSelection>
        </PanelContent>
      </PanelContainer>
    );
  }

  return (
    <PanelContainer>
      <PanelHeader>
        <h2>Route Information</h2>
        <CloseButton onClick={onClose}>
          <X size={20} />
        </CloseButton>
      </PanelHeader>
      
      <PanelContent>
        <RouteInfo>
          <RouteHeader color={selectedRoute.color}>
            <RouteColor color={selectedRoute.color}>
              {selectedRoute.name.split(' ')[0][0]}
            </RouteColor>
            <RouteDetails>
              <h3 style={{ margin: 0 }}>{selectedRoute.name}</h3>
              <p style={{ margin: 0, color: '#666' }}>{selectedRoute.description}</p>
            </RouteDetails>
          </RouteHeader>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <InfoItem>
              <Clock size={16} />
              <span>Frequency: {selectedRoute.frequency}</span>
            </InfoItem>
            <InfoItem>
              <Clock size={16} />
              <span>Operating Hours: {selectedRoute.operatingHours}</span>
            </InfoItem>
            <InfoItem>
              <MapPin size={16} />
              <span>{selectedRoute.stations.length} Stations</span>
            </InfoItem>
          </div>
        </RouteInfo>

        <StationList>
          <h3 style={{ marginBottom: '1rem' }}>Stations</h3>
          {selectedRoute.stations.map((station) => (
            <StationItem
              key={station.id}
              isSelected={selectedStation?.id === station.id}
            >
              <StationName>{station.name}</StationName>
              <StationDetails>
                {station.address && (
                  <div style={{ marginBottom: '0.25rem' }}>
                    <MapPin size={12} style={{ display: 'inline', marginRight: '0.25rem' }} />
                    {station.address}
                  </div>
                )}
                {station.facilities && station.facilities.length > 0 && (
                  <div>
                    <Info size={12} style={{ display: 'inline', marginRight: '0.25rem' }} />
                    Facilities: {station.facilities.join(', ')}
                  </div>
                )}
              </StationDetails>
            </StationItem>
          ))}
        </StationList>
      </PanelContent>
    </PanelContainer>
  );
};

export default RoutePanel; 