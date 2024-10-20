FROM node:14

# Set working directory
WORKDIR /usr/src/app

# Copy source files
COPY . .

# Install dependencies
RUN npm install

# Expose the port
EXPOSE 8081

# Start the application
CMD ["node", "index.js"]
