# Serve the static Learnora site with Nginx
FROM nginx:alpine

# Copy the site files into Nginx's default web root
COPY index.html /usr/share/nginx/html/index.html
COPY style.css  /usr/share/nginx/html/style.css

EXPOSE 80
