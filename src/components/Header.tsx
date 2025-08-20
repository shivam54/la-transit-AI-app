import React from 'react';
import styled from 'styled-components';
import { Menu, MapPin, Clock, Train, Search, Share2 } from 'lucide-react';

const HeaderContainer = styled.header`
  background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
  color: white;
  padding: 1rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  z-index: 1000;
`;

const Logo = styled.div`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1.5rem;
  font-weight: bold;
`;

const LogoIcon = styled(Train)`
  width: 2rem;
  height: 2rem;
`;

const NavItems = styled.div`
  display: flex;
  align-items: center;
  gap: 2rem;
`;

const NavItem = styled.div`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  transition: background-color 0.2s ease;

  &:hover {
    background-color: rgba(255, 255, 255, 0.1);
  }
`;

const MenuButton = styled.button`
  background: none;
  border: none;
  color: white;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 0.5rem;
  transition: background-color 0.2s ease;

  &:hover {
    background-color: rgba(255, 255, 255, 0.1);
  }
`;

const SearchButton = styled.button`
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  cursor: pointer;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
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

const LocationShareButton = styled.button`
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  cursor: pointer;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
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

interface HeaderProps {
  onMenuClick: () => void;
  onSearchClick: () => void;
  onLocationShareClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick, onSearchClick, onLocationShareClick }) => {
  return (
    <HeaderContainer>
      <Logo>
        <LogoIcon />
        LA Transit
      </Logo>
      
      <NavItems>
        <NavItem>
          <MapPin size={20} />
          Routes
        </NavItem>
        <NavItem>
          <Clock size={20} />
          Schedule
        </NavItem>
        <SearchButton onClick={onSearchClick}>
          <Search size={18} />
          Search Routes
        </SearchButton>
        <LocationShareButton onClick={onLocationShareClick}>
          <Share2 size={18} />
          Share Location
        </LocationShareButton>
        <MenuButton onClick={onMenuClick}>
          <Menu size={24} />
        </MenuButton>
      </NavItems>
    </HeaderContainer>
  );
};

export default Header; 