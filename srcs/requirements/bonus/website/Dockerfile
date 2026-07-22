FROM nginx:alpine

# Copy website files
COPY site/index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
