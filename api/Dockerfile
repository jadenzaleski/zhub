FROM node:18
LABEL authors="Jaden Zaleski"

# Set working directory
WORKDIR /api

# Copy package files and install dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy source code
COPY . .

# Expose port 3000 (for API access)
EXPOSE 3000

# Start the server
CMD ["node", "index.js"]