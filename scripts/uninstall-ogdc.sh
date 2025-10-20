#!/bin/bash

set -e

helm uninstall $RELEASE_NAME -n $NAMESPACE
