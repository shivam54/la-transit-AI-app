import React, { useEffect, useRef, useState } from 'react';
import { MapContainer, TileLayer, Polyline, Marker, Popup, CircleMarker } from 'react-leaflet';
import styled from 'styled-components';
import { metroRoutes, metroStations } from '../data/metroRoutes';
import { MetroRoute, Station, UserLocation } from '../types';
import locationService from '../services/locationService';
import 'leaflet/dist/leaflet.css';

// Fix for default markers in React Leaflet
import L from 'leaflet';
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
});

// Custom icon for user location
const userLocationIcon = L.divIcon({
  className: 'user-location-marker',
  html: `
    <div style="
      width: 20px;
      height: 20px;
      background: #667eea;
      border: 3px solid white;
      border-radius: 50%;
      box-shadow: 0 2px 6px rgba(0,0,0,0.3);
      position: relative;
    ">
      <div style="
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 8px;
        height: 8px;
        background: white;
        border-radius: 50%;
      "></div>
    </div>
  `,
  iconSize: [20, 20],
  iconAnchor: [10, 10],
});

const MapWrapper = styled.div`
  height: 100%;
  width: 100%;
`;

const RouteLegend = styled.div`
  position: absolute;
  top: 20px;
  right: 20px;
  background: white;
  padding: 1rem;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  min-width: 200px;
`;

const LegendItem = styled.div`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
  cursor: pointer;
  padding: 0.25rem;
  border-radius: 4px;
  transition: background-color 0.2s ease;

  &:hover {
    background-color: #f5f5f5;
  }
`;

const ColorSwatch = styled.div<{ color: string }>`
  width: 20px;
  height: 20px;
  background-color: ${props => props.color};
  border-radius: 4px;
  border: 1px solid #ccc;
`;

interface TransitMapProps {
  selectedRoute: MetroRoute | null;
  selectedStation: Station | null;
  onRouteSelect: (route: MetroRoute) => void;
  onStationSelect: (station: Station) => void;
}

const TransitMap: React.FC<TransitMapProps> = ({
  selectedRoute,
  selectedStation,
  onRouteSelect,
  onStationSelect
}) => {
  const mapRef = useRef<L.Map>(null);
  const [userLocation, setUserLocation] = useState<UserLocation | null>(null);

  // Center map on Los Angeles
  const center: [number, number] = [34.0522, -118.2437];
  const zoom = 11;

  useEffect(() => {
    // Get initial user location
    const getInitialLocation = async () => {
      try {
        const location = await locationService.getCurrentLocation();
        setUserLocation(location);
      } catch (error) {
        console.log('Could not get initial location:', error);
      }
    };

    getInitialLocation();
  }, []);

  useEffect(() => {
    if (selectedRoute && mapRef.current) {
      const bounds = L.latLngBounds(selectedRoute.coordinates);
      mapRef.current.fitBounds(bounds, { padding: [20, 20] });
    }
  }, [selectedRoute]);

  const handleRouteClick = (route: MetroRoute) => {
    onRouteSelect(route);
  };

  const handleStationClick = (station: Station) => {
    onStationSelect(station);
  };

  return (
    <MapWrapper>
      <MapContainer
        center={center}
        zoom={zoom}
        style={{ height: '100%', width: '100%' }}
        ref={mapRef}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        />

        {/* User location marker */}
        {userLocation && (
          <>
            <Marker
              position={[userLocation.latitude, userLocation.longitude]}
              icon={userLocationIcon}
            >
              <Popup>
                <div>
                  <h3>Your Location</h3>
                  <p>{userLocation.address || `${userLocation.latitude.toFixed(6)}, ${userLocation.longitude.toFixed(6)}`}</p>
                  <p style={{ fontSize: '12px', color: '#666' }}>
                    Accuracy: {userLocation.accuracy ? `${Math.round(userLocation.accuracy)}m` : 'Unknown'}
                  </p>
                  <p style={{ fontSize: '12px', color: '#666' }}>
                    Updated: {new Date(userLocation.timestamp).toLocaleTimeString()}
                  </p>
                </div>
              </Popup>
            </Marker>
            {/* Accuracy circle */}
            {userLocation.accuracy && (
              <CircleMarker
                center={[userLocation.latitude, userLocation.longitude]}
                radius={userLocation.accuracy}
                pathOptions={{
                  color: '#667eea',
                  fillColor: '#667eea',
                  fillOpacity: 0.1,
                  weight: 1,
                }}
              />
            )}
          </>
        )}

        {/* Draw metro routes */}
        {metroRoutes.map((route) => (
          <Polyline
            key={route.id}
            positions={route.coordinates}
            color={route.color}
            weight={6}
            opacity={selectedRoute?.id === route.id ? 1 : 0.6}
            onClick={() => handleRouteClick(route)}
            eventHandlers={{
              click: () => handleRouteClick(route),
            }}
          />
        ))}

        {/* Draw stations */}
        {metroStations.map((station) => (
          <Marker
            key={station.id}
            position={[station.latitude, station.longitude]}
            eventHandlers={{
              click: () => handleStationClick(station),
            }}
          >
            <Popup>
              <div>
                <h3>{station.name}</h3>
                <p>Lines: {station.lines.join(', ')}</p>
                {station.address && <p>Address: {station.address}</p>}
                {station.facilities && station.facilities.length > 0 && (
                  <p>Facilities: {station.facilities.join(', ')}</p>
                )}
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>

      <RouteLegend>
        <h3 style={{ margin: '0 0 1rem 0', fontSize: '1rem' }}>Metro Lines</h3>
        {metroRoutes.map((route) => (
          <LegendItem
            key={route.id}
            onClick={() => handleRouteClick(route)}
            style={{
              backgroundColor: selectedRoute?.id === route.id ? '#f0f0f0' : 'transparent'
            }}
          >
            <ColorSwatch color={route.color} />
            <span>{route.name}</span>
          </LegendItem>
        ))}
        {userLocation && (
          <LegendItem style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '1px solid #eee' }}>
            <div style={{
              width: 20,
              height: 20,
              background: '#667eea',
              border: '2px solid white',
              borderRadius: '50%',
              boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
              position: 'relative'
            }}>
              <div style={{
                position: 'absolute',
                top: '50%',
                left: '50%',
                transform: 'translate(-50%, -50%)',
                width: 6,
                height: 6,
                background: 'white',
                borderRadius: '50%'
              }}></div>
            </div>
            <span>Your Location</span>
          </LegendItem>
        )}
      </RouteLegend>
    </MapWrapper>
  );
};

export default TransitMap; 