FROM uribo/ramora:latest

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  libjq-dev \
  imagemagick \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN install2.r \
  egg \ 
  ggrepel \ 
  here \ 
  xaringan

RUN installGithub.r \
  dgrtwo/gganimate \
  yutannihilation/gghighlight \
  gadenbuie/xaringanthemer

RUN Rscript -e 'devtools::install_git("https://gitlab.com/uribo/jmastats")'
