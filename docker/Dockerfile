FROM node:23-slim

WORKDIR /app

# Copy package files from app folder
COPY app/package*.json ./

RUN npm install

# Copy application code
COPY app/ .

RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
