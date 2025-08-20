import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { MapPin, Share2, Users, Clock, X, Plus, Phone, Mail, MessageCircle, Settings } from 'lucide-react';
import { UserLocation, LocationShareSettings, Contact, LocationShareSession } from '../types';
import locationService from '../services/locationService';

const LocationShareContainer = styled.div<{ isOpen: boolean }>`
  position: fixed;
  top: 0;
  right: 0;
  width: ${props => props.isOpen ? '400px' : '0'};
  height: 100vh;
  background: white;
  box-shadow: -2px 0 10px rgba(0, 0, 0, 0.1);
  transition: width 0.3s ease;
  overflow: hidden;
  z-index: 2000;
  display: flex;
  flex-direction: column;
`;

const Header = styled.div`
  padding: 20px;
  border-bottom: 1px solid #e0e0e0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
`;

const HeaderTitle = styled.h2`
  margin: 0;
  font-size: 18px;
  font-weight: 600;
`;

const CloseButton = styled.button`
  background: none;
  border: none;
  color: white;
  cursor: pointer;
  padding: 8px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  
  &:hover {
    background: rgba(255, 255, 255, 0.1);
  }
`;

const Content = styled.div`
  flex: 1;
  padding: 20px;
  overflow-y: auto;
`;

const Section = styled.div`
  margin-bottom: 24px;
`;

const SectionTitle = styled.h3`
  margin: 0 0 12px 0;
  font-size: 16px;
  font-weight: 600;
  color: #333;
  display: flex;
  align-items: center;
  gap: 8px;
`;

const StatusCard = styled.div<{ isSharing: boolean }>`
  padding: 16px;
  border-radius: 12px;
  background: ${props => props.isSharing ? '#e8f5e8' : '#f5f5f5'};
  border: 2px solid ${props => props.isSharing ? '#4caf50' : '#ddd'};
  margin-bottom: 16px;
`;

const StatusText = styled.div`
  font-size: 14px;
  color: #666;
  margin-bottom: 8px;
`;

const StatusIndicator = styled.div<{ isSharing: boolean }>`
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  color: ${props => props.isSharing ? '#4caf50' : '#666'};
`;

const LocationInfo = styled.div`
  background: #f8f9fa;
  padding: 12px;
  border-radius: 8px;
  margin-bottom: 16px;
  font-size: 14px;
  color: #666;
`;

const Button = styled.button<{ variant?: 'primary' | 'secondary' | 'danger' }>`
  padding: 12px 20px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: all 0.2s ease;
  width: 100%;
  margin-bottom: 8px;

  ${props => {
    switch (props.variant) {
      case 'primary':
        return `
          background: #667eea;
          color: white;
          &:hover {
            background: #5a6fd8;
          }
        `;
      case 'danger':
        return `
          background: #dc3545;
          color: white;
          &:hover {
            background: #c82333;
          }
        `;
      default:
        return `
          background: #f8f9fa;
          color: #333;
          border: 1px solid #ddd;
          &:hover {
            background: #e9ecef;
          }
        `;
    }
  }}
`;

const ContactsList = styled.div`
  margin-bottom: 16px;
`;

const ContactItem = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  margin-bottom: 8px;
  background: white;
`;

const ContactInfo = styled.div`
  flex: 1;
`;

const ContactName = styled.div`
  font-weight: 600;
  color: #333;
  margin-bottom: 4px;
`;

const ContactDetails = styled.div`
  font-size: 12px;
  color: #666;
`;

const ContactActions = styled.div`
  display: flex;
  gap: 4px;
`;

const ActionButton = styled.button`
  background: none;
  border: none;
  padding: 6px;
  border-radius: 4px;
  cursor: pointer;
  color: #667eea;
  
  &:hover {
    background: #f0f2ff;
  }
`;

const AddContactForm = styled.div`
  background: #f8f9fa;
  padding: 16px;
  border-radius: 8px;
  margin-bottom: 16px;
`;

const Input = styled.input`
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  margin-bottom: 8px;
  font-size: 14px;
  
  &:focus {
    outline: none;
    border-color: #667eea;
  }
`;

const SettingsRow = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
`;

const SettingsLabel = styled.div`
  font-size: 14px;
  color: #333;
`;

const SettingsValue = styled.div`
  font-size: 14px;
  color: #666;
`;

interface LocationShareProps {
  isOpen: boolean;
  onClose: () => void;
}

const LocationShare: React.FC<LocationShareProps> = ({ isOpen, onClose }) => {
  const [currentLocation, setCurrentLocation] = useState<UserLocation | null>(null);
  const [isSharing, setIsSharing] = useState(false);
  const [contacts, setContacts] = useState<Contact[]>([
    { id: '1', name: 'Mom', phone: '+1234567890', email: 'mom@example.com', isActive: true },
    { id: '2', name: 'Dad', phone: '+1234567891', email: 'dad@example.com', isActive: true },
    { id: '3', name: 'Best Friend', phone: '+1234567892', isActive: false },
  ]);
  const [showAddContact, setShowAddContact] = useState(false);
  const [newContact, setNewContact] = useState({ name: '', phone: '', email: '' });
  const [updateInterval, setUpdateInterval] = useState(30); // seconds
  const [autoStopAfter, setAutoStopAfter] = useState<number | undefined>(60); // minutes

  useEffect(() => {
    if (isOpen) {
      getCurrentLocation();
    }
  }, [isOpen]);

  const getCurrentLocation = async () => {
    try {
      const location = await locationService.getCurrentLocation();
      setCurrentLocation(location);
    } catch (error) {
      console.error('Error getting location:', error);
    }
  };

  const startSharing = async () => {
    try {
      const activeContacts = contacts.filter(contact => contact.isActive);
      if (activeContacts.length === 0) {
        alert('Please select at least one contact to share with.');
        return;
      }

      const settings: LocationShareSettings = {
        isSharing: true,
        shareWith: activeContacts,
        updateInterval,
        autoStopAfter,
      };

      await locationService.startLocationSharing(settings, (location) => {
        setCurrentLocation(location);
      });

      setIsSharing(true);

      // Auto-stop after specified time
      if (autoStopAfter) {
        setTimeout(() => {
          stopSharing();
        }, autoStopAfter * 60 * 1000);
      }
    } catch (error) {
      console.error('Error starting location sharing:', error);
      alert('Failed to start location sharing. Please check your location permissions.');
    }
  };

  const stopSharing = () => {
    locationService.stopLocationSharing();
    setIsSharing(false);
  };

  const toggleContact = (contactId: string) => {
    setContacts(contacts.map(contact =>
      contact.id === contactId
        ? { ...contact, isActive: !contact.isActive }
        : contact
    ));
  };

  const addContact = () => {
    if (newContact.name.trim()) {
      const contact: Contact = {
        id: Date.now().toString(),
        name: newContact.name,
        phone: newContact.phone || undefined,
        email: newContact.email || undefined,
        isActive: true,
      };
      setContacts([...contacts, contact]);
      setNewContact({ name: '', phone: '', email: '' });
      setShowAddContact(false);
    }
  };

  const shareViaSMS = () => {
    if (currentLocation) {
      const activeContacts = contacts.filter(contact => contact.isActive && contact.phone);
      locationService.shareViaSMS(currentLocation, activeContacts);
    }
  };

  const shareViaEmail = () => {
    if (currentLocation) {
      const activeContacts = contacts.filter(contact => contact.isActive && contact.email);
      locationService.shareViaEmail(currentLocation, activeContacts);
    }
  };

  const shareViaWhatsApp = () => {
    if (currentLocation) {
      const activeContacts = contacts.filter(contact => contact.isActive && contact.phone);
      locationService.shareViaWhatsApp(currentLocation, activeContacts);
    }
  };

  return (
    <LocationShareContainer isOpen={isOpen}>
      <Header>
        <HeaderTitle>Share Location</HeaderTitle>
        <CloseButton onClick={onClose}>
          <X size={20} />
        </CloseButton>
      </Header>

      <Content>
        <Section>
          <SectionTitle>
            <MapPin size={16} />
            Current Status
          </SectionTitle>
          <StatusCard isSharing={isSharing}>
            <StatusText>
              {isSharing ? 'Sharing location with selected contacts' : 'Location sharing is inactive'}
            </StatusText>
            <StatusIndicator isSharing={isSharing}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: isSharing ? '#4caf50' : '#ccc' }} />
              {isSharing ? 'Active' : 'Inactive'}
            </StatusIndicator>
          </StatusCard>

          {currentLocation && (
            <LocationInfo>
              <div><strong>Current Location:</strong></div>
              <div>{currentLocation.address || `${currentLocation.latitude.toFixed(6)}, ${currentLocation.longitude.toFixed(6)}`}</div>
              <div style={{ fontSize: '12px', marginTop: '4px', color: '#999' }}>
                Last updated: {new Date(currentLocation.timestamp).toLocaleTimeString()}
              </div>
            </LocationInfo>
          )}
        </Section>

        <Section>
          <SectionTitle>
            <Users size={16} />
            Share With
          </SectionTitle>
          <ContactsList>
            {contacts.map(contact => (
              <ContactItem key={contact.id}>
                <ContactInfo>
                  <ContactName>{contact.name}</ContactName>
                  <ContactDetails>
                    {contact.phone && `${contact.phone} `}
                    {contact.email && `• ${contact.email}`}
                  </ContactDetails>
                </ContactInfo>
                <ContactActions>
                  <ActionButton onClick={() => toggleContact(contact.id)}>
                    {contact.isActive ? '✓' : '○'}
                  </ActionButton>
                </ContactActions>
              </ContactItem>
            ))}
          </ContactsList>

          {!showAddContact ? (
            <Button onClick={() => setShowAddContact(true)}>
              <Plus size={16} />
              Add Contact
            </Button>
          ) : (
            <AddContactForm>
              <Input
                placeholder="Name"
                value={newContact.name}
                onChange={(e) => setNewContact({ ...newContact, name: e.target.value })}
              />
              <Input
                placeholder="Phone (optional)"
                value={newContact.phone}
                onChange={(e) => setNewContact({ ...newContact, phone: e.target.value })}
              />
              <Input
                placeholder="Email (optional)"
                value={newContact.email}
                onChange={(e) => setNewContact({ ...newContact, email: e.target.value })}
              />
              <div style={{ display: 'flex', gap: '8px' }}>
                <Button onClick={addContact} variant="primary" style={{ flex: 1 }}>
                  Add
                </Button>
                <Button onClick={() => setShowAddContact(false)} style={{ flex: 1 }}>
                  Cancel
                </Button>
              </div>
            </AddContactForm>
          )}
        </Section>

        <Section>
          <SectionTitle>
            <Settings size={16} />
            Settings
          </SectionTitle>
          <SettingsRow>
            <SettingsLabel>Update Interval</SettingsLabel>
            <SettingsValue>{updateInterval} seconds</SettingsValue>
          </SettingsRow>
          <SettingsRow>
            <SettingsLabel>Auto-stop After</SettingsLabel>
            <SettingsValue>{autoStopAfter ? `${autoStopAfter} minutes` : 'Never'}</SettingsValue>
          </SettingsRow>
        </Section>

        <Section>
          <SectionTitle>
            <Share2 size={16} />
            Quick Share
          </SectionTitle>
          <Button onClick={shareViaSMS} variant="secondary">
            <Phone size={16} />
            Share via SMS
          </Button>
          <Button onClick={shareViaEmail} variant="secondary">
            <Mail size={16} />
            Share via Email
          </Button>
          <Button onClick={shareViaWhatsApp} variant="secondary">
            <MessageCircle size={16} />
            Share via WhatsApp
          </Button>
        </Section>

        <Section>
          {!isSharing ? (
            <Button onClick={startSharing} variant="primary">
              <Share2 size={16} />
              Start Sharing Location
            </Button>
          ) : (
            <Button onClick={stopSharing} variant="danger">
              <X size={16} />
              Stop Sharing Location
            </Button>
          )}
        </Section>
      </Content>
    </LocationShareContainer>
  );
};

export default LocationShare; 