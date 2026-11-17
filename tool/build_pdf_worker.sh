#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
dart compile js -O2 --no-source-maps tool/pdf_worker.dart -o assets/workers/pdf_builder.js
