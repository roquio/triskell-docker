FROM httpd

ARG TRISKELL_PUBLIC_HOST


COPY conf/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY conf/extra/triskell.conf /usr/local/apache2/conf/extra/triskell.conf


RUN sed -i \
    -e "s/TRISKELL_PUBLIC_HOST/$TRISKELL_PUBLIC_HOST/g" \
    /usr/local/apache2/conf/httpd.conf

RUN sed -i \
    -e "s/TRISKELL_PUBLIC_HOST/$TRISKELL_PUBLIC_HOST/g" \
    /usr/local/apache2/conf/extra/triskell.conf


EXPOSE 80
