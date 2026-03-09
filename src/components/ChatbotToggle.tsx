import React from 'react';
import styled from 'styled-components';
import { MessageCircle } from 'lucide-react';

interface ChatbotToggleProps {
  onClick: () => void;
  isOpen: boolean;
}

const ToggleButton = styled.button<{ isOpen: boolean }>`
  position: fixed;
  bottom: 20px;
  right: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 50%;
  width: 60px;
  height: 60px;
  font-size: 1.5rem;
  cursor: pointer;
  box-shadow: 0 4px 20px rgba(0,0,0,0.2);
  transition: all 0.3s ease;
  z-index: 999;
  display: flex;
  align-items: center;
  justify-content: center;
  transform: ${props => props.isOpen ? 'scale(0.8)' : 'scale(1)'};
  opacity: ${props => props.isOpen ? '0' : '1'};

  &:hover {
    transform: ${props => props.isOpen ? 'scale(0.8)' : 'scale(1.1)'};
    box-shadow: 0 6px 25px rgba(0,0,0,0.3);
  }

  @media (max-width: 768px) {
    width: 50px;
    height: 50px;
    font-size: 1.2rem;
    bottom: 15px;
    right: 15px;
  }
`;

const NotificationBadge = styled.div`
  position: absolute;
  top: -5px;
  right: -5px;
  background: #dc3545;
  color: white;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  font-size: 0.7rem;
  display: flex;
  align-items: center;
  justify-content: center;
  animation: pulse 2s infinite;

  @keyframes pulse {
    0% {
      box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7);
    }
    70% {
      box-shadow: 0 0 0 10px rgba(220, 53, 69, 0);
    }
    100% {
      box-shadow: 0 0 0 0 rgba(220, 53, 69, 0);
    }
  }
`;

const ChatbotToggle: React.FC<ChatbotToggleProps> = ({ onClick, isOpen }) => {
  return (
    <ToggleButton onClick={onClick} isOpen={isOpen} title="AI Assistant">
      <MessageCircle size={24} />
      {!isOpen && <NotificationBadge>AI</NotificationBadge>}
    </ToggleButton>
  );
};

export default ChatbotToggle;
