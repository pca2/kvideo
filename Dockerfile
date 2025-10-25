# Use Ruby 3.4 Alpine for smaller image size
FROM ruby:3.4-alpine

# Install build dependencies for native extensions (sqlite3 gem)
RUN apk add --no-cache \
    build-base \
    sqlite-dev \
    sqlite

# Set working directory
WORKDIR /app

# Copy dependency files
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle install --without development

# Remove build dependencies to reduce image size
RUN apk del build-base

# Copy application code
COPY . .

# Create volume mount point for production database
VOLUME ["/app/data"]

# Set up environment to use mounted database path
ENV DATABASE_PATH=/app/data/kottke.db

# Default command runs the main script
CMD ["ruby", "kottke.rb"]
