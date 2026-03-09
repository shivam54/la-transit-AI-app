import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User, AuthContextType } from '../types/auth';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check for existing authentication on app load
    const savedUser = localStorage.getItem('la-transit-user');
    if (savedUser) {
      try {
        setUser(JSON.parse(savedUser));
      } catch (error) {
        console.error('Error parsing saved user:', error);
        localStorage.removeItem('la-transit-user');
      }
    }
    setIsLoading(false);
  }, []);

  const login = async (provider: 'google' | 'guest') => {
    setIsLoading(true);
    
    try {
      if (provider === 'google') {
        // Simulate Google OAuth flow
        // In a real app, you would integrate with Google OAuth API
        const mockGoogleUser: User = {
          id: 'google_' + Date.now(),
          name: 'John Doe',
          email: 'john.doe@gmail.com',
          picture: 'https://via.placeholder.com/150/4285f4/ffffff?text=JD',
          provider: 'google'
        };
        
        setUser(mockGoogleUser);
        localStorage.setItem('la-transit-user', JSON.stringify(mockGoogleUser));
      } else {
        // Guest login
        const guestUser: User = {
          id: 'guest_' + Date.now(),
          name: 'Guest User',
          email: 'guest@example.com',
          provider: 'guest'
        };
        
        setUser(guestUser);
        localStorage.setItem('la-transit-user', JSON.stringify(guestUser));
      }
    } catch (error) {
      console.error('Login error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('la-transit-user');
  };

  const value: AuthContextType = {
    user,
    isLoading,
    login,
    logout,
    isAuthenticated: !!user
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
