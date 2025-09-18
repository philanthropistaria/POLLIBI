class PollibiApp {
    constructor() {
        this.apiUrl = 'https://7qs8m3m3v0.execute-api.us-east-1.amazonaws.com/prod/synthesize';
        this.initializeApp();
    }

    initializeApp() {
        this.bindEvents();
        this.loadVoices();
    }

    bindEvents() {
        document.getElementById('synthesizeBtn').addEventListener('click', () => {
            this.synthesizeSpeech();
        });

        // Enter key to synthesize
        document.getElementById('textInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && e.ctrlKey) {
                this.synthesizeSpeech();
            }
        });
    }

    async loadVoices() {
        // You can extend this to fetch available voices from Polly
        const voices = [
            { id: 'Joanna', name: 'Joanna (Female)' },
            { id: 'Matthew', name: 'Matthew (Male)' },
            { id: 'Ivy', name: 'Ivy (Child)' },
            { id: 'Justin', name: 'Justin (Child)' },
            { id: 'Kendra', name: 'Kendra (Female)' },
            { id: 'Kimberly', name: 'Kimberly (Female)' }
        ];

        const voiceSelect = document.getElementById('voiceSelect');
        voices.forEach(voice => {
            const option = document.createElement('option');
            option.value = voice.id;
            option.textContent = voice.name;
            voiceSelect.appendChild(option);
        });
    }

    async synthesizeSpeech() {
        const text = document.getElementById('textInput').value.trim();
        const voiceId = document.getElementById('voiceSelect').value;
        const outputFormat = document.getElementById('formatSelect').value;

        if (!text) {
            this.showError('Please enter some text to convert to speech.');
            return;
        }

        this.showLoading(true);
        this.hideError();
        this.hideOutput();

        try {
            const response = await fetch(this.apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    text: text,
                    voiceId: voiceId,
                    outputFormat: outputFormat,
                    engine: 'neural' // Using neural engine for better quality
                })
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.error || 'Failed to synthesize speech');
            }

            this.displayAudio(data.audioUrl, data.filename, voiceId);

        } catch (error) {
            this.showError(error.message || 'An error occurred while processing your request.');
        } finally {
            this.showLoading(false);
        }
    }

    displayAudio(audioUrl, filename, voiceId) {
        const audioPlayer = document.getElementById('audioPlayer');
        const downloadLink = document.getElementById('downloadLink');
        const audioInfo = document.getElementById('audioInfo');
        const outputSection = document.getElementById('outputSection');

        // Set audio source
        audioPlayer.src = audioUrl;
        
        // Set download link
        downloadLink.href = audioUrl;
        downloadLink.download = filename;
        
        // Set audio info
        audioInfo.textContent = `Voice: ${voiceId} | Generated: ${new Date().toLocaleTimeString()}`;
        
        // Show output section
        outputSection.style.display = 'block';
        
        // Play audio automatically
        audioPlayer.play().catch(e => {
            console.log('Autoplay prevented:', e);
        });
    }

    showLoading(show) {
        const loading = document.getElementById('loading');
        const synthesizeBtn = document.getElementById('synthesizeBtn');
        
        if (show) {
            loading.style.display = 'block';
            synthesizeBtn.disabled = true;
            synthesizeBtn.textContent = 'Processing...';
        } else {
            loading.style.display = 'none';
            synthesizeBtn.disabled = false;
            synthesizeBtn.textContent = '🎵 Synthesize Speech';
        }
    }

    showError(message) {
        const errorDiv = document.getElementById('error');
        errorDiv.textContent = message;
        errorDiv.style.display = 'block';
    }

    hideError() {
        document.getElementById('error').style.display = 'none';
    }

    hideOutput() {
        document.getElementById('outputSection').style.display = 'none';
    }
}

// Initialize the app when the page loads
document.addEventListener('DOMContentLoaded', () => {
    window.pollibiApp = new PollibiApp();
});

// Function to update API URL after deployment
function updateApiUrl(apiUrl) {
    window.pollibiApp.apiUrl = apiUrl;
}
