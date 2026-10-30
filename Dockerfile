# Serves the Annamayya anime video page with nginx. No build tools inside:
# the videos are already built and committed under video/.
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
COPY video/ /usr/share/nginx/html/video/
COPY images/cover.jpg /usr/share/nginx/html/cover.jpg
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
