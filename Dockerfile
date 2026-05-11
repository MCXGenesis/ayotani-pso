# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy project files
COPY . .

# Get Flutter dependencies
RUN flutter pub get

# Build Web release
RUN flutter build web --release

# Stage 2: Serve the web app
FROM node:20-alpine

WORKDIR /app

# Install a simple HTTP server
RUN npm install -g serve

# Copy built web files from builder stage
COPY --from=builder /app/build/web ./build/web

# Expose port 8080
EXPOSE 8080

# Serve the app on port 8080
CMD ["serve", "-s", "build/web", "-l", "8080"]