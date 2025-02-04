# Stage 1: Build the UI with the correct environment variable
FROM node:20.11.1-buster AS ui-build

WORKDIR /
RUN git clone https://github.com/rassos/eCourse.git

WORKDIR /eCourse/ui

# Copy package files and install dependencies
COPY ui/package*.json ./
RUN npm install

# Copy source code and build UI
COPY ui/ ./
RUN npm install @react-pdf-viewer/core @react-pdf-viewer/default-layout
RUN npm run build

# Stage 2: Setup and Serve PocketBase
FROM node:20.11.1-buster
WORKDIR /eCourse

# Copy the application (instead of cloning from GitHub)
COPY . .

# Fetch latest PocketBase version dynamically
ARG PB_VERSION=0.21.3
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /eCourse/pb

# Move built UI files into PocketBase's public folder
COPY --from=ui-build /eCourse/ui/dist /eCourse/pb/pb_public

# Set the Docker host IP explicitly during build
ARG DOCKER_HOST_IP
RUN echo "VITE_PROD_PB_URL=http://$DOCKER_HOST_IP:8090" > /eCourse/ui/.env

# Set environment variable for the production URL
ENV VITE_PROD_PB_URL="http://$DOCKER_HOST_IP:8090"

EXPOSE 8090
CMD ["/eCourse/pb/pocketbase", "serve", "--http=0.0.0.0:8090"]
