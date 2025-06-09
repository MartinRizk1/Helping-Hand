# Configuration Directory

This directory contains configuration files for the HelpingHand app.

## Security Setup

### API Key Configuration

The app requires an OpenAI API key to function. For security reasons, API keys should never be hardcoded or committed to version control.

#### Setup Instructions:

1. **Copy the template file:**
   ```bash
   cp Config/secrets.json.template Config/secrets.json
   ```

2. **Edit the secrets.json file:**
   ```json
   {
     "openai_api_key": "sk-your-actual-api-key-here"
   }
   ```

3. **Get your OpenAI API key:**
   - Visit: https://platform.openai.com/api-keys
   - Create a new API key
   - Copy the key and paste it in `secrets.json`

#### Alternative Methods:

You can also set the API key using environment variables:

```bash
export OPENAI_API_KEY="sk-your-actual-api-key-here"
```

#### Security Notes:

- ✅ `secrets.json` is automatically ignored by git (see `.gitignore`)
- ✅ Environment variables are not committed to version control
- ❌ Never commit actual API keys to git
- ❌ Never hardcode API keys in source code

## File Structure

```
Config/
├── README.md                 # This file
├── secrets.json.template     # Template for API keys (safe to commit)
└── secrets.json             # Your actual API keys (NEVER COMMIT)
```

## Troubleshooting

If you see the message "⚠️ OpenAI API key not configured!", make sure you have:
1. Created the `Config/secrets.json` file with your API key
2. OR set the `OPENAI_API_KEY` environment variable

## Production Deployment

For production deployments:
- Use environment variables or secure key management services
- Never deploy with hardcoded keys
- Consider using iOS Keychain for additional security
