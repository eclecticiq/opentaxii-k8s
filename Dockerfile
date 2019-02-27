FROM python:3.6-stretch AS build
LABEL maintainer="EclecticIQ <opentaxii@eclecticiq.com>"

RUN python3 -m venv /opt/opentaxii && /opt/opentaxii/bin/pip install -U pip setuptools

COPY ./requirements.txt ./requirements-docker.txt /opentaxii/
RUN /opt/opentaxii/bin/pip install -r /opentaxii/requirements.txt -r /opentaxii/requirements-docker.txt

COPY . /opentaxii
RUN /opt/opentaxii/bin/pip install /opentaxii


FROM python:3.6-slim-stretch AS prod
LABEL maintainer="EclecticIQ <opentaxii@eclecticiq.com>"
COPY --from=build /opt/opentaxii /opt/opentaxii

RUN mkdir /data /input
VOLUME ["/data", "/input"]

COPY ./docker/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 9000
ENV PATH "/opt/opentaxii/bin:${PATH}"
ENV PYTHONDONTWRITEBYTECODE "1"
CMD ["/opt/opentaxii/bin/gunicorn", "opentaxii.http:app", "--workers=2", \
     "--log-level=info", "--log-file=-", "--timeout=300", \
     "--config=python:opentaxii.http", "--bind=0.0.0.0:9000"]


# TODO: update once bugs in 1.11 are fixed
FROM eclecticiq/package:1.10.2 AS pkg
COPY ./packaging ./
COPY --from=prod --chown=package:package /opt/opentaxii /opt/opentaxii
ARG VERSION=0.0.0
ARG ITERATION=1
RUN VERSION=$VERSION ITERATION=$ITERATION ./build.sh
