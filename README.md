# LA Transit App 🚇

A comprehensive LA transit application with AI-powered chatbot, real-time navigation, and location sharing features.

## 🌟 Features

- **AI Chatbot**: Powered by Hugging Face models for intelligent route planning
- **Real-time Navigation**: Step-by-step directions with landmarks and transit info
- **Location Sharing**: Share live location with family and friends
- **Multi-modal Routes**: Metro, Bus, Walking, and Ride-sharing options
- **Bilingual Support**: English and Spanish interface
- **GPS Integration**: Real-time location detection with accuracy indicators

## 🚀 Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/la-transit-app-AI.git
   cd la-transit-app-AI
   ```

2. **Open the app**:
   - Navigate to `simple-version/` folder
   - Open `index-working-with-location-sharing.html` in your browser
   - Or run a local server: `python -m http.server 8000`

3. **Start using**:
   - Plan routes between any LA locations
   - Chat with the AI assistant
   - Share your location with friends
   - Get real-time transit information

## 🛠️ Technologies Used

- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Maps**: Leaflet.js with OpenStreetMap
- **AI**: Hugging Face API (facebook/bart-large-mnli)
- **Geolocation**: Browser GPS APIs
- **Transit Data**: LA Metro, Metrolink, and Regional Services

## 📁 Project Structure

```
la-transit-app/
├── simple-version/
│   ├── index-working-with-location-sharing.html  # Main application
│   ├── ai-features.js                           # AI chatbot functionality
│   └── ... (other files)
├── README.md
└── ... (documentation files)
```

## 🤖 AI Features

- **Intent Classification**: Understands user queries in English and Spanish
- **Smart Route Planning**: Suggests optimal routes based on preferences
- **Natural Language Processing**: Conversational interface for transit queries
- **Bilingual Support**: Full Spanish and English language support

## 📱 Features

### Route Planning
- Multi-modal transportation options
- Real-time departure information
- Step-by-step navigation
- Landmark-based directions

### Location Sharing
- Live location tracking
- Share via email, SMS, WhatsApp
- Duration-based sharing
- Real-time updates

### AI Chatbot
- Natural language queries
- Route planning assistance
- Transit information
- Bilingual conversations

## ⚙️ Configuration

### Hugging Face API
To use the AI features, you'll need a Hugging Face API token:
1. Go to [huggingface.co](https://huggingface.co)
2. Create an account and get your API token
3. Replace the token in `ai-features.js`

### Transit APIs
The app uses real LA transit data:
- LA Metro API
- Metrolink API
- Regional Transit Network

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

If you have any questions or need help, please open an issue on GitHub.

---

**Made with ❤️ for LA commuters** 