# Usa una imagen base oficial de Nginx.
# Esto proporciona un entorno ligero y optimizado para servir contenido web estático.
FROM nginx:alpine

# Copia los archivos de tu aplicación (HTML, CSS, JS) al directorio de Nginx.
# /usr/share/nginx/html es el directorio por defecto donde Nginx busca los archivos web.
# El "." al final de la primera línea indica que copie todo el contenido
# del directorio actual (donde se encuentra el Dockerfile).
COPY . /usr/share/nginx/html

# Opcional: Si tienes una configuración personalizada de Nginx, puedes copiarla aquí.
# Por ahora, Nginx usará su configuración por defecto que es adecuada para servir archivos estáticos.
# Si necesitas una configuración personalizada, crearías un archivo `nginx.conf`
# en tu directorio local y lo copiarías así:
# COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Expone el puerto 80 del contenedor, que es el puerto por defecto de Nginx.
# Esto permite que el tráfico externo llegue al servidor web dentro del contenedor.
EXPOSE 80

# Comando para iniciar Nginx en primer plano cuando el contenedor se ejecute.
# Esto es importante para que el contenedor no se detenga inmediatamente.
CMD ["nginx", "-g", "daemon off;"]