/**
 * Authentication Manager for LA Transit App
 * Handles user login, logout, and authentication state
 */

class AuthManager {
    constructor() {
        this.currentUser = this.getStoredUser();
        this.init();
    }

    init() {
        // Initialize authentication UI
        this.updateAuthUI();
        
        // Listen for storage changes (for multi-tab sync)
        window.addEventListener('storage', (e) => {
            if (e.key === 'la-transit-user') {
                this.currentUser = this.getStoredUser();
                this.updateAuthUI();
            }
        });
    }

    getStoredUser() {
        const user = localStorage.getItem('la-transit-user');
        return user ? JSON.parse(user) : null;
    }

    storeUser(user) {
        localStorage.setItem('la-transit-user', JSON.stringify(user));
        this.currentUser = user;
        this.updateAuthUI();
    }

    clearUser() {
        localStorage.removeItem('la-transit-user');
        this.currentUser = null;
        this.updateAuthUI();
    }

    isAuthenticated() {
        return this.currentUser !== null;
    }

    getCurrentUser() {
        return this.currentUser;
    }

    updateAuthUI() {
        const userProfile = document.getElementById('user-profile');
        
        if (this.isAuthenticated()) {
            // Show user profile
            if (userProfile) {
                userProfile.style.display = 'flex';
                this.updateUserProfile();
            }
        } else {
            // Hide user profile and redirect to login
            if (userProfile) userProfile.style.display = 'none';
            this.redirectToLogin();
        }
    }

    updateUserProfile() {
        const userName = document.getElementById('user-name');
        const userEmail = document.getElementById('user-email');
        const userAvatar = document.getElementById('user-avatar');
        
        if (this.currentUser) {
            if (userName) userName.textContent = this.currentUser.name;
            if (userEmail) userEmail.textContent = this.currentUser.email;
            if (userAvatar) {
                if (this.currentUser.picture) {
                    userAvatar.src = this.currentUser.picture;
                    userAvatar.style.display = 'block';
                } else {
                    userAvatar.style.display = 'none';
                }
            }
        }
    }

    showLoginModal() {
        // Redirect to login page
        window.location.href = '/';
    }

    redirectToLogin() {
        // Redirect to login page if not authenticated
        if (window.location.pathname !== '/' && window.location.pathname !== '/login.html') {
            window.location.href = '/';
        }
    }

    logout() {
        this.clearUser();
        // Redirect to login page after logout
        window.location.href = '/';
    }

    // Get user preferences (for future use)
    getUserPreferences() {
        if (!this.isAuthenticated()) return {};
        
        const prefs = localStorage.getItem(`user-preferences-${this.currentUser.id}`);
        return prefs ? JSON.parse(prefs) : {};
    }

    // Save user preferences (for future use)
    saveUserPreferences(preferences) {
        if (!this.isAuthenticated()) return;
        
        localStorage.setItem(`user-preferences-${this.currentUser.id}`, JSON.stringify(preferences));
    }
}

// Initialize global auth manager
window.authManager = new AuthManager();

// Utility functions for easy access
window.login = () => window.authManager.showLoginModal();
window.logout = () => window.authManager.logout();
window.isLoggedIn = () => window.authManager.isAuthenticated();
window.getCurrentUser = () => window.authManager.getCurrentUser();
