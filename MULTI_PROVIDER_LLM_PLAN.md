# Multi-Provider LLM Profiles Plan

## Objectives

- Allow users to configure and switch between multiple LLM providers (OpenAI, OpenRouter, Anthropic, Ollama, etc.) without losing credentials or per-provider settings.
- Support "profiles" so users can predefine model + provider + tuning parameters and quickly choose which profile Triplo should use at runtime.
- Make the configuration intuitive inside the existing **API & Models** tab while keeping backward compatibility with the current `settings` structure and environment seeding.

## Current State

- `settings.ai_source` stores a single provider choice (`open_ai`, `open_router`, `anthropic`, `ollama`).
- Separate fields (`openai_key`, `openrouter_key`, `anthropic_key`, `ollama_url`, etc.) hold provider-specific credentials.
- Enablement flags (`enable_openai_key`, etc.) exist but simply gate the current provider.
- UI presents a single provider dropdown and shared controls—users cannot keep multiple provider configs in parallel.

## Requirements

1. **Profiles Model**
   - Each profile should capture provider type, credential references, model selection, and tuning controls (temp, presence penalty, extra flags).
   - Profiles need friendly names and an "active" flag.
   - Must persist to `config.json` so that restarting the container restores the same profile set.
2. **Provider Credentials**
   - Store secrets once per provider; multiple profiles can reference the same credential entry.
   - Continue honoring environment variables on first run for seeding.
3. **UI Experience**
   - Display a profile list/card view within the API & Models tab.
   - Provide actions to add, duplicate, delete, and reorder profiles.
   - Offer a quick toggle to mark the active profile Triplo should use.
4. **Runtime Behavior**
   - Backend should expose the active profile via `/api/config` and `/api/status`.
   - Saving config should validate the active profile has all required fields for its provider.
   - Triplo restart should load the active profile and pass the right provider settings to the desktop app.
5. **Compatibility**
   - Existing configs without `llm_profiles` should auto-convert: build a default profile from current single-provider settings.
   - CLI/env seeding continues to populate legacy fields; conversion happens when Web UI saves.

## Proposed Data Shape

```json
{
  "settings": {
    "llm_profiles": [
      {
        "id": "profile-uuid",
        "name": "OpenAI - Creative",
        "provider": "open_ai",
        "model": "gpt-4o",
        "temperature": 0.7,
        "presence_penalty": 0,
        "options": {
          "max_tokens": 4096,
          "json_mode": false
        }
      }
    ],
    "active_llm_profile": "profile-uuid",
    "provider_credentials": {
      "open_ai": { "api_key": "..." },
      "open_router": { "api_key": "..." },
      "anthropic": { "api_key": "..." },
      "ollama": { "url": "http://localhost:11434", "models": ["qwen2"], "token": null }
    }
  }
}
```

- `provider_credentials` keeps secrets centralized.
- Profiles reference a provider enum; Ollama profiles can also embed `model_pull` info or local params.

## UI/UX Outline

1. **Profiles Sidebar (API & Models tab)**
   - Left column listing profiles with status indicator (active). Buttons: `+ New Profile`, `Duplicate`, `Delete`.
2. **Profile Editor Pane**
   - Provider selector (OpenAI/OpenRouter/Anthropic/Ollama/Custom HTTP).
   - Provider-specific credential inputs (keys, base URLs). When a credential already exists, show it masked with an "Update" button.
   - Model dropdown (pull from provider APIs when possible—reuse existing model fetch code for Ollama).
   - Advanced options accordion: temperature, penalties, JSON mode, streaming toggle, etc.
   - Save button for profile plus a "Set as Active" checkbox.
3. **Global Controls**
   - Toggle to enable multi-provider mode (defaults on once multiple profiles exist).
   - Display the active profile summary in the header/status bar.

## Backend/Config Changes

1. Extend `webui/app.py`:
   - New endpoints: `/api/llm/profiles` (list/add/update/delete), `/api/llm/profile/activate`.
   - Validation helpers per provider.
   - Migration helper to convert legacy settings into the new structure when `llm_profiles` missing.
2. Update `init-config.sh` and `config-template.json`:
   - Seed `llm_profiles` array with one profile based on env values (provider from `TRIPLO_AI_SOURCE`).
   - Capture provider credentials inside `provider_credentials` map.
3. Update `webui/templates/index.html` JS:
   - Replace current single-provider form with profile manager UI.
   - Add state management for profiles (load/save via new API).
   - Keep existing fields for voice, display, etc. untouched.

## Testing Plan

- Unit-test migration helper (legacy config -> new structure).
- API integration tests for profile CRUD and activation.
- Frontend tests (if/when a framework is added) or manual test script: create profile per provider, switch active profile, ensure Triplo restarts with new provider.
- Regression tests for Ollama model refresh and encryption key generation (untouched code paths).

## Next Steps

1. Implement backend data model + migration logic.
2. Build API endpoints and update config save/load paths.
3. Redesign the API & Models tab to hook into the new endpoints.
4. Document usage in README/WEBUI-README, including how to manage multiple profiles.
5. Add CLI instructions for seeding multiple profiles via JSON import (optional future enhancement).
