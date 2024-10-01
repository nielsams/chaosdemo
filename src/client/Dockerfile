# Use the official Node.js image
FROM node:alpine

# Create and change to the app directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Create a directory for static files and move index.html there
RUN mkdir -p /app/public && mv /app/index.html /app/public/index.html

# Expose port 3000
EXPOSE 3000

# Start the server
CMD ["node", "server.js"]
