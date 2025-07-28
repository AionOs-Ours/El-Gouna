# STAGE 1: Build
FROM node:18-alpine AS build
# Installing libvips-dev for sharp compatibility
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev nasm bash vips-dev git
# Set the working directory
WORKDIR /opt/app
# Copy package.json and yarn.lock
COPY package.json yarn.lock ./
# Install dependencies
RUN yarn install --frozen-lockfile
# Copy the rest of the application
COPY . .
# Build the application for production
RUN NODE_ENV=production yarn build

# STAGE 2: Production
FROM node:18-alpine
# Installing libvips-dev for sharp compatibility
RUN apk update && apk add --no-cache vips-dev
# Set the working directory
WORKDIR /opt/app
# Copy package.json and yarn.lock
COPY package.json yarn.lock ./
# Install only production dependencies
RUN yarn install --production --frozen-lockfile
# Copy the built application from the build stage
COPY --from=build /opt/app/dist ./dist
# Copy the .env.example file
COPY --from=build /opt/app/.env.example ./.env
# Copy the public folder
COPY --from=build /opt/app/public ./public
# Copy Strapi config
COPY --from=build /opt/app/config ./config
# Copy database folder
COPY --from=build /opt/app/database ./database
# Set environment to production
ENV NODE_ENV=production
# Expose port
EXPOSE 1337
# Start the application
CMD ["yarn", "start"]
