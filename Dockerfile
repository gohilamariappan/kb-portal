FROM node:18.12.1 AS build

WORKDIR /app

RUN npm install -g @angular/cli@14.2.0
COPY package*.json ./
RUN npm install

COPY . .
RUN ng build --configuration=production


# ===============================
# Final Stage - Run as appuser
# ===============================
FROM node:18.12.1 AS final

# Create non-root user
RUN useradd -m appuser

WORKDIR /usr/src/app

# Copy build output with user ownership
COPY --from=build --chown=appuser:appuser /app/dist/kb-survey/ ./dist/

# Install serve globally (done as root)
RUN npm install -g serve

RUN apt-get update && apt-get install -y libcap2-bin \
    && setcap 'cap_net_bind_service=+ep' /usr/local/bin/node

# Change dist folder ownership
RUN chown -R appuser:appuser /usr/src/app

# Switch to non-root user
USER appuser

EXPOSE 80

CMD ["serve", "-s", "dist", "-p", "80"]
