export interface User {
  id: string;
  name: string;
  email: string;
  picture?: string;
  provider: 'google' | 'guest';
}

export interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  login: (provider: 'google' | 'guest') => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}
