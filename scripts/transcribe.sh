#!/bin/bash
# Local Whisper transcription script
# Usage: ./transcribe.sh /path/to/audio.ogg [language]

WHISPER_CLI="$HOME/whisper.cpp/build/bin/whisper-cli"
MODEL="$HOME/whisper.cpp/models/ggml-large-v3-turbo-q5_0.bin"

INPUT="$1"
LANG="${2:-auto}"

if [ -z "$INPUT" ]; then
    echo "Usage: $0 <audio_file> [language]"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: File not found: $INPUT"
    exit 1
fi

# Convert to WAV if needed (whisper.cpp works best with WAV)
TMPWAV=$(mktemp /tmp/whisper_XXXXXX.wav)
trap "rm -f $TMPWAV" EXIT

# Use ffmpeg to convert to 16kHz mono WAV
ffmpeg -i "$INPUT" -ar 16000 -ac 1 -c:a pcm_s16le "$TMPWAV" -y -loglevel error

# Run whisper (output just the transcribed text, no timestamps)
"$WHISPER_CLI" -m "$MODEL" -l "$LANG" -f "$TMPWAV" --no-timestamps 2>/dev/null | grep -E '^\s+' | sed 's/^[[:space:]]*//' | tr '\n' ' ' | sed 's/  */ /g'
