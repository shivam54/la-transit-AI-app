import React, { useState } from 'react';
import styled from 'styled-components';
import TransitMap from './components/TransitMap';
import RoutePanel from './components/RoutePanel';
import EnhancedRouteSearch from './components/EnhancedRouteSearch';
import Header from './components/Header';
import LocationShare from './components/LocationShare';
import EnhancedChatbot from './components/EnhancedChatbot';
import ChatbotToggle from './components/ChatbotToggle';
import LoginPage from './components/LoginPage';
import { AuthProvider } from './contexts/AuthContext';
import { MetroRoute, Station } from './types';
import { metroRoutes, metroStations } from './data/metroRoutes';

const AppContainer = styled.div`
  height: 100vh;
  display: flex;
  flex-direction: column;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
`;

const MainContent = styled.div`
  flex: 1;
  display: flex;
  position: relative;
`;

const MapContainer = styled.div`
  flex: 1;
  position: relative;
`;

const PanelContainer = styled.div<{ isOpen: boolean }>`
  width: ${props => props.isOpen ? '400px' : '0'};
  background: white;
  box-shadow: -2px 0 10px rgba(0, 0, 0, 0.1);
  transition: width 0.3s ease;
  overflow: hidden;
  z-index: 1000;
`;

function App() {
  const [selectedRoute, setSelectedRoute] = useState<MetroRoute | null>(null);
  const [isPanelOpen, setIsPanelOpen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [isLocationShareOpen, setIsLocationShareOpen] = useState(false);
  const [isChatbotOpen, setIsChatbotOpen] = useState(false);
  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const [selectedStation, setSelectedStation] = useState<Station | null>(null);

  const handleRouteSelect = (route: MetroRoute) => {
    setSelectedRoute(route);
    setIsPanelOpen(true);
    setIsSearchOpen(false);
    setIsLocationShareOpen(false);
  };

  const handleStationSelect = (station: Station) => {
    setSelectedStation(station);
  };

  const handleSearchClick = () => {
    setIsSearchOpen(!isSearchOpen);
    if (isPanelOpen) setIsPanelOpen(false);
    if (isLocationShareOpen) setIsLocationShareOpen(false);
  };

  const handleSearchClose = () => {
    setIsSearchOpen(false);
  };

  const handleLocationShareClick = () => {
    setIsLocationShareOpen(!isLocationShareOpen);
    if (isPanelOpen) setIsPanelOpen(false);
    if (isSearchOpen) setIsSearchOpen(false);
  };

  const handleLocationShareClose = () => {
    setIsLocationShareOpen(false);
  };

  const handleChatbotToggle = () => {
    setIsChatbotOpen(!isChatbotOpen);
    if (isPanelOpen) setIsPanelOpen(false);
    if (isSearchOpen) setIsSearchOpen(false);
    if (isLocationShareOpen) setIsLocationShareOpen(false);
  };

  const handleChatbotClose = () => {
    setIsChatbotOpen(false);
  };

  const handleLoginClick = () => {
    setIsLoginOpen(true);
  };

  const handleLoginClose = () => {
    setIsLoginOpen(false);
  };

  return (
    <AppContainer>
      <Header 
        onMenuClick={() => setIsPanelOpen(!isPanelOpen)} 
        onSearchClick={handleSearchClick}
        onLocationShareClick={handleLocationShareClick}
        onLoginClick={handleLoginClick}
      />
      <MainContent>
        <MapContainer>
          <TransitMap 
            selectedRoute={selectedRoute}
            selectedStation={selectedStation}
            onRouteSelect={handleRouteSelect}
            onStationSelect={handleStationSelect}
          />
          
          {isSearchOpen && (
            <EnhancedRouteSearch
              stations={metroStations}
              routes={metroRoutes}
              onRouteSelect={handleRouteSelect}
              onClose={handleSearchClose}
            />
          )}
        </MapContainer>
        
        <PanelContainer isOpen={isPanelOpen}>
          <RoutePanel 
            selectedRoute={selectedRoute}
            selectedStation={selectedStation}
            onClose={() => setIsPanelOpen(false)}
          />
        </PanelContainer>

        <LocationShare 
          isOpen={isLocationShareOpen}
          onClose={handleLocationShareClose}
        />

        <EnhancedChatbot 
          isOpen={isChatbotOpen}
          onClose={handleChatbotClose}
        />

        <ChatbotToggle 
          onClick={handleChatbotToggle}
          isOpen={isChatbotOpen}
        />

        {isLoginOpen && (
          <LoginPage onClose={handleLoginClose} />
        )}
      </MainContent>
    </AppContainer>
  );
}

const AppWithAuth: React.FC = () => {
  return (
    <AuthProvider>
      <App />
    </AuthProvider>
  );
};

export default AppWithAuth; 