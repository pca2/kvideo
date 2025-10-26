# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby script that scrapes kottke.org's RSS feed for YouTube links and automatically adds them to a YouTube playlist with newest videos at the top. The script maintains a SQLite database to track processed posts and prevents duplicates.

## Development Commands

### Setup
```bash
# Install dependencies
bundle install

# Set up environment variables (copy and modify env_SAMPLE.sh)
source .env  # Your local version with actual credentials
```

### Running the Script
```bash
# Main script
ruby kottke.rb

# Or make it executable and run directly
chmod +x kottke.rb
./kottke.rb
```

### Testing
```bash
# Run all tests (uses VCR cassettes for YouTube API interactions)
bundle exec ruby ./Test/kottke_test.rb

# Run a single test (use minitest syntax)
bundle exec ruby ./Test/kottke_test.rb -n test_get_feed

# Re-record VCR cassettes (delete cassettes first)
rm -rf Test/vcr_cassettes/* && bundle exec ruby ./Test/kottke_test.rb
```

### YouTube OAuth Setup (One-time)
The script requires YouTube API credentials. Run these scripts in sequence:
```bash
# Step 1: Get authorization code
ruby get_authorize_token.rb

# Step 2: Exchange for refresh token
ruby get_refresh_code.rb
```

### Docker Usage
```bash
# Build the Docker image
docker build -t kvideo .

# Run the script with docker-compose (recommended)
docker-compose up

# Run the script with docker run
docker run --env-file env.sh -v $(pwd)/data:/app/data kvideo

# Run tests with docker-compose
docker-compose --profile test up kvideo-test

# Run tests with docker run
docker run --env-file env.sh kvideo bundle exec ruby ./Test/kottke_test.rb

# Interactive shell for debugging
docker run --env-file env.sh -v $(pwd)/data:/app/data -it kvideo sh
```

**Docker Notes:**
- The production database (`kottke.db`) is stored in the mounted `./data` directory for persistence
- Test database (`Test/kottke_test.db`) is ephemeral and lives inside the container
- VCR cassettes are included in the image for test playback
- Uses Ruby 3.4 Alpine for minimal image size (~150MB)

## Architecture

### Core Workflow (kottke.rb)
1. **Feed Processing**: Fetches RSS feed from kottke.org and checks for updates since last run
2. **Link Extraction**: Scans post content for YouTube URLs using regex patterns
3. **Database Storage**: Stores posts and video IDs in SQLite with Sequel ORM
4. **Playlist Management**: Adds new videos to YouTube playlist via Yt gem
5. **Reordering**: Ensures newest videos appear at top of playlist

### Database Schema
- **posts**: Stores blog post metadata (headline, post_url, post_date)
- **videos**: Stores YouTube video IDs with foreign key to posts
- Database path: `kottke.db` (auto-created on first run)
- Test database: `Test/kottke_test.db`

### Key Functions
- `process_feed(feed, latest_db_post, playlist)`: Main processing loop that iterates through feed entries
- `get_links(post)`: Regex extraction of YouTube URLs from post content
- `get_ids(array)`: Converts YouTube URLs to video IDs, handles multiple URL formats
- `append_to_playlist(playlist, youtube_id)`: Adds video to YouTube playlist with error handling
- `reorder_vids_from_array(playlist)`: Reorders playlist items to put newest at top

### YouTube API Integration
- Uses the Yt gem (v0.33.4) for YouTube Data API v3 interaction
- Requires OAuth 2.0 credentials (CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN)
- Playlist operations include adding videos and reordering items
- Handles `Yt::Errors::Forbidden` for restricted videos

### Environment Variables Required
Core operation:
- `CLIENT_ID`, `CLIENT_SECRET`: YouTube OAuth credentials
- `REFRESH_TOKEN`: OAuth refresh token for API access
- `PLAYLIST_ID`: Target YouTube playlist ID

Authorization setup only:
- `AUTHORIZATION_CODE`, `REDIRECT_URI`, `API_KEY`

### Testing Strategy
- Test fixtures in `Test/sample_xml/` directory contain sample RSS feeds
- Tests use a separate test database (`kottke_test.db`)
- **VCR Integration**: All YouTube API calls are recorded/replayed using VCR cassettes stored in `Test/vcr_cassettes/`
  - First test run records HTTP interactions to cassette files
  - Subsequent runs replay from cassettes (no real API calls)
  - Sensitive credentials (CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN) are filtered out
  - To re-record cassettes: delete the cassette files and run tests with valid credentials
- Tests create and delete temporary YouTube playlists (recorded in VCR cassettes)
- Tables are truncated between tests to ensure clean state

### Logging
- Outputs to STDOUT using Ruby's Logger class
- Log level set to INFO (configurable in Log class)
- Useful for debugging feed processing and YouTube API calls
