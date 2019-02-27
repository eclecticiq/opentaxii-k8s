VENV_PATH ?= .venv
PACKAGE_NAME = opentaxii
PROD_IMAGE_NAME = eclecticiq/$(PACKAGE_NAME)
PROD_IMAGE = $(PROD_IMAGE_NAME):$(IMAGE_TAG)
ifeq ($(origin IMAGE_TAG), undefined)
  LOCAL_TAG = latest
else
  LOCAL_TAG = $(IMAGE_TAG)
endif
PKG_IMAGE = localhost/opentaxii-pkg:$(LOCAL_TAG)
PKG_CONTAINER = tmp-opentaxii-pkg-$(LOCAL_TAG)

default: lint test build-image build-packages


# running stuff locally in a venv
$(VENV_PATH):
	python3 -m venv $(VENV_PATH)
	$(VENV_PATH)/bin/pip install -r requirements-dev.txt

lint: $(VENV_PATH)
	$(VENV_PATH)/bin/flake8

test: $(VENV_PATH)
	$(VENV_PATH)/bin/pytest -v

run-dev: $(VENV_PATH)
	FLASK_APP=opentaxii.http:app FLASK_ENV=dev FLASK_DEBUG=true $(VENV_PATH)/bin/flask run -p9000

run-prod: $(VENV_PATH)
	$(VENV_PATH)/bin/gunicorn 'opentaxii.http:app' -b localhost:9000


# managing the docker image
build-image:
	docker build --target=prod --tag $(PROD_IMAGE) .

run-image: build-image
	docker run --rm -t -p 127.0.0.1:9000:9000 $(PROD_IMAGE)

push-image: build-image
ifeq ($(origin PUSH_TAG), undefined)
	docker push $(PROD_IMAGE)
else
	docker tag $(PROD_IMAGE) $(PROD_IMAGE_NAME):$(PUSH_TAG)
	docker push $(PROD_IMAGE_NAME):$(PUSH_TAG)
endif


# packaging
build-packages: pkg-copy-files pkg-clean
build-signed-packages: pkg-copy-files pkg-sign pkg-clean

pkg-build-image:
	docker build --target pkg --build-arg VERSION=$(VERSION) --build-arg ITERATION=$(ITERATION) --tag $(PKG_IMAGE) .

pkg-create-container: pkg-build-image
	docker create --name $(PKG_CONTAINER) $(PKG_IMAGE)

pkg-copy-files: pkg-create-container
	mkdir -p dist
	docker cp $(PKG_CONTAINER):/home/package/dist/$(PACKAGE_NAME)_$(VERSION)-$(ITERATION).rpm ./dist
	docker cp $(PKG_CONTAINER):/home/package/dist/$(PACKAGE_NAME)_$(VERSION)-$(ITERATION).deb ./dist

pkg-sign: pkg-copy-files
	dpkg-sig --sign builder ./dist/*.deb
	rpmsign --addsign ./dist/*.rpm

pkg-clean:
	docker rm -f $(PKG_CONTAINER) || true
	docker rmi -f $(PKG_IMAGE) || true

clean: pkg-clean
	docker rm -f $(PROD_IMAGE) || true
	rm -f ./dist/*
	rm -f $(VENV_PATH)
