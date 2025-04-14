"""Test script for kokoro text-to-speech in a hermetic way (no downloads)."""
import os
import sys
import torch
import io
from kokoro import KModel, KPipeline
from scipy.io import wavfile

# Define paths to model files
# First check if KOKORO_MODEL_PATH is set in the environment
KOKORO_MODEL_PATH = os.environ.get('KOKORO_MODEL_PATH')

# Define fallback paths
FALLBACK_PATHS = [
    # Nix store path (will be set during build)
    '/nix/store/kokoro-model',
]

# Find the model files
CONFIG_PATH = None
MODEL_PATH = None
VOICE_PATH = None

# Try the environment variable path first
if KOKORO_MODEL_PATH:
    potential_config = os.path.join(KOKORO_MODEL_PATH, 'models/config.json')
    potential_model = os.path.join(KOKORO_MODEL_PATH, 'models/kokoro-v1_0.pth')
    potential_voice = os.path.join(KOKORO_MODEL_PATH, 'voices/af_heart.pt')
    
    if (os.path.exists(potential_config) and 
        os.path.exists(potential_model) and 
        os.path.exists(potential_voice)):
        CONFIG_PATH = potential_config
        MODEL_PATH = potential_model
        VOICE_PATH = potential_voice
        print(f"Using model files from KOKORO_MODEL_PATH: {KOKORO_MODEL_PATH}")

# Try fallback paths if needed
if not CONFIG_PATH:
    for base_path in FALLBACK_PATHS:
        # Try the kokoro-model structure
        potential_config = os.path.join(base_path, 'models/config.json')
        potential_model = os.path.join(base_path, 'models/kokoro-v1_0.pth')
        potential_voice = os.path.join(base_path, 'voices/af_heart.pt')
        
        # Try the media directory structure
        if not os.path.exists(potential_config):
            potential_config = os.path.join(base_path, 'models/config.json')
            potential_model = os.path.join(base_path, 'models/kokoro-v1_0.pth')
            potential_voice = os.path.join(base_path, 'voices/af_heart.pt')
        
        if (os.path.exists(potential_config) and 
            os.path.exists(potential_model) and 
            os.path.exists(potential_voice)):
            CONFIG_PATH = potential_config
            MODEL_PATH = potential_model
            VOICE_PATH = potential_voice
            print(f"Using model files from fallback path: {base_path}")
            break

# Exit if we couldn't find the model files
if not CONFIG_PATH or not MODEL_PATH or not VOICE_PATH:
    print("Error: Could not find required model files.")
    print("Looked in:")
    print(f"  - KOKORO_MODEL_PATH: {KOKORO_MODEL_PATH}")
    for path in FALLBACK_PATHS:
        print(f"  - {path}")
    sys.exit(1)

OUTPUT_FILE = 'hello_world.wav'

# Set device (use CPU to avoid CUDA requirements)
device = 'cpu'
print(f"Using device: {device}")

# Initialize the model with existing files (no downloads)
print(f"Loading model from {MODEL_PATH}")
model = KModel(
    config=CONFIG_PATH,
    model=MODEL_PATH,
    disable_complex=False
)
model = model.to(device).eval()

# Create pipeline for American English
print("Creating pipeline for American English")
pipeline = KPipeline(lang_code='a', model=model)

# Load the voice model
print(f"Loading voice from {VOICE_PATH}")
voice_pack = torch.load(VOICE_PATH, weights_only=True)

# Text to convert to speech
text = "hello world"
print(f"Generating audio for text: '{text}'")

# Generate the audio using the pipeline with the voice pack
results = list(pipeline(text=text, voice=voice_pack, speed=1.0))

# Process the results
if results and results[0].audio is not None:
    # If there's only one segment, use it directly
    if len(results) == 1:
        audio = results[0].audio
    else:
        # Concatenate multiple audio segments
        audio = torch.cat([r.audio for r in results if r.audio is not None])
    
    # Get sample rate from pipeline
    sample_rate = 24000  # Default sample rate for kokoro
    
    # Save as WAV file
    print(f"Saving audio to {OUTPUT_FILE}")
    with open(OUTPUT_FILE, "wb") as f:
        with io.BytesIO() as wav_io:
            wavfile.write(wav_io, sample_rate, audio.numpy())
            f.write(wav_io.getvalue())
    
    # Verify the file was created
    if os.path.exists(OUTPUT_FILE):
        file_size = os.path.getsize(OUTPUT_FILE)
        print(f"Successfully created {OUTPUT_FILE} ({file_size} bytes)")
        print(f"Audio duration: {len(audio) / sample_rate:.2f} seconds")
    else:
        print(f"Failed to create {OUTPUT_FILE}")
else:
    print("Failed to generate audio")
