# Stage 1: Build the UI with the correct environment variable
FROM node:20.11.1-buster AS ui-build

WORKDIR /
RUN git clone https://github.com/rassos/eCourse.git

WORKDIR /eCourse/ui

# Pass the Docker host IP as a build argument
ARG DOCKER_HOST_IP
# Create a .env file with the correct production URL BEFORE installing dependencies/building UI
RUN echo "VITE_PROD_PB_URL=http://$DOCKER_HOST_IP:8090" > .env

# Copy package files and install dependencies
COPY ui/package*.json ./
RUN npm install

# Copy the rest of the UI source code and build it
COPY ui/ ./
RUN npm install @react-pdf-viewer/core @react-pdf-viewer/default-layout
RUN npm run build

# Stage 2: Setup and Serve PocketBase
FROM node:20.11.1-buster
WORKDIR /eCourse

# Copy the entire application
COPY . .

# Fetch the specified version of PocketBase
ARG PB_VERSION=0.21.3
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /eCourse/pb

# Move the built UI files (which now contain the correct VITE_PROD_PB_URL) into PocketBase's public folder
COPY --from=ui-build /eCourse/ui/dist /eCourse/pb/pb_public

# (Optional) Set the runtime environment variable as well (this is not used by the already-built front-end)
ENV VITE_PROD_PB_URL="http://$DOCKER_HOST_IP:8090"

EXPOSE 8090
CMD ["/eCourse/pb/pocketbase", "serve", "--http=0.0.0.0:8090"]
