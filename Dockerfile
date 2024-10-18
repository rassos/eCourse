FROM node:20.11.1-buster

WORKDIR /

RUN git clone https://github.com/rassos/eCourse.git

ARG PB_VERSION=0.21.3
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /eCourse/pb

WORKDIR /eCourse/ui

RUN grep -qxF 'VITE_PROD_PB_URL=' .env || echo 'VITE_PROD_PB_URL=http://ecourse:8090' >> .env
RUN npm install
RUN npm run build
RUN mv dist/* /eCourse/pb/pb_public

EXPOSE 8090

CMD ["/eCourse/pb/pocketbase", "serve", "--http=0.0.0.0:8090"]
