import React, { useState } from 'react';
import styled, { keyframes } from 'styled-components';
import { Train, User, Mail, MapPin, Clock, ArrowRight, X } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

const fadeIn = keyframes`
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
`;

const slideIn = keyframes`
  from {
    transform: translateX(-100%);
  }
  to {
    transform: translateX(0);
  }
`;

const LoginOverlay = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
  animation: ${fadeIn} 0.3s ease-out;
`;

const LoginContainer = styled.div`
  background: white;
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  overflow: hidden;
  width: 90%;
  max-width: 1000px;
  max-height: 90vh;
  display: flex;
  animation: ${slideIn} 0.4s ease-out;
`;

const LeftPanel = styled.div`
  flex: 1;
  background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
  padding: 3rem;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  color: white;
  position: relative;
  overflow: hidden;

  &::before {
    content: '';
    position: absolute;
    top: -50%;
    right: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle, rgba(255, 255, 255, 0.1) 0%, transparent 70%);
    animation: ${fadeIn} 2s ease-in-out infinite alternate;
  }
`;

const RightPanel = styled.div`
  flex: 1;
  padding: 3rem;
  display: flex;
  flex-direction: column;
  justify-content: center;
  background: white;
`;

const CloseButton = styled.button`
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  z-index: 10;

  &:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: scale(1.1);
  }
`;

const Logo = styled.div`
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 2rem;
  z-index: 5;
`;

const LogoIcon = styled(Train)`
  width: 3rem;
  height: 3rem;
`;

const LogoText = styled.h1`
  font-size: 2.5rem;
  font-weight: bold;
  margin: 0;
`;

const WelcomeText = styled.h2`
  font-size: 1.8rem;
  margin-bottom: 1rem;
  text-align: center;
  z-index: 5;
`;

const FeaturesList = styled.div`
  display: flex;
  flex-direction: column;
  gap: 1rem;
  z-index: 5;
`;

const FeatureItem = styled.div`
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.5rem 0;
`;

const FeatureIcon = styled.div`
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
`;

const LoginTitle = styled.h2`
  font-size: 2rem;
  color: #1e3c72;
  margin-bottom: 0.5rem;
  text-align: center;
`;

const LoginSubtitle = styled.p`
  color: #666;
  text-align: center;
  margin-bottom: 2rem;
  font-size: 1.1rem;
`;

const LoginOptions = styled.div`
  display: flex;
  flex-direction: column;
  gap: 1rem;
`;

const GoogleLoginButton = styled.button`
  background: #4285f4;
  color: white;
  border: none;
  padding: 1rem 2rem;
  border-radius: 12px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(66, 133, 244, 0.3);

  &:hover {
    background: #3367d6;
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(66, 133, 244, 0.4);
  }

  &:active {
    transform: translateY(0);
  }
`;

const GuestLoginButton = styled.button`
  background: transparent;
  color: #1e3c72;
  border: 2px solid #1e3c72;
  padding: 1rem 2rem;
  border-radius: 12px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  transition: all 0.3s ease;

  &:hover {
    background: #1e3c72;
    color: white;
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(30, 60, 114, 0.3);
  }

  &:active {
    transform: translateY(0);
  }
`;

const SkipButton = styled.button`
  background: none;
  border: none;
  color: #999;
  cursor: pointer;
  text-decoration: underline;
  font-size: 0.9rem;
  margin-top: 1rem;
  transition: color 0.2s ease;

  &:hover {
    color: #666;
  }
`;

const LoadingSpinner = styled.div`
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top: 2px solid white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
`;

const GoogleIcon = styled.div`
  width: 20px;
  height: 20px;
  background: white;
  border-radius: 2px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  color: #4285f4;
  font-size: 14px;
`;

interface LoginPageProps {
  onClose: () => void;
}

const LoginPage: React.FC<LoginPageProps> = ({ onClose }) => {
  const { login, isLoading } = useAuth();
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  const handleGoogleLogin = async () => {
    setIsLoggingIn(true);
    try {
      await login('google');
      onClose();
    } catch (error) {
      console.error('Google login failed:', error);
    } finally {
      setIsLoggingIn(false);
    }
  };

  const handleGuestLogin = async () => {
    setIsLoggingIn(true);
    try {
      await login('guest');
      onClose();
    } catch (error) {
      console.error('Guest login failed:', error);
    } finally {
      setIsLoggingIn(false);
    }
  };

  const handleSkip = () => {
    onClose();
  };

  return (
    <LoginOverlay onClick={onClose}>
      <LoginContainer onClick={(e) => e.stopPropagation()}>
        <LeftPanel>
          <CloseButton onClick={onClose}>
            <X size={20} />
          </CloseButton>
          
          <Logo>
            <LogoIcon />
            <LogoText>LA Transit</LogoText>
          </Logo>
          
          <WelcomeText>Welcome to LA Transit</WelcomeText>
          
          <FeaturesList>
            <FeatureItem>
              <FeatureIcon>
                <MapPin size={20} />
              </FeatureIcon>
              <span>Real-time route planning</span>
            </FeatureItem>
            <FeatureItem>
              <FeatureIcon>
                <Clock size={20} />
              </FeatureIcon>
              <span>Live transit updates</span>
            </FeatureItem>
            <FeatureItem>
              <FeatureIcon>
                <User size={20} />
              </FeatureIcon>
              <span>Personalized recommendations</span>
            </FeatureItem>
          </FeaturesList>
        </LeftPanel>
        
        <RightPanel>
          <LoginTitle>Get Started</LoginTitle>
          <LoginSubtitle>
            Sign in to save your favorite routes and get personalized transit updates
          </LoginSubtitle>
          
          <LoginOptions>
            <GoogleLoginButton onClick={handleGoogleLogin} disabled={isLoggingIn}>
              {isLoggingIn ? (
                <LoadingSpinner />
              ) : (
                <>
                  <GoogleIcon>G</GoogleIcon>
                  Continue with Google
                </>
              )}
            </GoogleLoginButton>
            
            <GuestLoginButton onClick={handleGuestLogin} disabled={isLoggingIn}>
              {isLoggingIn ? (
                <LoadingSpinner />
              ) : (
                <>
                  <User size={20} />
                  Continue as Guest
                </>
              )}
            </GuestLoginButton>
          </LoginOptions>
          
          <SkipButton onClick={handleSkip}>
            Skip for now
          </SkipButton>
        </RightPanel>
      </LoginContainer>
    </LoginOverlay>
  );
};

export default LoginPage;
