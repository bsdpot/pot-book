FROM pizzamig/mkdocs-material-extended:6.2.8 as builder

RUN git clone --depth 1 https://github.com/pizzamig/pot-book.git . && mkdocs build -d /html

FROM nginx:1.18 as runtime

COPY --from=builder /html /usr/share/nginx/html
