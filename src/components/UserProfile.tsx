import React, { useState } from 'react';
import styled from 'styled-components';
import { User, LogOut, Settings, ChevronDown } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

const ProfileContainer = styled.div`
  position: relative;
  display: flex;
  align-items: center;
  gap: 0.5rem;
`;

const ProfileButton = styled.button`
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  cursor: pointer;
  padding: 0.5rem 1rem;
  border-radius: 25px;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 500;

  &:hover {
    background-color: rgba(255, 255, 255, 0.2);
    transform: translateY(-1px);
  }
`;

const ProfileImage = styled.img`
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
`;

const ProfileName = styled.span`
  font-size: 0.9rem;
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
`;

const DropdownMenu = styled.div<{ isOpen: boolean }>`
  position: absolute;
  top: 100%;
  right: 0;
  background: white;
  border-radius: 12px;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.12);
  min-width: 200px;
  z-index: 1000;
  opacity: ${props => props.isOpen ? 1 : 0};
  visibility: ${props => props.isOpen ? 'visible' : 'hidden'};
  transform: ${props => props.isOpen ? 'translateY(0)' : 'translateY(-10px)'};
  transition: all 0.2s ease;
  margin-top: 0.5rem;
`;

const DropdownItem = styled.button`
  width: 100%;
  padding: 0.75rem 1rem;
  border: none;
  background: none;
  text-align: left;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  color: #333;
  font-size: 0.9rem;
  transition: background-color 0.2s ease;

  &:hover {
    background-color: #f8f9fa;
  }

  &:first-child {
    border-radius: 12px 12px 0 0;
  }

  &:last-child {
    border-radius: 0 0 12px 12px;
  }

  &:only-child {
    border-radius: 12px;
  }
`;

const UserInfo = styled.div`
  padding: 1rem;
  border-bottom: 1px solid #f0f0f0;
`;

const UserName = styled.div`
  font-weight: 600;
  color: #333;
  margin-bottom: 0.25rem;
`;

const UserEmail = styled.div`
  font-size: 0.8rem;
  color: #666;
`;

const UserProfile: React.FC = () => {
  const { user, logout } = useAuth();
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  if (!user) return null;

  const handleLogout = () => {
    logout();
    setIsDropdownOpen(false);
  };

  return (
    <ProfileContainer>
      <ProfileButton onClick={() => setIsDropdownOpen(!isDropdownOpen)}>
        {user.picture ? (
          <ProfileImage src={user.picture} alt={user.name} />
        ) : (
          <User size={20} />
        )}
        <ProfileName>{user.name}</ProfileName>
        <ChevronDown size={16} />
      </ProfileButton>

      <DropdownMenu isOpen={isDropdownOpen}>
        <UserInfo>
          <UserName>{user.name}</UserName>
          <UserEmail>{user.email}</UserEmail>
        </UserInfo>
        
        <DropdownItem onClick={() => setIsDropdownOpen(false)}>
          <Settings size={16} />
          Settings
        </DropdownItem>
        
        <DropdownItem onClick={handleLogout}>
          <LogOut size={16} />
          Sign Out
        </DropdownItem>
      </DropdownMenu>
    </ProfileContainer>
  );
};

export default UserProfile;
